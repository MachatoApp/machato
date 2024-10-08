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
    case gpt_4               = "gpt-4"
    case gpt_35_turbo        = "gpt-3.5-turbo"
    case gpt_4_turbo         = "gpt-4-turbo"
    case gpt_4o              = "gpt-4o"
    case gpt_4o_20240806     = "gpt-4o-2024-08-06"
    case gpt_4o_mini         = "gpt-4o-mini"

    var contextLength : Int32 {
        switch self {
        case .gpt_35_turbo:
            return 16_385
        case .gpt_4:
            return 8_192
        case .gpt_4_turbo, .gpt_4o, .gpt_4o_20240806, .gpt_4o_mini:
            return 128_000
        }
    }
    
    var supportsFunctionCalling : Bool { true } // previously conditional
    
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
