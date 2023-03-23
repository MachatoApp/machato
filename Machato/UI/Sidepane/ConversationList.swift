//
//  ConversationList.swift
//  Machato
//
//  Created by Théophile Cailliau on 18/04/2023.
//

import SwiftUI
import UniformTypeIdentifiers
import AlertToast

struct ConversationIdentifier : Identifiable, Codable, Transferable {
    var id : UUID;
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(for: ConversationIdentifier.self, contentType: .conversation)
    }
}

extension UTType {
    static var conversation = UTType(exportedAs: "machato.Machato.ConversationIdentifier")
}

struct ConversationList: View {
    private var conversations : [Conversation] = [];
    @Environment(\.managedObjectContext) var moc;
    @Binding private var current : Conversation?;
    private var nestingLevel : Int = 0;
    private var parent : Conversation? = nil;
    @State private var test : Bool = false;
    @State private var showCircularAlertState : Bool = false;
    @State private var editing : Bool = false;
    
    var content: some View {
        ForEach(conversations.indices, id: \.self) { i in
            let convo = conversations[i]
            Group {
                if convo.is_folder {
                    FolderItem(folder: convo, showChildren: (convo.folder_has_conversations?.count ?? 0) > 0) {
                        
                        ConversationList(current: $current, children: convo.folder_has_conversations?.sortedArray(using: [NSSortDescriptor(keyPath: \Conversation.userOrder, ascending: true), NSSortDescriptor(keyPath: \Conversation.date, ascending: false)]) as? [Conversation], nesting: nestingLevel + 1, parent: convo)
                    }
                } else {
                    ConversationItem(current: $current, convo: convo)
                }
            }
        }
        .dropDestination(for: ConversationIdentifier.self, action: drop)
    }
    
    @ObservedObject var signals = Signals.shared
    
    var body: some View {
//        return Spacer()
        Group {
            if nestingLevel == 0 {
//                let _ = Self._printChanges()
                    List(selection: $current) {
                        content
                    }.environment(\.editingSidepane, editing)
                if editing {
                    HStack {
                        if Signals.shared.selectedConversations.count > 0 {
                            Button("Deselect all") {
                                Signals.shared.selectedConversations.removeAll()
                            }
                        } else {
                            Button("Select all") {
                                let fr = Conversation.fetchRequest()
                                Signals.shared.selectedConversations.formUnion((try? moc.fetch(fr)) ?? [])
                            }
                        }
                        if Signals.shared.selectedConversations.count > 0 {
                            Button("Delete") {
                                Signals.shared.selectedConversations.forEach { c in
                                    moc.delete(c)
                                }
                                try? moc.save()
                                editing = false
                            }
                        }
                    }
                }
                Toggle("Drag and select", isOn: $editing).toggleStyle(.switch).onChange(of: editing) { _ in
                    Signals.shared.selectedConversations.removeAll()
                }
            } else {
                content
            }
        }
    }
    
    @discardableResult
    func putConvoInFolder(id: UUID, folder: Conversation?) -> Conversation? {
        let fr = Conversation.fetchRequest()
        fr.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        guard let c = try? moc.fetch(fr).first else {
            print("No such conversation!")
            return nil
        }
        guard !hasParent(folder: folder, has: c) else {
            print("Attempted circular move !")
            showCircularAlertState = true
            return nil
        }
        c.belongs_to_folder = folder
        try? moc.save()
        return c
    }
    
    func hasParent(folder: Conversation?, has: Conversation) -> Bool {
        guard folder != has else { return true }
        guard let parent = folder?.belongs_to_folder else { return false }
        if parent == has {
            return true
        } else {
            return hasParent(folder: parent, has: has)
        }
    }
    
    func drop(what identifiers: [ConversationIdentifier], at index: Int) {
//        print("drop", identifiers, index)
        guard let id = identifiers.first?.id else { return }
        DispatchQueue.main.async {
            guard let c = putConvoInFolder(id: id, folder: parent) else { return }
            
            if index-1 >= conversations.startIndex && conversations[index-1].is_folder && (conversations[index-1].folder_has_conversations?.count ?? 0) == 0 {
                putConvoInFolder(id: id, folder: conversations[index-1])
                return
            }
            
            var revisedConversations : [Conversation] = conversations.map { $0 }
            revisedConversations.insert(c, at: index)
            let revisedEnumeration = revisedConversations.enumerated().filter { $0.element.id != id || $0.offset == index}
            revisedEnumeration.forEach { ind in
                ind.element.userOrder = Int16(ind.offset)
            }
            
            try? moc.save()
        }
    }
    
    let convoID : UUID?;
    
    init(current: Binding<Conversation?>, children: [Conversation]?) {
        _current = current
        conversations = children ?? []
        convoID = current.wrappedValue?.id
    }
    
    private init(current: Binding<Conversation?>, children: [Conversation]?, nesting: Int, parent: Conversation) {
        _current = current
        conversations = children ?? []
        nestingLevel += 1
        self.parent = parent
        convoID = current.wrappedValue?.id
    }
}
