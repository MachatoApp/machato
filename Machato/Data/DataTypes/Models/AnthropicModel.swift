//
//  ClaudeModels.swift
//  Machato
//
//  Created by Théophile Cailliau on 05/07/2023.
//

import Foundation

enum AnthropicModel: String, CaseIterable, Identifiable, ModelEnum {
    case claude_3_haiku           = "claude-3-haiku-20240307"
    case claude_3_opus            = "claude-3-opus-20240229"
    case claude_3_sonnet          = "claude-3-sonnet-20240229"
    case claude_35_sonnet         = "claude-3-5-sonnet-20240620"

    var contextLength : Int32 {
        switch self {
        default:
            return 200_000
        }
    }
    
    var maxTokens : Int32 {
        4096
    }
    
    var id : String { return self.rawValue }
    static let default_case : Self = .claude_3_haiku
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
