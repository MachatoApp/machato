//
//  ChatView.swift
//  Machato
//
//  Created by Théophile Cailliau on 25/03/2023.
//

import SwiftUI
import CoreData
import AlertToast

struct ChatView: View {
    @State private var message : String = "";
    @Environment(\.managedObjectContext) var moc;
    @ObservedObject private var convo : Conversation;
    @Namespace var bottomID;
    @Namespace var systemID;

    @State private var lastSent: Message? = nil;
    @State private var editing: Bool = false;
    @State private var showToast : Bool = false;
    @State private var toastText : String  = "";
    @State private var scrollBroken : Bool = false;
    
    @AppStorage(PreferencesManager.StoredPreferenceKey.autoScroll) var autoScroll : Bool = true;
    
    @State private var clearConvoDialog = false;
    
    
    @Environment(\.openWindow) var openWindow;
        
    private var breakAutoscrollThreshold = PreferencesManager.shared.fontSize * 8 + 80
    private var joinAutoscrollThreshold = PreferencesManager.shared.fontSize * 4
    
    func updateLastSent<V>(_ _: V) {
        updateLastSent()
    }
    
    func updateLastSent() {
        lastSent = convo.has_messages?.sortedArray(using: [NSSortDescriptor(keyPath: \Message.date, ascending: true)]).filter { ($0 as? Message)?.is_response == false && ($0 as? Message)?.is_function == false }.last as? Message;
    }
    
    private var messageCount : Int {
        return convo.has_messages?.count ?? 0
    }
    
    private var isGenerating : Bool {
        return convo.last_message?.is_finished ?? true == false
    }

    @State private var scrollPosition: CGFloat = .zero
    @State private var scrollViewHeight : CGFloat = .zero
    @State private var lastMessageHeight : CGFloat = .zero;
    @Binding private var selectMessage : Message?;
    
    @ObservedObject private var settings : ConversationSettings;
    
    var systemPrompt : some View {
        Group {
            HStack {
                Spacer()
                Text("**System prompt**: \(settings.prompt.replacing(#/\n+/#, with: " "))")
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(.gray)
                    .padding([.trailing], 10)
                    .padding([.top, .bottom], 3)
                Button {
                    openWindow(id: "system-prompt", value: convo.id)
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.gray)
                }.buttonStyle(.borderless)
                Spacer()
            } .padding([.leading, .trailing], 10)
        }
    }
    
    @ViewBuilder
    func msgsView(_ sv: ScrollViewProxy) -> some View {
//        return EmptyView()
        LazyVStack(alignment: .leading, spacing: 0) {
            
            if messageCount > 0 { Divider().padding([.bottom], 0) }
            ForEach((convo.has_messages?.sortedArray(using: [NSSortDescriptor(keyPath: \Message.date, ascending: true)]) ?? []) as! [Message]) { message in
                ChatElement(message, allowEdit: message == lastSent, editing: $editing).equatable()
                    .contextMenu {
                        Button {
                            DataActions.shared.onMessageAction(.delete, message)
                        } label: {
                            Text("Delete")
                        }
                    } .id(message.id)
                    .background(GeometryReader { geometry in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).height)
                    })
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        if message.id == convo.last_message?.id {
                            self.lastMessageHeight = value
                        }
                    }//.zIndex(-(message.date?.timeIntervalSince1970 ?? 0))
            }.onChange(of: lastMessageHeight) { _ in
                guard !scrollBroken && autoScroll else { return }
                sv.scrollTo(bottomID, anchor: .bottom)
            } .onChange(of: convo.last_message?.id) { _ in
                updateLastSent()
            } .onAppear(perform: updateLastSent)
        }
    }
    
    var body: some View {
        VStack (alignment: .leading, spacing: 0) {
            ZStack (alignment: .bottomLeading){
                ScrollViewReader { sv in
                    ScrollView(.vertical) {
                        VStack(alignment: .leading, spacing: 0) {
                            Button {
                                sv.scrollTo(systemID, anchor: .top)
                            } label: {
                                EmptyView()
                            }.buttonStyle(.borderless).keyboardShortcut(.upArrow, modifiers: .command)
                            Button {
                                sv.scrollTo(bottomID, anchor: .top)
                            } label: {
                                EmptyView()
                            }.buttonStyle(.borderless).keyboardShortcut(.downArrow, modifiers: .command)
                            systemPrompt.id(systemID)
                            
                                msgsView(sv)
                            
                            Spacer().id(bottomID).frame(maxWidth: .infinity, minHeight: 20, maxHeight: 20)
                                .background(GeometryReader { geometry in
                                    Color.clear
                                        .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).maxY)
                                })
                                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
//                                    guard convo.last_message?.is_finished == false else { return }
                                    let isNaturalScroll = abs(value - scrollPosition) <= PreferencesManager.shared.fontSize // heuristic
                                    let scrollingUp = (value > scrollPosition) && (value > scrollViewHeight)
                                    self.scrollPosition = value
                                    guard isNaturalScroll else { return }
                                    if scrollingUp && isNaturalScroll {
                                        scrollBroken = true
                                    } else {
                                        scrollBroken = abs(scrollPosition - scrollViewHeight) > (scrollBroken ? joinAutoscrollThreshold : breakAutoscrollThreshold)
                                    }
//                                    print("isNaturalScroll:\(isNaturalScroll) scrollingUp:\(scrollingUp) scrollPosition:\(scrollPosition) scrollViewHeight:\(scrollViewHeight) scrollBroken:\(scrollBroken)")
                                }
                        }
                    }.onAppear() {
                        if let id = selectMessage?.id {
                            sv.scrollTo(id, anchor: .top)
                        } else {
                            sv.scrollTo(bottomID, anchor: .bottom)
                        }
                    }.onChange(of: convo) { _ in
                        updateLastSent()
                        if convo.tokens == .zero {
                            convo.countTokens()
                        }
                        if let id = selectMessage?.id {
                            sv.scrollTo(id, anchor: .top)
                        } else {
                            sv.scrollTo(bottomID, anchor: .bottom)
                        }
                    }.coordinateSpace(name: "scroll") .background {
                        GeometryReader { geometry in
                            Color.clear.preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).height)
                        }
                    } .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        self.scrollViewHeight = value
                    } .onChange(of: selectMessage) { message in
                        if let id = selectMessage?.id {
                            sv.scrollTo(id, anchor: .top)
                        }
                    } .onReceive(Signals.shared.clearConversationSignal) {
                        clearConvoDialog = true
                    } .confirmationDialog("Clear conversation ?", isPresented: $clearConvoDialog) {
                        Button("Clear") {
                            Task { @MainActor in
                                await ChatAPIManager.shared.cancel(convo)
                                convo.has_messages?.forEach({ m in
                                    guard let m = m as? Message else { return }
                                    moc.delete(m)
                                })
                                convo.title = nil
                                convo.summary = nil
                                convo.date = Date.now
                                await convo.countTokens()
                                try? moc.save()
                                toastText = "Cleared conversation"
                                showToast = true
                            }
                        } .keyboardShortcut(.defaultAction)
                        Button("Cancel", role: .cancel) {
                            clearConvoDialog = false
                        }
                    }
                }
            }
            // debug
            //            HStack {
            //                Text(scrollBroken.description)
            //                Text(scrollPosition.description)
            //                Text(lastMessageHeight.description)
            //            }
            bottomField
        }
        .background(AppColors.chatBackgroundColor)
        .toast(isPresenting: $showToast, duration: 2) {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: toastText)
        }
    }
    
    @ViewBuilder
    var bottomField : some View {
        ConversationStatusBar(convo: convo)
        SendMessageSection(editing: $editing, current: convo)
    }
    
    init(_ ce: Conversation, selectMessage: Binding<Message?>) {
        self._convo = ObservedObject(initialValue: ce);
        self._selectMessage = selectMessage
        _settings = ObservedObject(initialValue: PreferencesManager.getConversationSettings(ce))
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    }
}

