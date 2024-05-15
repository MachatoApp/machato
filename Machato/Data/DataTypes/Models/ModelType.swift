//
//  ModelTypes.swift
//  Machato
//
//  Created by Théophile Cailliau on 05/06/2023.
//

import Foundation

enum ModelType : String, CaseIterable, Identifiable {
    case openai, azure, anthropic, local
    
    var id : Self { self }
    
    var description : String {
        switch self {
        case .openai:
            return "OpenAI"
        case .azure:
            return "Azure"
        case .anthropic:
            return "Anthropic"
        case .local:
            return "Ollama"
        }
    }
    
    static let default_case : Self = .openai
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
