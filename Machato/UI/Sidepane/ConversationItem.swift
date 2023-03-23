//
//  ConversationItem.swift
//  Machato
//
//  Created by Théophile Cailliau on 19/04/2023.
//

import SwiftUI

struct ConversationItem : View {
    @State private var hoverMessage = false;
    private var convo : Conversation;
    @Environment(\.managedObjectContext) var moc;
    @AppStorage(PreferencesManager.StoredPreferenceKey.hideConversationSummary) private var hide_conversation_summary : Bool = false;
    @Binding private var current: Conversation?;
    @State private var hovering : Bool = false;
    @FocusState private var focus : Bool;
    @State private var confirmDelete : Bool = false;
    
    @Environment(\.editingSidepane) var editing;
    
    @ObservedObject var signals = Signals.shared
    
    func select() {
        if Signals.shared.selectedConversations.contains(convo) {
            Signals.shared.selectedConversations.remove(convo)
        } else {
            Signals.shared.selectedConversations.insert(convo)
        }
    }
    
    var body: some View {
        NavigationLink(value: convo) {
            ZStack(alignment: .topTrailing) {
                let content = HStack(spacing: 0){
                    if editing {
                        Button() {
                            select()
                        } label: {
                            Image(systemName: Signals.shared.selectedConversations.contains(convo) ? "checkmark.circle.fill" : "circle")
                        }.buttonStyle(.borderless)
                    }
                    Image(systemName: "text.bubble")
                    .padding([.leading, .trailing], 5)
                        //.opacity(hovering ? 0 : 1)
                    VStack (alignment: .leading) {
                        HStack {
                            if convo.unread == true {
                                Circle().frame(width: 10, height: 10).foregroundColor(.accentColor)
                                    .padding([.leading], 7)
                            }
                            TextField(text: Binding {
                                return convo.title ?? "Untitled conversation"
                            } set: { v in
                                convo.title = v
                                try? moc.save();
                            }) {
                                Text("Untitled conversation")
                            } .padding([.leading], 5).bold()
                                .frame(maxWidth: .infinity)
                                .focused($focus, equals: true)
                                .allowsHitTesting(false)
                                .background(focus ? AppColors.chatBackgroundColor : .clear)
                                .mask(GeometryReader { geometry in
                                    if hovering {
                                        HStack (spacing: 0) {
                                            let reservedWidth : CGFloat = confirmDelete ? 60 : 40
                                            Rectangle().fill().frame(width: max(0,geometry.size.width - (80+reservedWidth)))
                                            LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing).frame(width: 80)
                                        }
                                    } else {
                                        Rectangle().fill()
                                    }
                                })
                        }
                        if hide_conversation_summary == false {
                            Text(convo.summary ?? "Send your first message!")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(2)
                                .padding([.leading], 5)
                                .bold(convo.unread)
                        }
                    }
                }
                if editing {
                    content.background(.secondary.opacity(0.00001)).draggable(ConversationIdentifier(id: convo.id ?? UUID()))
                        .onTapGesture {
                            select()
                        }
                } else {
                    content
                }
                HStack(alignment: .top, spacing: 0) {
//                    VStack(spacing: 0) {
//                        Spacer().frame(width: 15).background(.white.opacity(0.001))
//                        Image(systemName: "line.3.horizontal")
//                            .padding([.leading, .trailing], 5)
//                            .opacity(hovering ? 1 : 0)
//                        Spacer().frame(width: 15).background(.white.opacity(0.001))
//                    }
//                        .onHover { inside in
//                            if inside {
//                                NSCursor.openHand.push()
//                            } else {
//                                NSCursor.pop()
//                            }
//                        }
                    Spacer()
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
                    if confirmDelete {
                        Button {
                            confirmDelete = false
                            deleteConvo()
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
            }
        }.onHover { h in
            withAnimation(Animation.easeInOut(duration: 0.15)) {
                hovering = h
                if !h {
                    confirmDelete = false
                }
            }
        }
        .padding([.top, .bottom], 5)
    }
    
    @MainActor
    func deleteConvo() {
        DataActions.shared.deleteConversation(convo)
        if current == convo {
            current = nil
        }
    }
    
    init(current: Binding<Conversation?>, convo: Conversation) {
        self._current = current
        self.convo = convo
    }
}
