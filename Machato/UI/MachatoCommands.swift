//
//  MachatoCommands.swift
//  Machato
//
//  Created by Théophile Cailliau on 10/04/2023.
//

import Foundation
import SwiftUI

struct MachatoCommands: Commands {
    private var onAction : (Self.Action) -> Void;
    public enum Action: CaseIterable {
        case new_convo
    }
    var body: some Commands {
        CommandGroup(after: .appInfo) {
            CheckForUpdatesView(updater: PreferencesManager.shared.updaterController.updater)
        }
        CommandGroup(after: .help) {
            CheckForUpdatesView(updater: PreferencesManager.shared.updaterController.updater)
        }
        CommandMenu("Conversation") {
            Button("New conversation") {
                onAction(.new_convo)
            }.keyboardShortcut("n", modifiers: [.command])
        }
        SidebarCommands()
    }
    
    init(onAction: @escaping (Self.Action) -> Void) {
        self.onAction = onAction
    }
}

