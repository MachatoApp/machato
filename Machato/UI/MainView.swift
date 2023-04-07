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
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Conversation.userOrder, ascending: true), NSSortDescriptor(keyPath: \Conversation.date, ascending: false)], animation: .default) var conversations: FetchedResults<Conversation>;
    @Environment(\.managedObjectContext) var moc;
    @State private var current : Conversation? = nil;
    public var onMessageAction : ((ChatElementAction, Message) -> Void)? = nil;
    @State private var openSettingsPane : Bool = false;
    @State private var openConvoSettingsPane : Bool = false;
    @Environment(\.openWindow) var openWindow;
    @State private var update : Bool = false;
    
    @Environment(\.colorScheme) var colorScheme
    
    @ViewBuilder
    var sidepane: some View {
        VStack {
            // Divider()
            Button() {
                if let nc = newConvo {
                    current = nc()
                }
            } label: {
                Image(systemName: "plus.square")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
            } .buttonStyle(.borderless).padding([.bottom], 15)
            
            List(conversations, selection: $current) { convo in
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
                                if let dc = delConv {
                                    dc(convo)
                                }
                                if current == convo {
                                    current = nil
                                }
                            } label: {
                                Image(systemName: "trash")
                            } .buttonStyle(.borderless)
                        }
                        if PreferencesManager.shared.hide_conversation_summary == false {
                            Text(convo.last_message == nil ? "Send your first message!" : convo.last_message!.content?.replacing(#/\n+/#, with: { _ in return " " }) ?? "Empty")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .opacity(0.6)
                                .lineLimit(2)
                                .padding([.leading], 5)
                                .id(convo.update) // hack to force update
                        }
                    }.id(update)
                }.padding([.top, .bottom], 5) .onChange(of: current) {nc in
                    UserDefaults.standard.set(nc?.id?.uuidString ?? "", forKey: "current_uuid")
                }
            } .listStyle(.sidebar)
            Divider()
            Button {
                openSettingsPane = true;
            } label: {
                Label("Settings", systemImage: "gearshape").labelStyle(.titleAndIcon)
            }
            .buttonStyle(.plain).padding([.bottom], 15)
            .padding([.top], 5)
            .sheet(isPresented: $openSettingsPane) {
                SettingsView()
            } .onChange(of: openSettingsPane) { _ in
                update.toggle()
            }
        }
    }
    
    @ViewBuilder
    var detail: some View {
        if let cur = current {
            if cur.id != nil {
                ChatView(cur, onSend: onSend) { (action, message) in
                    if let oma = onMessageAction {
                        oma(action, message)
                    }
                    if action == .branch {
                        if let c = conversations.first {
                            select(c)
                        }
                    }
                } .environment(\.managedObjectContext, moc)
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
                openSettingsPane = true
            }
        }
    }
    
    var body: some View {
        NavigationSplitView(){
            sidepane
        } detail: {
            detail
        }
        .navigationTitle(current?.title ?? "Machato")
        #if os(macOS)
        .navigationSubtitle(current?.date?.formatted() ?? "") // TODO: show date elsewhere
        #endif
        .toolbar() {
            ToolbarItemGroup(placement: .primaryAction) {
                if let c = current {
                    let cs = PreferencesManager.getConversationSettings(c)
                    Chip(cs.model.rawValue.uppercased())
                    Chip(cs.typeset.description.uppercased())
                    Button() {
                        openConvoSettingsPane = true
                    } label: {
                        Label("Conversation settings", systemImage: "gearshape")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.bordered)
                    .sheet(isPresented: $openConvoSettingsPane) {
                        c.update.toggle()
                    } content: {
                        SettingsView(forConvo: c)
                    }
                }
            }
        } .onAppear() {
            if let cuids = UserDefaults.standard.string(forKey: "current_uuid") {
                print("Trying to select conversation \(cuids)")
                let cuid = UUID(uuidString: cuids)
                let candidates = conversations.filter { $0.id == cuid }
                if candidates.count == 1 {
                    print("Found conversation")
                    select(candidates.first!)
                }
            }
            updateCodeHighlightTheme(colorScheme)
        } .onChange(of: colorScheme) { nv in
            updateCodeHighlightTheme(nv)
        }
    }
    
    func updateCodeHighlightTheme(_ v: ColorScheme) {
        HighlightrSyntaxHighlighter.shared.setTheme(theme: v == .dark ? AppColors.darkCodeTheme : AppColors.lightCodeTheme)
    }
    
    func select(_ c: Conversation) -> Void {
        // TODO: hack
        Task {
            try await Task.sleep(for: .milliseconds(100))
            current = c;
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
}

struct ContentView_Previews: PreviewProvider {
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ChatModel")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        return container
    }()
    
    
    static var previews: some View {
        MainView()
    }
}
