//
//  MachatoApp.swift
//  Machato
//
//  Created by Théophile Cailliau on 24/03/2023.
//

import SwiftUI

@main
class MachatoApp: App {
    private var chatAPIManager: ChatAPIManager = ChatAPIManager();
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    required init() {
        
    }
    
    private var persistentContainer : NSPersistentContainer = PreferencesManager.shared.persistentContainer;
    
    
    var body: some Scene {
        WindowGroup {
            MainView (newConvo: newConversation,
                      onSend: onSend,
                      delConv: deleteConversation,
                      onMessageAction: onMessageAction) .environment(\.managedObjectContext, persistentContainer.viewContext)
                .onAppear() {
                    self.initialize()
                }
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
            if let c = m.content {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(c, forType: .string)
            }
        default:
            print("Unimplemented action")
        }
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
    
    func onSend(conversation: Conversation, messageString: String) {
        guard let msgs = conversation.has_messages else { return }
        let wasFirstMessage = msgs.count == 0;
        newMessage(messageString, conversation)
        let m = newMessage("", conversation, received: true, trySave: false)
        let settings = PreferencesManager.getConversationSettings(conversation)
        if settings.stream {
            Task {
                await chatAPIManager.streamedChatRequest(conversation) { (event, delta, _, error, errorMessage) in
                    conversation.update.toggle()
                    switch event {
                    case .end:
                        m.is_finished = true
                        try? self.persistentContainer.viewContext.save()
                        if wasFirstMessage { self.entitleConvo(conversation) }
                    case .delta:
                        guard let d = delta else { return }
                        guard let ds = d.choices.first?.delta.content else { return }
                        m.content! += ds;
                    case .error:
                        guard let e = error else { return }
                        m.is_error = true
                        m.is_finished = true
                        if m.content == nil { m.content = "" }
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
        
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationWillTerminate(_ aNotification: Notification) {
        do {
            try PreferencesManager.shared.persistentContainer.viewContext.save()
        } catch {
            print(error)
        }
    }
}
