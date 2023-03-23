//
//  MachatoCommands.swift
//  Machato
//
//  Created by Théophile Cailliau on 10/04/2023.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct MachatoCommands: Commands {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) var openWindow;
    @Environment(\.openURL) var openURL;
    
    @State private var exportVisible : Bool = false
    @State private var document : ConversationDocument? = nil;

    var body: some Commands {
        #if !MAS
        CommandGroup(after: .appInfo) {
            CheckForUpdatesView(updater: PreferencesManager.shared.updaterController.updater)
        }
        #endif
        CommandGroup(replacing: .help) {
            #if !MAS
            CheckForUpdatesView(updater: PreferencesManager.shared.updaterController.updater)
            #endif
            Button("Machato FAQ") {
                if let url = URL(string: "https://machato.app/faq") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
        CommandGroup(replacing: .newItem) {
            
        }
        CommandGroup(replacing: .importExport) {
            Button("Export conversation") {
                let fr = Conversation.fetchRequest()
                fr.predicate = NSPredicate(format: "id == %@", (UUID(uuidString: PreferencesManager.shared.currentConversation) ?? UUID()) as CVarArg)
                guard let c = try? PreferencesManager.shared.persistentContainer.viewContext.fetch(fr).first else { return }
                document = ConversationDocument(convo: c)
                exportVisible = true
            }.fileExporter(isPresented: $exportVisible, document: document, contentType: UTType.text, defaultFilename: document?.title) { a in
                switch a {
                case .success(let file):
                    NSWorkspace.shared.activateFileViewerSelecting([file])
                case .failure(let err):
                    print(err)
                }
            }
        }
        CommandMenu("Conversation") {
            Button("Share conversation") {
                let fr = Conversation.fetchRequest()
                fr.predicate = NSPredicate(format: "id == %@", (UUID(uuidString: PreferencesManager.shared.currentConversation) ?? UUID()) as CVarArg)
                guard let c = try? PreferencesManager.shared.persistentContainer.viewContext.fetch(fr).first else { return }
                Task {
                    guard let sharelink = await ShareGPT.shared.share(conversation: c) else {
                        return
                    }
                    openURL(URL(string: sharelink)!)
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(sharelink, forType: .URL)
                }
            }
            Divider()
            Button("Select above") {
                guard let convos = try? convoDFS() else { return }
                let currentuid = PreferencesManager.shared.currentConversation
                guard let i = convos.firstIndex(where: { $0.id?.uuidString == currentuid}) else { return }
                guard i > 0 else { return } // no conversation above
                Signals.shared.selectConversation(convos[i-1])
            }.keyboardShortcut("{", modifiers: .command)
            Button("Select below") {
                guard let convos = try? convoDFS() else { return }
                let currentuid = PreferencesManager.shared.currentConversation
                guard let i = convos.firstIndex(where: { $0.id?.uuidString == currentuid}) else { return }
                guard i + 1 < convos.count else { return } // no conversation above
                Signals.shared.selectConversation(convos[i+1])
            }.keyboardShortcut("}", modifiers: .command)
            Divider()
            Button("Search") {
//            https://developer.apple.com/forums/thread/688679
                if let toolbar = NSApp.keyWindow?.toolbar,
                   let search = toolbar.items.first(where: { $0.itemIdentifier.rawValue == "com.apple.SwiftUI.search" }) as? NSSearchToolbarItem {
                    search.beginSearchInteraction()
                }
            }.keyboardShortcut("f", modifiers: .command)
            Divider()
            Button("New conversation") {
                let nc = DataActions.shared.newConversation()
                Signals.shared.selectConversation(nc)
            }.keyboardShortcut("n", modifiers: [.command])
            Button("Clear current conversation") {
                Signals.shared.clearConversationSignal.send()
            }.keyboardShortcut(.delete, modifiers: [.command, .shift])
        }
        CommandMenu("Prompts") {
            Button ("Prompt Library") {
                openWindow(id: "prompt-library")
            }.keyboardShortcut("p", modifiers: .command)
        }
        SidebarCommands()
        CommandGroup(replacing: CommandGroupPlacement.appInfo) {
            Button("About \(Bundle.main.appName)") { appDelegate.showAboutWnd() }
        }
    }
    
    @MainActor
    func convoDFS(parent : Conversation? = nil) throws -> [Conversation] {
        let fr = Conversation.fetchRequest()
        fr.sortDescriptors = [NSSortDescriptor(keyPath: \Conversation.userOrder, ascending: true), NSSortDescriptor(keyPath: \Conversation.date, ascending: false)]
        if let parent = parent {
            fr.predicate = NSPredicate(format: "%K == %@", #keyPath(Conversation.belongs_to_folder), parent as CVarArg)

        } else {
            fr.predicate = NSPredicate(format: "belongs_to_folder == nil")
        }
        let convos = try PreferencesManager.shared.persistentContainer.viewContext.fetch(fr)
        var result : [Conversation] = []
        try convos.enumerated().forEach { i, value in
            let convo = convos[i]
            if convo.is_folder {
                try result.append(contentsOf: convoDFS(parent: convo))
            } else {
                result.append(convo)
            }
        }
        return result
    }
}
