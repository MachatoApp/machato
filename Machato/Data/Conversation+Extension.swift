//
//  ConversationEntityExtension.swift
//  Machato
//
//  Created by Théophile Cailliau on 03/05/2023.
//

import Foundation

extension Conversation {
    func expandParents() {
        guard let parent = self.belongs_to_folder else { return }
        parent.expand_folder = true
        parent.expandParents()
    }
    
    var settings : ConversationSettings {
        PreferencesManager.getConversationSettings(self)
    }
    
    var children : [Conversation]? {
        let result = self.folder_has_conversations?.sortedArray(using: [NSSortDescriptor(keyPath: \Conversation.userOrder, ascending: true)]).compactMap { $0 as? Conversation } ?? []
        return result.isEmpty ? nil : result
    }
    
    @available(*, noasync, message: "Only available in non async contexts")
    func countTokens() {
        Task.detached(priority: .background) {
            await self.countTokens()
        }
    }
    
    @MainActor
    func countTokens() async {
        guard let msgs = has_messages else { return }
        guard let messages = Array(msgs) as? [Message] else { return }
        var tokens : Int32 = .zero
        var excluded : Int32 = .zero
        let queue = DispatchQueue(label: "machato.tokenUpdateDispatchQueue")
        tokens += TokenCounter.shared.countTokens(self.settings.prompt) + 6
        DispatchQueue.concurrentPerform(iterations: messages.count) { index in
            let message = messages[index]
            guard message.is_error == false && message.content?.isEmpty == false else { return }
            var tc = TokenCounter.shared.countTokens(message.content)
            tc += 5
            if message.is_response {
                tc += 1
            }
            queue.sync { [tc] in
                tokens += tc
                if !message.include_in_requests {
                    excluded += tc
                }
            }
        }
        PreferencesManager.shared.persistentContainer.viewContext.performAndWait {
            self.tokens = tokens
            self.excluded_tokens = excluded
            try? PreferencesManager.shared.persistentContainer.viewContext.save()
        }
    }
    
}
