//
//  TypesetFunctionalities.swift
//  Machato
//
//  Created by Théophile Cailliau on 28/03/2023.
//

import Foundation

enum TypesetFunctionality: String, CaseIterable, Identifiable {
    case markdown = "markdown", mathjax = "mathjax", plain = "plain"
    var description : String {
        switch self {
        case .markdown:
            return "Markdown"
        case .mathjax:
            return "LaTeX"
        case .plain:
            return "Plain"
        }
    }
    var id : Self { self }
    
    static let default_case : Self = .markdown
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
