//
//  View+Extension.swift
//  Machato
//
//  Created by Théophile Cailliau on 05/07/2023.
//

import Foundation
import SwiftUI

private struct EditingModeKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var editingSidepane: Bool {
        get { self[EditingModeKey.self] }
        set { self[EditingModeKey.self] = newValue }
    }
}
