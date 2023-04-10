//
//  Settings.swift
//  Machato
//
//  Created by Théophile Cailliau on 26/03/2023.
//

import Foundation

enum OpenAIChatModel: String, CaseIterable, Identifiable {
    case gpt_4              = "gpt-4"
    case gpt_4_32k          = "gpt-4-32k"
    case gpt_35_turbo       = "gpt-3.5-turbo"
    
    var id : String { return self.rawValue }
    static let default_case : Self = .gpt_35_turbo
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
