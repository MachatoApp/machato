//
//  Signals.swift
//  Machato
//
//  Created by Théophile Cailliau on 19/05/2023.
//

import Combine
import Foundation

class Signals : ObservableObject {
    static let shared : Signals = .init();
    
    let selectConversationPublisher = PassthroughSubject<UUID?, Never>()
    
    func selectConversation(_ convo: Conversation? = nil) {
        PreferencesManager.shared.currentConversation = convo?.id?.uuidString ?? ""
        selectConversationPublisher.send(UUID(uuidString: PreferencesManager.shared.currentConversation))
    }
    
    let clearConversationSignal = PassthroughSubject<(), Never>();
    
    let keySettings = PassthroughSubject<Void, Never>()
    
    func selectKeysTab() {
        keySettings.send()
    }
    
    @Published var selectedConversations = Set<Conversation>()
}
