//
//  ContentView.swift
//  Machato
//
//  Created by Théophile Cailliau on 24/03/2023.
//

import SwiftUI
import CoreData

struct MainView: View {
    public var newConvo : (() -> Conversation)?; // Call back
    public var onSend : ((Conversation, String) -> Void)?;
    public var delConv : ((Conversation) -> Void)?;
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Conversation.userOrder, ascending: true), NSSortDescriptor(keyPath: \Conversation.date, ascending: false)], animation: .none) var conversations: FetchedResults<Conversation>;
    @Environment(\.managedObjectContext) var moc;
    @State private var current : Conversation? = nil;
    public var onMessageAction : ((ChatElementAction, Message) -> Void)? = nil;
    @State private var openConvoSettingsPane : Bool = false;
    @Environment(\.openWindow) var openWindow;
    @State private var update : Bool = false;
    @AppStorage(PreferencesManager.StoredPreferenceKey.hide_conversation_summary) private var hide_conversation_summary : Bool = false;
    @AppStorage(PreferencesManager.StoredPreferenceKey.current_conversation) private var currentConversationUUIDString : String = "";
    @State private var searchString : String = "";
    @State private var selectMessage : Message? = nil;
    
    @Environment(\.colorScheme) var colorScheme;
    
    private var showSearchView : Bool {
        return searchString.count > 0
    }
    
    enum SearchScope: String, CaseIterable {
        case all, current
    }
    @State private var searchScope = SearchScope.current

    
    @ViewBuilder
    var sidepane: some View {
        VStack {
            // Divider()
            Button() {
                if let nc = newConvo {
                    select(nc())
                }
            } label: {
                Image(systemName: "plus.square")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
            } .buttonStyle(.borderless)
            
            List(selection: $current) {
                Spacer().frame(height:2)
                ForEach(conversations) {convo in
                    NavigationLink(value: convo) {
                        VStack (alignment: .leading) {
                            HStack {
                                TextField(text: Binding {
                                    return convo.title ?? "No title"
                                } set: { v in
                                    convo.title = v
                                    try? moc.save();
                                }) {
                                    Text("Untitled conversation")
                                } .padding([.leading], -3).bold()
                                Spacer()
                                Button {
                                    delConv?(convo)
                                    if current == convo {
                                        current = nil
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                } .buttonStyle(.borderless)
                            }
                            if hide_conversation_summary == false {
                                Text(convo.last_message == nil ? "Send your first message!" : convo.last_message!.content?.replacing(#/\n+/#, with: { _ in return " " }) ?? "Empty")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .opacity(0.6)
                                    .lineLimit(2)
                                    .padding([.leading], 5)
                                    .id(convo.update) // hack to force update
                            }
                        }.id(update)
                    }.padding([.top, .bottom], 5)

                } .onMove(perform: move)
            }
            Divider()
            Button {
                openSettings()
            } label: {
                Label("Settings", systemImage: "gearshape").labelStyle(.titleAndIcon)
            }
            .buttonStyle(.plain).padding([.bottom], 15)
            .padding([.top], 5)
            
        }
    }
    
    @ViewBuilder
    var detail: some View {
        if showSearchView {
            SearchView(text: $searchString, scope: $searchScope, current: $current) { message in
                searchString = ""
                if let c = message.belongs_to_convo {
                    select(c, selectMessage: message)
                }
            }
        } else {
            if let cur = current {
                if cur.id != nil {
                    ChatView(cur, onSend: onSend, selectMessage: $selectMessage) { (action, message) in
                        onMessageAction?(action, message)
                        if action == .branch {
                            if let c = conversations.first {
                                select(c)
                            }
                        }
                    } onStopGenerating: { m in
                        onMessageAction?(.stop, m)
                    }.environment(\.managedObjectContext, moc)
                } else {
                    Text("Error: conversation has no ID !")
                }
            }
            else {
                HomePane {
                    if let nc = newConvo {
                        select(nc())
                    }
                } openSettings: {
                    openSettings()
                }
            }
        }
    }
    
    func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
    
    var body: some View {
        NavigationSplitView(){
            sidepane
        } detail: {
            detail
        }
        .navigationTitle(current?.title ?? "Machato")
        #if os(macOS)
        .navigationSubtitle(current?.date?.formatted() ?? "") // TODO: show date elsewhere on iOS
        #endif
        .toolbar() {
            ToolbarItemGroup(placement: .primaryAction) {
                if let c = current {
                    ToolbarSettings(c)
                }
            }
        } .onAppear() {
            selectStoredCurrentConversation()
            MainView.updateCodeHighlightTheme(colorScheme)
        } .onChange(of: colorScheme) { nv in
            MainView.updateCodeHighlightTheme(nv)
        } .onChange(of: currentConversationUUIDString) { _ in
            selectStoredCurrentConversation()
        }.searchable(text: $searchString, placement: .toolbar)
            .searchScopes($searchScope) {
                ForEach(SearchScope.allCases, id: \.self) { scope in
                    if scope != .current || current != nil {
                        Text(scope.rawValue.capitalized)
                    }
                }
            }
    }
    
    func selectStoredCurrentConversation() {
        // print("Trying to select conversation \(currentConversationUUIDString)")
        let cuid = UUID(uuidString: currentConversationUUIDString)
        let candidates = conversations.filter { $0.id == cuid }
        if candidates.count == 1 {
            select(candidates.first!)
        }
    }
    
    static func updateCodeHighlightTheme(_ v: ColorScheme) {
        HighlightrSyntaxHighlighter.shared.setTheme(theme: v == .dark ? PreferencesManager.shared.darkTheme : PreferencesManager.shared.lightTheme)
        HighlightrSyntaxHighlighter.darkShared.setTheme(theme: PreferencesManager.shared.darkTheme)
    }
    
    func select(_ c: Conversation, selectMessage m: Message? = nil) -> Void {
        Task {
            try await Task.sleep(for: .milliseconds(10))
            current = c;
            currentConversationUUIDString = c.id?.uuidString ?? ""
                //try await Task.sleep(for: .milliseconds(1000))
            selectMessage = m
        }
    }
    
    init(newConvo: (() -> Conversation)? = nil,
         onSend: ((Conversation, String) -> Void)? = nil,
         delConv: ((Conversation) -> Void)? = nil,
         onMessageAction: ((ChatElementAction, Message) -> Void)? = nil) {
        self.newConvo = newConvo;
        self.onSend = onSend;
        self.delConv = delConv;
        self.onMessageAction = onMessageAction
    }
    
    private func move( from source: IndexSet, to destination: Int)
    {
        let currentUUID = current?.id?.uuidString ?? currentConversationUUIDString
        // Make an array of items from fetched results
        var revisedItems: [ Conversation ] = conversations.map{ $0 }

        // change the order of the items in the array
        revisedItems.move(fromOffsets: source, toOffset: destination )

        // update the userOrder attribute in revisedItems to
        // persist the new order. This is done in reverse order
        // to minimize changes to the indices.
        for reverseIndex in stride( from: revisedItems.count - 1,
                                    through: 0,
                                    by: -1 )
        {
            revisedItems[ reverseIndex ].userOrder =
                Int16( reverseIndex )
        }
        try? moc.save()
        Task {
            //try await Task.sleep(for: .milliseconds(1000))
            currentConversationUUIDString = currentUUID
            selectStoredCurrentConversation()
        }
    }
}
