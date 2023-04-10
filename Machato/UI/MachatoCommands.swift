//
//  MachatoCommands.swift
//  Machato
//
//  Created by Théophile Cailliau on 10/04/2023.
//

import Foundation
import SwiftUI

struct MachatoCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .appInfo) {
            CheckForUpdatesView(updater: PreferencesManager.shared.updaterController.updater)
        }
        CommandGroup(after: .help) {
            CheckForUpdatesView(updater: PreferencesManager.shared.updaterController.updater)
        }
        SidebarCommands()
    }
}

