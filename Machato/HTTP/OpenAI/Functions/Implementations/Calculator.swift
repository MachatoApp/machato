//
//  Calculator.swift
//  Machato
//
//  Created by Théophile Cailliau on 14/06/2023.
//

import Foundation
import MathParser

struct Calculator : OpenAIFunction {
    static let name: String = "calculator"
    static let description: String = "Evaluate a mathematical expression"
    static let argumentDescription: [String : Any] = [
        "expression": [
            "type": "string",
            "description": "The mathematical expression to evaluate.",
        ] as [String : String]
    ] as [String : Any];
    
    struct Arguments : Codable {
        var expression : String;
    }
    
    func displayDescription(args: String) throws -> String {
        "`calculator`: \(try parseArguments(str: args).expression)"
    }
    
    func execute(arguments args: Arguments) async throws -> String {
//        print(args.expression)
        do {
            return try args.expression.replacing("^", with: "**").evaluate().description
        } catch {
            throw FunctionError.executionFailed(message: error.localizedDescription)
        }
    }
}
