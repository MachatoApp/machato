//
//  MenuContent.swift
//  Machato
//
//  Created by Théophile Cailliau on 30/09/2023.
//

import SwiftUI

struct MenuContent: View {
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Conversation.userOrder, ascending: true), NSSortDescriptor(keyPath: \Conversation.date, ascending: false)], predicate: NSPredicate(format: "belongs_to_folder == nil"), animation: .none) var conversations: FetchedResults<Conversation>;
    
    var body: some View {
        Button("New conversation") {
            let c = DataActions.shared.newConversation()
            Signals.shared.selectConversation(c)
            NSApp.activate(ignoringOtherApps: true)
        }
        Button("Machato preferences") {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        Divider()
        ForEach(conversations, id: \.self) { c in
            ConvoList(conversation: c)
        }
    }
}

fileprivate struct ConvoList : View {
    var conversation : Conversation
    
    var body: some View {
        if let children = conversation.children, !children.isEmpty {
            Menu {
                ForEach(children, id: \.self) { c in
                    ConvoList(conversation: c)
                }
            } label: {
                Label(conversation.title ?? "Untitled folder", systemImage: "folder")
            }
        } else {
            Button(conversation.title ?? "Untitled conversation") {
                Signals.shared.selectConversation(conversation)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}

struct MenuContent_Previews: PreviewProvider {
    static var previews: some View {
        MenuContent()
    }
}
