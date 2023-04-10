//
//  MachatoApp.swift
//  Machato
//
//  Created by Théophile Cailliau on 24/03/2023.
//

import SwiftUI
import CoreData
import Sparkle

@main
class MachatoApp: App {
    private var chatAPIManager: ChatAPIManager = ChatAPIManager();
    private let updaterController: SPUStandardUpdaterController = PreferencesManager.shared.updaterController

    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    required init() {

    }
    
    private var persistentContainer : NSPersistentContainer = PreferencesManager.shared.persistentContainer;
    
    
    var body: some Scene {
        WindowGroup {
            MainView (newConvo: newConversation,
                      onSend: { (a, b) in self.onSend(conversation: a, messageString: b) },
                      delConv: deleteConversation,
                      onMessageAction: onMessageAction) .environment(\.managedObjectContext, persistentContainer.viewContext)
                .onAppear() {
                    self.initialize()
                }
        }.commands {
            MachatoCommands()
        }
        Settings {
            AppSettingsView(updater: updaterController.updater)
        }
    }
    
    func onMessageAction(_ action: ChatElementAction, _ m: Message) {
        switch action {
        case .delete:
            guard let c = m.belongs_to_convo else {
                print("Could not delete, no associated conversation")
                return
            }
            persistentContainer.viewContext.delete(m)
            if let msgs = c.has_messages {
                if let lm = msgs.sortedArray(using: [NSSortDescriptor(keyPath: \Message.date, ascending: true)]) as? [Message] {
                    c.last_message = lm.last(where: { $0.id != m.id})
                    c.update.toggle()
                }
            }
            try? persistentContainer.viewContext.save()
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
            guard let c = m.belongs_to_convo else { return}
            let nm = newMessage(m.content ?? "N/A", c, received: true, trySave: false)
            nm.is_finished = true
            onMessageAction(.delete, m)
        case .regenerate:
            guard let c = m.belongs_to_convo else { return }
            guard let lm = c.last_message else { return }
            if lm.is_response == true {
                onMessageAction(.delete, lm)
            }
            let content : String = m.content ?? ""
            onSend(conversation: c, messageString: content, msg: lm)
        default:
            print("Unimplemented action")
        }
    }
    
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
        }
        try? persistentContainer.viewContext.save()
    }
    
    func deleteConversation(_ c: Conversation) {
        print("deleting \(c.title ?? "")")
        persistentContainer.viewContext.delete(c)
        try? persistentContainer.viewContext.save()
    }
    
    func newConversation () -> Conversation {
        let c = Conversation(context: persistentContainer.viewContext)
        c.id = UUID()
        c.title = "Untitled conversation"
        c.date = Date()
        let cs = ConversationSettingsEntity(context: persistentContainer.viewContext)
        cs.model = PreferencesManager.shared.defaultModel.rawValue
        cs.prompt = PreferencesManager.shared.defaultPrompt
        cs.rendering = PreferencesManager.shared.defaultTypeset.rawValue
        cs.stream = PreferencesManager.shared.streamChat
        cs.override_global = false; // Do not override global settings unless explicitely specified in conversation-specific settings
        cs.of_convo = c
        try? persistentContainer.viewContext.save()
        return c
    }
    
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
                await chatAPIManager.streamedChatRequest(conversation) { (event, delta, _, error, errorMessage) in
                    conversation.update.toggle()
                    guard m.isInserted && !m.isDeleted else { return }
                    switch event {
                    case .end:
                        m.is_finished = true
                        try? self.persistentContainer.viewContext.save()
                        if wasFirstMessage { self.entitleConvo(conversation) }
                    case .delta:
                        guard let d = delta else { return }
                        guard let ds = d.choices.first?.delta.content else { return }
                        m.content = m.content ?? ""
                        m.content! += ds;
                    case .error:
                        guard let e = error else { return }
                        m.is_error = true
                        m.is_finished = true
                        m.content = m.content ?? ""
                        m.content! += "\n\n"
                        m.content = e.description
                        if let em = errorMessage {
                            m.content! += "\n\n"
                            m.content! += "```\n" + em + "\n```";
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
                }
            }
        }
    }
    
    func entitleConvo(_ c: Conversation) {
        chatAPIManager.getTitle(c) { s in
            c.title = s;
            try? self.persistentContainer.viewContext.save()
        }
    }
    
    @discardableResult
    func newMessage(_ content: String, _ convo: Conversation, received: Bool = false, trySave: Bool = true) -> Message {
        let m = Message(context: persistentContainer.viewContext)
        m.id = UUID()
        m.content = content
        m.is_response = received
        m.is_finished = !received
        m.date = Date();
        m.is_error = false;
        m.belongs_to_convo = convo;
        convo.last_message = m
        if trySave { try? persistentContainer.viewContext.save() }
        return m
    }
        
    func initialize() {
        if PreferencesManager.shared.defaults_initialized == false {
            PreferencesManager.restoreDefaults()
        }
        if PreferencesManager.shared.fontSize < 10 {
            PreferencesManager.shared.fontSize = 13;
        }
    }
}

#if os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationWillTerminate(_ aNotification: Notification) {
        do {
            try PreferencesManager.shared.persistentContainer.viewContext.save()
        } catch {
            print(error)
        }
    }
}
#endif
