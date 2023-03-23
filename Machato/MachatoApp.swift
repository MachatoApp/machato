//
//  MachatoApp.swift
//  Machato
//
//  Created by Théophile Cailliau on 24/03/2023.
//

import SwiftUI
import CoreData
#if !MAS
import Sparkle
#endif
import Colorful
import Combine

@main
class MachatoApp: App {
    #if !MAS
    private let updaterController: SPUStandardUpdaterController = PreferencesManager.shared.updaterController
    #endif
    
#if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#endif
    
    required init() {
        let _ = NSApplication.shared // https://developer.apple.com/forums/thread/711122
        print(NSApplication.shared.isRunning)
        Task {
            await TokenCounter.shared.initEncoder()
        }
        ModelManager.shared.updateAvailableModels()
    }
    
    private var persistentContainer : NSPersistentContainer = PreferencesManager.shared.persistentContainer;
    
    @ObservedObject var prefs : PreferencesManager = PreferencesManager.shared;
    
    var body: some Scene {
        WindowGroup(id: "machato") {
            MainView ()
                .environment(\.managedObjectContext, persistentContainer.viewContext)
                .onAppear() {
                    self.initialize()
                } .preferredColorScheme(prefs.colorScheme == .system ? nil : prefs.colorScheme == .dark ? .dark : .light)
        }.commands {
            MachatoCommands ()
        } .defaultSize(width: 900, height: 600)
        Settings {
            #if MAS
            let settingsView = AppSettingsView()
            #else
            let settingsView = AppSettingsView(updater: updaterController.updater)
            #endif
            settingsView.preferredColorScheme(prefs.colorScheme == .system ? nil : prefs.colorScheme == .dark ? .dark : .light)
                .environment(\.managedObjectContext, persistentContainer.viewContext)
        }
        Window("Machato", id: "greetings") {
            Greetings() .ignoresSafeArea().environment(\.managedObjectContext, persistentContainer.viewContext)
                //.background(ColorfulView(blurRadius: 100, colors: [AppColors.matcha]).ignoresSafeArea())
                .background(VisualEffect().ignoresSafeArea())
        }.windowStyle(.hiddenTitleBar).windowResizability(.contentSize)
        WindowGroup("System Prompt", id: "system-prompt", for: Conversation.ID.self) { convoId in
            SystemPromptInputView(convoid: Binding(get: {
                convoId.wrappedValue ?? nil
            }, set: { v in
                
            })
            ).environment(\.managedObjectContext, self.persistentContainer.viewContext)
        }.windowResizability(.contentSize)
        Window("Prompt Library", id: "prompt-library") {
            PromptLibrary()
                .environment(\.managedObjectContext, persistentContainer.viewContext)
        }.windowResizability(.contentSize).defaultSize(CGSize(width: 300, height: 500))
        MenuBarExtra {
            MenuContent().environment(\.managedObjectContext, persistentContainer.viewContext)
        } label: {
            let image: NSImage = {
                let ratio = $0.size.height / $0.size.width
                $0.size.height = 18
                $0.size.width = 18 / ratio
                return $0
            }(NSImage(named: "menulogo")!)
            Image(nsImage: image)
        }
        //.menuBarExtraStyle(.window)
    }
    
    func initialize() {
        if PreferencesManager.shared.defaultsInitialized == false {
            PreferencesManager.restoreDefaults()
        }
        if PreferencesManager.shared.fontSize < 10 {
            PreferencesManager.shared.fontSize = 13;
        }
        if PreferencesManager.shared.maxWidth == .zero {
            PreferencesManager.shared.maxWidth = 800
        }
        if PreferencesManager.shared.defaultTopP == .zero {
            PreferencesManager.shared.defaultTopP = 1
        }
        TokenUsageManager.shared.updateCost()
        
        let key = PreferencesManager.shared.api_key
        if !key.isEmpty {
            let model = Model(context: persistentContainer.viewContext)
            model.date_added = Date.now
            model.name = "Default"
            model.openai_prefix = ""
            model.type = "openai"
            model.openai_enabled_models = "gpt-3.5-turbo;gpt-4;gpt-4-32k;"
            model.openai_api_key = key
            ModelManager.shared.updateAvailableModels()
            PreferencesManager.shared.api_key = ""
        }
        let fr = Function.fetchRequest()
        if let results = try? persistentContainer.viewContext.fetch(fr), results.isEmpty {
            AvailableFunction.allCases.filter { $0.customisable == false }.forEach { fun in
                let function = Function(context: persistentContainer.viewContext)
                function.type = fun.name
                function.id = UUID()
                function.customisable = false
                function.nickname = fun.name
                function.authfamily = "none"
            }
            try? persistentContainer.viewContext.save()
        }
    }
    
}

#if os(macOS)
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    
    func applicationWillTerminate(_ aNotification: Notification) {
        do {
            try PreferencesManager.shared.persistentContainer.viewContext.save()
        } catch {
            print(error)
        }
    }
    
    
    //    func applicationWillUpdate(_ notification: Notification) {
    //        if let menu = NSApplication.shared.mainMenu {
    //            //menu.items.removeAll{ $0.title == "Edit" }
    //            menu.items.removeAll{ $0.title == "File" }
    //            menu.items.removeAll{ $0.title == "Window" }
    //            menu.items.removeAll{ $0.title == "View" }
    //        }
    //    }
    
    private var aboutBoxWindowController: NSWindowController?
    
    func showAboutWnd() {
        if aboutBoxWindowController == nil {
            let styleMask: NSWindow.StyleMask = [.closable, .miniaturizable,/* .resizable,*/ .titled]
            let window = NSWindow()
            window.styleMask = styleMask
            window.titlebarAppearsTransparent = true
            window.title = "About \(Bundle.main.appName)"
            window.contentView = NSHostingView(rootView: AboutView())
            window.center()
            aboutBoxWindowController = NSWindowController(window: window)
        }
        
        aboutBoxWindowController?.showWindow(aboutBoxWindowController?.window)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
        let mainWindow = NSApp.windows.first
        mainWindow?.delegate = self
    }
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if sender.title.contains("Prompt") {
            return true
        }
        NSApp.hide(nil)
        return false
    }
}
#endif
