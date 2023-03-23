//
//  Settings.swift
//  Machato
//
//  Created by Théophile Cailliau on 26/03/2023.
//

import Foundation

protocol ModelEnum {
    var contextLength : Int32 { get }
}

enum OpenAIChatModel: String, CaseIterable, Identifiable, ModelEnum {
    case gpt_4              = "gpt-4"
    case gpt_4_32k          = "gpt-4-32k"
    case gpt_35_turbo       = "gpt-3.5-turbo"
    case gpt_35_turbo_16k   = "gpt-3.5-turbo-16k"
    case gpt_35_turbo_1103  = "gpt-3.5-turbo-1106"
    case gpt_4_turbo        = "gpt-4-1106-preview"
    
    var contextLength : Int32 {
        switch self {
        case .gpt_35_turbo:
            return 4_096
        case .gpt_4:
            return 8_192
        case .gpt_4_32k:
            return 32_768
        case .gpt_35_turbo_16k, .gpt_35_turbo_1103:
            return 16_385
        case .gpt_4_turbo:
            return 128_000
        }
    }
    
    var supportsFunctionCalling : Bool {
        switch self {
        case .gpt_4_turbo, .gpt_35_turbo_16k, .gpt_4, .gpt_35_turbo_1103:
            return true
        default:
            return false
        }
    }
    
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
