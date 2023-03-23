//
//  ContentView.swift
//  Machato
//
//  Created by Théophile Cailliau on 24/03/2023.
//

import SwiftUI
import CoreData

struct MainView: View {
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Conversation.userOrder, ascending: true), NSSortDescriptor(keyPath: \Conversation.date, ascending: false)], animation: .none) var conversations: FetchedResults<Conversation>;
    @Environment(\.managedObjectContext) var moc;
    @State private var current : Conversation? = nil;
    @State private var openConvoSettingsPane : Bool = false;
    @Environment(\.openWindow) var openWindow;
    @Environment(\.dismiss) var dismiss;
    @State private var update : Bool = false;
    @AppStorage(PreferencesManager.StoredPreferenceKey.hideTokenCount) private var hideTokenCount = false;
    @State private var searchString : String = "";
    @State private var selectMessage : Message? = nil;
    
    @AppStorage(PreferencesManager.StoredPreferenceKey.hasLaunched) var haslaunched : Bool = false;
    
    @Environment(\.isSearching) private var isSearching
    
    @Environment(\.colorScheme) var colorScheme;
    
    @ObservedObject private var prefs = PreferencesManager.shared
            
    enum SearchScope: String, CaseIterable {
        case all, current
    }
    @State private var searchScope = SearchScope.all
    
    @ViewBuilder
    var sidepane: some View {
        VStack {
            Divider()            
            ConversationList(current: $current, children: conversations.filter { $0.belongs_to_folder == nil }).padding([.top], 10)
            
            Divider()
            if !hideTokenCount {
                TokenUsagePriceTag()
            }
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
        ZStack (alignment: .topLeading) {
            if let current = current {
                ChatView(current, selectMessage: $selectMessage).id(current.id)
                    .animation(.easeInOut(duration: 0.2), value: current)
            } else  {
                HomePane()
            }
            SearchView(text: $searchString, scope: $searchScope, current: $current) { message in
                searchString = ""
                if let c = message.belongs_to_convo {
                    select(c, selectMessage: message)
                }
            }.equatable().background(.ultraThinMaterial.shadow(.drop(radius: 5))).frame(maxHeight: 300)
        }
    }
    
    func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
    
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationSplitView {
            sidepane
                .navigationSplitViewColumnWidth(min: 250, ideal: 300)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button() {
                            select(DataActions.shared.newConversation())
                        } label: {
                            Image(systemName: "plus.bubble")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                        } .buttonStyle(.borderless) .help("New conversation")
                            .padding([.leading, .trailing], 10)

                    }
                    ToolbarItem(placement: .primaryAction) {

                        Button() {
                            let _ = DataActions.shared.newFolder(title: "New folder", convo: current)
                        } label: {
                            Image(systemName: "folder.badge.plus")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 22, height: 22).padding([.bottom], 2)
                        } .buttonStyle(.borderless) .help("New folder")
                            .padding([.leading, .trailing], 10)
                    }
                    ToolbarItem(placement: .primaryAction) {

                        Button() {
                            current = nil
                        } label: {
                            Image(systemName: "house")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20).padding([.bottom], 2)
                        } .buttonStyle(.borderless) .help("Home")
                            .padding([.leading, .trailing], 10)

                    }
                }
        } detail: {
            NavigationStack(path: $path.animation(.linear(duration: 0))) { // fix xcode 14.3 animation bug
                detail
            }
        .navigationSplitViewColumnWidth(min: 500, ideal: 500)
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
            if !haslaunched {
                openWindow(id: "greetings")
            }
            selectStoredCurrentConversation()
        }  .onReceive(Signals.shared.selectConversationPublisher, perform: { uuid in
            select(uuid)
        })
        .onChange(of: current) { _ in
            PreferencesManager.shared.currentConversation = current?.id?.uuidString ?? ""
            current?.unread = false
        }
        .searchable(text: $searchString, placement: .toolbar)
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
        let cuid = UUID(uuidString: PreferencesManager.shared.currentConversation)
        let candidates = conversations.filter { $0.id == cuid }
        if candidates.count == 1 {
            let selected = candidates.first!
            selected.expandParents()
            select(selected)
        }
    }
    
    
    func select(_ c: Conversation, selectMessage m: Message? = nil) -> Void {
        Task {
            try await Task.sleep(for: .milliseconds(10))
            current = c;
            PreferencesManager.shared.currentConversation = c.id?.uuidString ?? ""
            //try await Task.sleep(for: .milliseconds(1000))
            selectMessage = m
        }
    }
    
    func select(_ uuid: UUID? = nil) {
        if uuid == nil {
            current = nil
        } else {
            current = conversations.first(where: { $0.id == uuid! })
        }
    }
}
