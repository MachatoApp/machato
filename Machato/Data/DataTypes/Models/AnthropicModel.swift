//
//  ClaudeModels.swift
//  Machato
//
//  Created by Théophile Cailliau on 05/07/2023.
//

import Foundation

enum AnthropicModel: String, CaseIterable, Identifiable, ModelEnum {
    case claude_instant_v1      = "claude-instant-1.2"
    case claude_v2              = "claude-2"
    case claude_v2_1            = "claude-2.1"
    case claude_haiku           = "claude-3-haiku-20240307"
    case claude_opus            = "claude-3-opus-20240229"
    case claude_sonnet          = "claude-3-sonnet-20240229"

    var contextLength : Int32 {
        switch self {
        case .claude_instant_v1, .claude_v2:
            return 100_000
        default:
            return 200_000
        }
    }
    
    var maxTokens : Int32 {
        4096
    }
    
    var id : String { return self.rawValue }
    static let default_case : Self = .claude_haiku
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
