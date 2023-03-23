//
//  UnitConverter.swift
//  Machato
//
//  Created by Théophile Cailliau on 17/06/2023.
//

import Foundation
import JavaScriptCore


struct ConvertJS {
    static public let shared = ConvertJS();
    
    private var convert : JSValue? = nil;
    
    init() {
        let jsContext = JSContext()!
        guard let fileURL = Bundle.main.url(forResource: "convert.prod", withExtension: "js") else {
            print("bundle not found")
            return
        }
        let fileContents = try? String(contentsOf: fileURL, encoding: .utf8)
        jsContext.evaluateScript(fileContents)
        guard let parse = jsContext.objectForKeyedSubscript("convert") else {
            print("convert was nil")
            return
        }
        convert = parse
    }
    
    func convert(value : Double, unit_start : String, unit_end : String) -> Double? {
        return convert?.invokeMethod("convert", withArguments: [value, unit_start.replacingOccurrences(of: "°", with: "")])?.invokeMethod("to", withArguments: [unit_end.replacingOccurrences(of: "°", with: "")])?.toNumber().doubleValue
    }
}

struct UnitConverter : OpenAIFunction {
    static let name: String = "convert_units"
    static let description: String = "Convert a quantity from one unit to another homogenous unit"
    static let argumentDescription: [String : Any] = [
        "value": [
            "type": "number",
            "description": "The raw value to convert from",
        ] as [String : String],
        "unit_from": [
            "type": "string",
            "description": "The symbol of the starting unit",
        ] as [String : String],
        "unit_to": [
            "type": "string",
            "description": "The symbol of the ending unit",
        ] as [String : String]
    ] as [String : Any];
    static let required = ["value", "unit_from", "unit_to"]
    
    struct Arguments : Codable {
        var value : Double;
        var unit_from : String;
        var unit_to : String;
    }
    
    func displayDescription(args: String) throws -> String {
        let parsed = try parseArguments(str: args)
        return "Unit converter: \(parsed.value)\(parsed.unit_from) to \(parsed.unit_to)"
    }
    
    func doConversion(of args: Arguments) async throws -> Double {
        guard let result = ConvertJS.shared.convert(value: args.value, unit_start: args.unit_from, unit_end: args.unit_to) else {
            throw FunctionError.executionFailed(message: "Conversion failed")
        }
        guard !result.isNaN else {
            throw FunctionError.executionFailed(message: "Conversion failed")
        }
        return result
    }
    
    func execute(arguments args: Arguments) async throws -> String {
        let splitFrom = args.unit_from.split(separator: "/").map { String($0) }
        let splitTo = args.unit_to.split(separator: "/").map { String($0) }
        if splitFrom.count == 2 && splitTo.count == 2 {
            let resultA = try await doConversion(of: Arguments(value: args.value, unit_from: splitFrom[0], unit_to: splitTo[0]))
            let resultB = try await doConversion(of: Arguments(value: 1, unit_from: splitFrom[1], unit_to: splitTo[1]))
            return (resultA/resultB).description
        } else {
            return try await doConversion(of: args).description
        }
    }
}
