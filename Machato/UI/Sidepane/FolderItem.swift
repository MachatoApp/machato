//
//  FolderItem.swift
//  Machato
//
//  Created by Théophile Cailliau on 19/04/2023.
//

import SwiftUI

struct FolderItem<Content>: View where Content: View {
    private var folder : Conversation;
    @Environment(\.managedObjectContext) var moc;
    var content : () -> Content;
    private var showChildren : Bool = true;
    @State private var hovering = false;
    @FocusState private var focus : Bool;
    @State private var confirmDelete : Bool = false;
    @Environment(\.editingSidepane) var editing;
    
    @State private var update = false;
    @ObservedObject var signals = Signals.shared
    
    func select() {
        recursiveSelect(select: !Signals.shared.selectedConversations.contains(folder), current: folder)
        update.toggle()
    }
    
    func recursiveSelect(select: Bool, current: Conversation) {
        current.folder_has_conversations?.forEach { c in
            guard let c = c as? Conversation else { return }
            recursiveSelect(select: select, current: c)
        }
        if select {
            Signals.shared.selectedConversations.insert(current)
        } else {
            Signals.shared.selectedConversations.remove(current)
        }
        Signals.shared.objectWillChange.send()
    }
    
    var label : some View {
        ZStack(alignment: .trailing) {
            let labelcontent = HStack (spacing: 0){
                if editing {
                    Button() {
                        select()
                    } label: {
                        Image(systemName: Signals.shared.selectedConversations.contains(folder) ? "checkmark.circle.fill" : "circle")
                    }.buttonStyle(.borderless)
                }
                Image(systemName: "folder").padding([.leading], 5)//.opacity(hovering ? 0 : 1)
                TextField(text: Binding {
                    return folder.title ?? "No title"
                } set: { v in
                    folder.title = v
                    try? moc.save();
                }) {
                    Text("Untitled folder")
                }.background(focus ? AppColors.chatBackgroundColor : Color.clear)
                    .focused($focus, equals: true)
                    .allowsHitTesting(false)
                    .mask (GeometryReader { geometry in
                        if hovering {
                            HStack (spacing: 0) {
                                let reservedWidth : CGFloat = confirmDelete ? 60 : 40
                                Rectangle().fill().frame(width: max(0, geometry.size.width - (80+reservedWidth)))
                                LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing).frame(width: 80)
                            }
                        } else {
                            Rectangle().fill()
                        }
                    })
                Spacer()
            }
            if editing {
                labelcontent.background(.secondary.opacity(0.001)).draggable(ConversationIdentifier(id: folder.id ?? UUID()))
                    .onTapGesture {
                        select()
                    }
            } else {
                labelcontent
            }
            HStack (alignment: .top, spacing: 0){
//                Image(systemName: "line.3.horizontal").padding([.leading, .top, .bottom], 5).opacity(hovering ? 1 : 0)
                    
//                Spacer()
                Button {
                    focus = true
                } label: {
                    Image(systemName: "pencil.line")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 15, height: 15)
                }
                .buttonStyle(.borderless)
                .opacity(hovering ? 1 : 0)
                .padding([.trailing], 5)
                Button {
                    Task {
                        let c = await DataActions.shared.newConversation()
                        DispatchQueue.main.async {
                            c.belongs_to_folder = folder
                            folder.expand_folder = true
                            try? moc.save()
                            Signals.shared.selectConversation(c)
                        }
                    }
                } label: {
                    Image(systemName: "plus.bubble")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 15, height: 15)
                }
                .buttonStyle(.borderless)
                .opacity(hovering ? 1 : 0)
                .padding([.trailing], 5)

                if confirmDelete {
                    Button {
                        confirmDelete = false
                        Task { @MainActor in
                            DataActions.shared.deleteConversation(folder)
                        }
                    } label: {
                        Image(systemName: "checkmark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 15, height: 15)
                    }
                    .buttonStyle(.borderless)
                    .opacity(hovering ? 1 : 0)
                    .padding([.trailing], 5)
                }
                Button {
                    confirmDelete.toggle()
                } label: {
                    Image(systemName: confirmDelete ? "multiply" : "trash")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 15, height: 15)
                }
                .buttonStyle(.borderless)
                .opacity(hovering ? 1 : 0)
                .padding(.trailing, 5)
            }
        }.onHover { h in
            withAnimation(Animation.easeInOut(duration: 0.15)) {
                hovering = h
                if !h {
                    confirmDelete = false
                }
            }
        }
    }
    
    var body: some View {
        if showChildren {
            let expanded = Binding(get: {
                folder.expand_folder
            }, set: { v in
                folder.expand_folder = v
                try? moc.save()
            })
            DisclosureGroup(isExpanded: expanded) {
//                if folder.expand_folder {
                content()
//                }
            } label: {
                label
            }// .disclosureGroupStyle(CustomDisclosureGroupStyle(isExpanded: expanded))
        } else {
            label
        }
    }
    
    init(folder: Conversation, showChildren : Bool, _ content: @escaping () -> Content) {
        self.folder = folder
        self.content = content
        self.showChildren = showChildren
    }
}

