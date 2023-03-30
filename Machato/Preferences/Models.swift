//
//  Settings.swift
//  Machato
//
//  Created by Théophile Cailliau on 26/03/2023.
//

import Foundation

enum OpenAIChatModel: String, CaseIterable, Identifiable {
    case gpt_4              = "gpt-4"
    case gpt_4_0314         = "gpt-4-0314"
    case gpt_4_32k          = "gpt-4-32k"
    case gpt_4_32k_0314     = "gpt-4-32k-0314"
    case gpt_35_turbo       = "gpt-3.5-turbo"
    case gpt_35_turbo_0301  = "gpt-3.5-turbo-0301"
    
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
