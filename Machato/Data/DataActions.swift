//
//  DataActions.swift
//  Machato
//
//  Created by Théophile Cailliau on 23/05/2023.
//

import Foundation
import Cocoa

struct DataActions {
    static let shared : DataActions = .init()
    
    private var moc = PreferencesManager.shared.persistentContainer.viewContext
    var chatAPIManager = ChatAPIManager.shared
    
    @MainActor
    func entitleConvo(_ c: Conversation) {
        Task {
            await chatAPIManager.getTitle(c) { @MainActor s in
                c.title = s;
                try? self.moc.save()
            }
        }
    }
    
    @MainActor
    func onMessageAction(_ action: ChatElementAction, _ m: Message) {
        switch action {
        case .delete:
            guard let c = m.belongs_to_convo else {
                print("Could not delete, no associated conversation")
                return
            }
            moc.delete(m)
            if let msgs = c.has_messages {
                if let lm = msgs.sortedArray(using: [NSSortDescriptor(keyPath: \Message.date, ascending: true)]) as? [Message] {
                    c.last_message = lm.last(where: { $0.id != m.id})
                    //c.update.toggle()
                }
            }
            updateSummary(c)
            c.countTokens()
            try? moc.save()
        case .copy:
#if os(macOS)
            if let c = m.content {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(c, forType: .string)
            }
#endif
        case .branch:
            branchFromMessage(m)
        case .stop:
            guard let c = m.belongs_to_convo else { return }
            guard m.is_finished == false else { return }
            Task { @MainActor in
                await chatAPIManager.cancel(c)
                let nm = newMessage(m.content ?? "N/A", c, received: true, trySave: false)
                nm.is_finished = true
                TokenUsageManager.shared.updateCost()
                onMessageAction(.delete, m)
                updateSummary(c)
                await c.countTokens()
                try? moc.save()
            }
        case .regenerate:
            guard let c = m.belongs_to_convo else { return }
            c.has_messages?.forEach({ lm in
                guard let lm = lm as? Message else { return }
//                print(lm.date, m.date, lm.function_arguments, (lm.date ?? .distantPast) > (m.date ?? .distantFuture))
                if (lm.date ?? .distantPast) > (m.date ?? .distantFuture) {
//                    print("delet!")
                    onMessageAction(.delete, lm)
                }
            })
            m.date = Date.now
            try? moc.save()
            let content : String = m.content ?? ""
            c.countTokens()
            onSend(conversation: c, messageString: content, msg: m)
        default:
            print("Unimplemented action")
        }
    }
    
    @MainActor
    func branchFromMessage(_ m: Message) {
        guard let c = m.belongs_to_convo else {
            print("Branching from orphaned messaged")
            return
        }
        guard let cs = c.has_settings else {
            print("Conversation had no settings")
            return
        }
        let newConvo = newConversation()
        guard let csnew = newConvo.has_settings else {
            print("New conversation had no settings")
            return
        }
        newConvo.title = c.title
        csnew.model = cs.model
        csnew.prompt = cs.prompt
        csnew.rendering = cs.rendering
        csnew.stream = cs.stream
        csnew.override_global = cs.override_global
        
        guard let messages = c.has_messages else {
            print("Conversation had no messages while branching")
            return
        }
        let maybeMessages = messages.sortedArray(using: [NSSortDescriptor(keyPath: \Message.date, ascending: true)]) as? [Message]
        guard let msgs = maybeMessages else {
            print("Could not cast message list to [Message]")
            return
        }
        guard let d = m.date else {
            print("Message had no date")
            return
        }
        let msgsUpToM = msgs.filter { msg in
            guard let d1 = msg.date else { return false }
            return d1 <= d || msg.id == m.id
        }
        msgsUpToM.forEach { msg in
            let m2 = newMessage(msg.content ?? "", newConvo, received: msg.is_response, trySave: false)
            m2.is_finished = true
            m2.is_function = msg.is_function
            m2.function_name = msg.function_name
            m2.function_displaytext = msg.function_displaytext
            m2.function_arguments = msg.function_arguments
        }
        updateSummary(newConvo)
        Signals.shared.selectConversation(newConvo)
        try? moc.save()
    }
    
    @MainActor
    func onSend(conversation: Conversation, messageString: String, msg: Message? = nil) {
        guard let msgs = conversation.has_messages else { return }
        let wasFirstMessage = msgs.count == 0;
        let m: Message;
        if msg == nil {
            newMessage(messageString, conversation)
        }
        m = newMessage("", conversation, received: true, trySave: false)
        
        let settings = PreferencesManager.getConversationSettings(conversation)
        if settings.stream {
            Task {
                await self.chatAPIManager.streamedChatRequest(conversation) { (event) in
                    //  conversation.update.toggle()
                    guard !m.isDeleted else {
                        return
                    }
                    switch event {
                    case .end(let completion):
                        m.is_finished = true
                        m.content = completion
                        m.date = Date.now
                        if wasFirstMessage && conversation.title == nil { self.entitleConvo(conversation) }
                        self.updateSummary(conversation)
                        TokenUsageManager.shared.updateCost()
                        conversation.countTokens()
                        if PreferencesManager.shared.currentConversation != conversation.id?.uuidString {
                            conversation.unread = true
                        }
                        try? moc.save()
                    case .delta:
                        break
                    case .error(let e, let errorMessage):
                        m.is_error = true
                        m.is_finished = true
                        m.content = m.content ?? ""
                        m.content! += "\n\n"
                        m.content = e.description
                        if let em = errorMessage {
                            m.content! += "\n\n"
                            m.content! += "```\n" + em + "\n```";
                        }
                        if e == .api_error && (errorMessage?.contains("maximum context length") ?? false) {
                            m.content! += "\n\n"
                            let model = OpenAIChatModel.fromString(m.belongs_to_convo?.has_settings?.model)
                            m.content! += "This error means you have reached the maximum allowed context length. For reference, the current model is `\(model.rawValue)` and its context length is `\(model.contextLength)` tokens.\n\nKeep in mind that Machato's token count is an estimate: it can be a few tokens off."
                        }
                        if e == .api_error && (errorMessage?.contains("invalid_api_key") ?? false) {
                            m.content! += "\n\n"
                            m.content! += "Make sure you've set the correct API key in Machato's Settings. A blue checkmark should appear next to your API key."
                        }
                        if e == .api_error && (errorMessage?.contains("billing") ?? false) {
                            m.content! += "\n\n"
                            m.content! += "The most likely cause for this error is that your haven't [set up billing in your OpenAI account](https://platform.openai.com/account/billing/overview)"
                        }
                        if e == .api_error && (errorMessage?.contains("does not exist") ?? false) {
                            m.content! += "\n\n"
                            m.content! += "It is likely your account does not have API access to GPT-4 or the selected model. Make sure you've gone through the [waitlist](https://openai.com/waitlist/gpt-4-api) process. This is independent from ChatGPT Plus."
                        }
                        if e == .model_invalid {
                            m.content! += "\n\n"
                            m.content! += "This conversation model was incorrectly defined. This is most likely due to the conversation having been created before you made modifications to your profiles and models. Choose a new model for this conversation from the bottom status bar."
                        }
                        m.content! += "\n\n"
                        m.content! += "If you need more help, check out the [FAQ](https://machato.app/faq) or contact [contact@machato.app](mailto:contact@machato.app)."
                        self.updateSummary(conversation)
                        conversation.countTokens()
                    case .update(let completion):
                        if m.is_error {
                            break
                        }
                        m.content = completion
                    case .updateFunction(let name, let arguments):
                        guard let lm = conversation.last_message else { return }
                        if lm.is_function == false && (lm.content?.isEmpty == false) {
                            newMessage("", conversation)
                        }
                        guard let lm = conversation.last_message else { return }
                        lm.is_function = true
                        lm.is_response = false
                        lm.function_name = name
                        lm.function_arguments = arguments
                        lm.function_displaytext = "`\(name)`\(arguments.isEmpty ? "" : ":")\(arguments.replacing(#/\s+/#, with: " "))"
                    case .function(let name, let arguments):
                        guard let fm = conversation.last_message else { return }
                        if fm.is_function == false {
                            newMessage("", conversation)
                        }
                        guard let fm = conversation.last_message else { return }
                        fm.date = .now
                        fm.content = ""
                        fm.is_function = true
                        fm.collapsed = true
                        fm.function_name = name
                        fm.function_arguments = arguments
                        fm.function_displaytext = (try? conversation.settings.getFunction(name: name).displayDescription(args: arguments)) ?? ""
                        if wasFirstMessage && conversation.title == nil { self.entitleConvo(conversation) }
                        self.updateSummary(conversation)
                        TokenUsageManager.shared.updateCost()
                        conversation.countTokens()
                        if PreferencesManager.shared.currentConversation != conversation.id?.uuidString {
                            conversation.unread = true
                        }
                        try? moc.save()
                        Task {
                            fm.is_response = false
                            guard let fn = try? conversation.settings.getFunction(name: name) else {
                                print("Function \(name) could not be retrieved")
                                fm.is_error = true
                                fm.collapsed = false
                                fm.content = "Function \(name) does not exist."
                                try? moc.save()
                                return
                            }
                            do {
                                var implem = fn
                                implem.conversation = conversation
                                let res = try await implem.execute(arguments: arguments)
                                fm.content = res
                                fm.is_finished = true
                                fm.collapsed = !implem.expandOnResult
                                try? moc.save()
                                onSend(conversation: conversation, messageString: res, msg: m)
                            } catch FunctionError.executionFailed(let message) {
                                print("Execution of \(name) with arguments \(arguments) failed")
                                print(message)
                                fm.is_error = true
                                fm.content = message
                                fm.collapsed = false
                                try? moc.save()
                                return
                            } catch FunctionError.malformedInput {
                                fm.function_displaytext = "Input to \(fm.function_name ?? "?") did not match the right schema : \(fm.function_arguments ?? "?")"
                                fm.is_error = true
                                fm.content = "Malformed input"
                                fm.collapsed = false
                                try? moc.save()
                            } catch {
                                fm.is_error = true
                                fm.content = "Unknown error"
                                try? moc.save()
                            }
                        }
                    }
                }
            }
        } else {
            Task {
                await chatAPIManager.sendChatRequest(conversation) { convo, response, error, errorMessage in
                    guard m.isInserted && !m.isDeleted else { return }
                    guard error == nil else {
                        print("There was an error: \(error!.description)")
                        m.is_error = true
                        m.is_finished = true
                        m.date = Date.now
                        if m.content == nil { m.content = "" }
                        m.content! += "\n\n"
                        m.content! += error!.description
                        if let em = errorMessage {
                            print(em)
                            m.content! += "\n\n"
                            m.content! += "```\n" + em + "\n```";
                        }
                        return
                    }
                    guard let firstChoice = response?.choices.first else { return }
                    print(firstChoice.message.content)
                    m.is_finished = true
                    m.content = firstChoice.message.content
                    self.updateSummary(conversation)
                }
            }
        }
    }
    
    @discardableResult
    @MainActor
    func newMessage(_ content: String, _ convo: Conversation, received: Bool = false, trySave: Bool = true) -> Message {
        let m = Message(context: moc)
        m.id = UUID()
        m.content = content
        m.is_response = received
        m.is_finished = !received
        m.date = Date();
        m.is_error = false;
        m.belongs_to_convo = convo;
        convo.last_message = m
        if trySave { try? moc.save() }
        if !received { self.updateSummary(convo) }
        return m
    }
    
    @MainActor
    func updateSummary(_ c: Conversation) {
        if let sum = c.last_message?.content?.replacing(#/\n+/#, with: { _ in return " " })
            .replacing(#/[$`*\\]/#, with: "")
        {
            c.summary = String(sum.prefix(100)) + (sum.count > 100 ? "…" : "")
        } else {
            c.summary = nil
        }
        Signals.shared.objectWillChange.send()
    }
    
    @MainActor
    func deleteConversation(_ c: Conversation) {
        print("deleting \(c.title ?? "")")
        moc.delete(c)
        PreferencesManager.conversationSettings.removeValue(forKey: c)
        try? moc.save()
    }
    
    @MainActor
    func newConversation () -> Conversation {
        let c = Conversation(context: moc)
        c.id = UUID()
        c.title = nil
        c.unread = false
        c.date = Date()
        let cs = ConversationSettingsEntity(context: moc)
        cs.model = PreferencesManager.shared.defaultModel
        cs.prompt = PreferencesManager.shared.defaultPrompt
        cs.rendering = PreferencesManager.shared.defaultTypeset.rawValue
        cs.temperature = PreferencesManager.shared.defaultTemperature
        cs.stream = PreferencesManager.shared.streamChat
        cs.frequency_penalty = PreferencesManager.shared.defaultFrequencyPenalty
        cs.presence_penalty = PreferencesManager.shared.defaultPresencePenalty
        cs.top_p = PreferencesManager.shared.defaultTopP
        cs.manage_max = !PreferencesManager.shared.maxTokensManual
        cs.max_tokens = PreferencesManager.shared.maxTokens
        cs.override_global = false; // Outdated
        cs.of_convo = c
        try? moc.save()
        return c
    }
    
    @MainActor
    func newFolder(title: String, convo: Conversation?) -> Conversation {
        let c = newConversation()
        c.is_folder = true
        c.title = title.isEmpty ? "New folder" : title
        //c.belongs_to_folder = convo?.belongs_to_folder
        try? moc.save()
        return c
    }
}
