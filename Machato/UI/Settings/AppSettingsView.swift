//
//  AppSettingsView.swift
//  Machato
//
//  Created by Théophile Cailliau on 09/04/2023.
//

import SwiftUI
import Sparkle

struct AppSettingsView: View {
    private var updater: SPUUpdater;
    private enum Tabs: Hashable {
        case general, update, appearance, keys
    }
    var body: some View {
        TabView {
            KeysSettingsView()
                .tabItem {
                    Label("Keys", systemImage: "person.badge.key")
                } .tag(Tabs.keys)
            SettingsView()
                .tabItem {
                    Label("Conversation", systemImage: "text.bubble")
                }
                .tag(Tabs.general)
            AppearanceSettings()
                .tabItem {
                    Label("Appearance", systemImage: "text.and.command.macwindow")
                }
                .tag(Tabs.appearance)
            CodeBlockSettings()
                .tabItem {
                    Label("Code Blocks", systemImage: "chevron.left.forwardslash.chevron.right")
                }
            UpdaterSettingsView(updater: updater)
                .tabItem {
                    Label("Update", systemImage: "square.and.arrow.down")
                }
                .tag(Tabs.update)
        }
        .padding(20)
        .frame(minWidth: 400)
    }
    init(updater: SPUUpdater) {
        self.updater = updater
    }
}
