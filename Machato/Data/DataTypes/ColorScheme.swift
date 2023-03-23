//
//  ColorScheme.swift
//  Machato
//
//  Created by Théophile Cailliau on 14/04/2023.
//

import Foundation

enum AppColorScheme: String, CaseIterable, Identifiable {
    case light, dark, system;
    
    var id : String { return self.rawValue }
    static let default_case : Self = .system
    static func fromString(_ sm: String?) -> Self {
        guard let s = sm else { return default_case }
        for c in Self.allCases {
            if c.rawValue == s {
                return c
            }
        }
        return default_case
    }
}
