//
//  AppSettingsView.swift
//  Machato
//
//  Created by Théophile Cailliau on 09/04/2023.
//

import SwiftUI
#if !MAS
import Sparkle
#endif

struct AppSettingsView: View {
    #if !MAS
    private var updater: SPUUpdater;
    #endif
    
    private enum Tabs: Hashable {
        case general, update, appearance, keys, token, code, behavior, functions
    }
    
    @State private var tab : Tabs = .general;
    
    var body: some View {
        TabView(selection: $tab) {
            SettingsView()
                .tag(Tabs.general)
                .tabItem {
                    Label("Conversation", systemImage: "text.bubble")
                }
            BehaviorSettings()
                .tag(Tabs.behavior)
                .tabItem {
                    Label("Behavior", systemImage: "command.square")
                }
            FunctionsSettings()
                .tag(Tabs.functions)
                .tabItem {
                    Label("Functions", systemImage: "f.cursive")
                }
            AppearanceSettings()
                .tag(Tabs.appearance)
                .tabItem {
                    Label("Appearance", systemImage: "text.and.command.macwindow")
                }
            CodeBlockSettings()
                .tag(Tabs.code)
                .tabItem {
                    Label("Code Blocks", systemImage: "chevron.left.forwardslash.chevron.right")
                }
            TokenSettings()
                .tag(Tabs.token)
                .tabItem {
                    Label("Cost estimation", systemImage: "dollarsign")
                }
            KeysSettingsView()
                .tag(Tabs.keys)
                .tabItem {
                    Label("Keys & Sync", systemImage: "person.badge.key")
                }
            #if !MAS
            UpdaterSettingsView(updater: updater)
                .tag(Tabs.update)
                .tabItem {
                    Label("Update", systemImage: "square.and.arrow.down")
                }
            #endif
        }
        .padding(20)
        .frame(width: 650)
        .onReceive(Signals.shared.keySettings) { _ in
            print("received")
            tab = .keys
        }
    }
    #if !MAS
    init(updater: SPUUpdater) {
        self.updater = updater
    }
    #endif
}
