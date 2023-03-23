//
//  ClaudeModels.swift
//  Machato
//
//  Created by Théophile Cailliau on 05/07/2023.
//

import Foundation

enum AnthropicModel: String, CaseIterable, Identifiable, ModelEnum {
    case claude_instant_v1      = "claude-instant-1"
    case claude_instant_v1_100k = "claude-instant-1-100k"
    case claude_v2              = "claude-2"

    var contextLength : Int32 {
        switch self {
        case .claude_instant_v1:
            return 9_000
        case .claude_instant_v1_100k, .claude_v2:
            return 100_000
        }
    }
    
    var id : String { return self.rawValue }
    static let default_case : Self = .claude_v2
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
