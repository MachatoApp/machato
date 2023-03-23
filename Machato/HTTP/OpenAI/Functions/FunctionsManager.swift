//
//  FunctionsManager.swift
//  Machato
//
//  Created by Théophile Cailliau on 14/06/2023.
//

import Foundation

protocol OpenAIFunction {
    associatedtype Arguments : Codable
    static var name : String { get };
    static var description : String { get };
    static var argumentDescription : [String : Any] { get };
    static var parameters : [String : Any] { get }
    static var required : [String] { get };
    var conversation : Conversation? { get set };
    var expandOnResult : Bool { get };
    
    func displayDescription(args: String) throws -> String
    
    func parseArguments(str: String) throws -> Arguments
    func execute (arguments : String) async throws -> String
    
    func execute (arguments : Arguments) async throws -> String
}

extension OpenAIFunction {
    var expandOnResult : Bool {
        false
    }
    
    static var parameters : [String : Any ] {
        [
            "type": "object",
            "properties": Self.argumentDescription,
            "required": Self.required
        ] as [String: Any]
    }
    
    var conversation : Conversation? {
        get {
            nil
        }
        set {
            // unimplemented by default
        }
    }
    
    static var required : [String] {
        argumentDescription.keys.unique()
    }
    
    func parseArguments(str : String) throws -> Arguments {
        do {
            return try JSONDecoder().decode(Arguments.self, from: str.data(using: .utf8)!)
        } catch {
            throw FunctionError.malformedInput
        }
    }
    func execute(arguments : String) async throws -> String {
        return try await execute(arguments: parseArguments(str: arguments))
    }
    func displayDescription(args: String) throws -> String {
        "*`\(name)`: `\(args.replacing(#/\s+/#, with: " "))`*"
    }
    var name : String { Self.name }
    var description : String { Self.description }
    var argumentDescription: [String : Any] { Self.argumentDescription }
    var required : [String] { Self.required }
    var parameters : [String : Any] { Self.parameters }
}

struct  AvailableFunction : CaseIterable, Equatable {
    static var allCases: [AvailableFunction] = [.calculator, .openweathermapCity, .openweathermapCoordinates, .deviceLocation, .unitConverter, .wikipediaSearch, .webpage]
    
    let name: String
    
    static let calculator = Self(name: Calculator.name)
    static let openweathermapCity = Self(name: OpenWeatherMapCity.name)
    static let openweathermapCoordinates = Self(name: OpenWeatherMapCoordinates.name)
    static let deviceLocation = Self(name: DeviceLocation.name)
    static let unitConverter = Self(name: UnitConverter.name)
    static let wikipediaSearch = Self(name: Wikipedia.name)
    static let webpage = Self(name: Webpage.name)
    
    var customisable : Bool {
        switch self {
        case .openweathermapCity, .openweathermapCoordinates:
            return true
        default:
            return false
        }
    }
}

enum RegisterableFunctionType : String, CaseIterable, Identifiable {
    case owm
    
    var id : Self { self }
    
    var description : String {
        switch self {
        case .owm:
            return "OpenWeatherMap"
        }
    }
    
    @MainActor
    func register(data : [String : String] = [:]) {
        switch self {
        case .owm:
            guard let owm_api_key = data["owm_api_key"] else { return }
            [.openweathermapCity, .openweathermapCoordinates].forEach { (fun : AvailableFunction) in
                let function = Function(context: PreferencesManager.shared.persistentContainer.viewContext)
                function.type = fun.name
                function.id = UUID()
                function.customisable = true
                function.nickname = fun.name
                function.authfamily = "owm"
                function.owm_api = owm_api_key
            }
        }
    }
}


class FunctionsManager {
    static let shared : FunctionsManager = .init();

    lazy private var functionsEntities : [Function] = getFunctionsFromCoreData()
    
    func getFunctionsFromCoreData() -> [Function] {
        let fr = Function.fetchRequest()
        return (try? PreferencesManager.shared.persistentContainer.viewContext.fetch(fr)) ?? []
    }
    
    func updateAvailableFunctions() {
        functionsEntities = getFunctionsFromCoreData()
    }
    
    func functionsEntities(from: [UUID]) -> [Function] {
        functionsEntities.filter { from.contains($0.id ?? UUID()) }
    }
    
    func functionsEntities(from: NSSet?) -> [Function] {
        return from?.compactMap { $0 as? Function } ?? []
    }
    
    func function(from: Function) throws -> any OpenAIFunction {
        guard let type = from.type else { throw FunctionError.noAvailableFunctionWithName(name: "unknown") }
        switch type {
        case Calculator.name:
            return Calculator()
        case DeviceLocation.name:
            return DeviceLocation()
        case UnitConverter.name:
            return UnitConverter()
        case Wikipedia.name:
            return Wikipedia()
        case Webpage.name:
            return Webpage()
        case OpenWeatherMapCity.name:
            return OpenWeatherMapCity(openweathermap_api_key: from.owm_api ?? "")
        case OpenWeatherMapCoordinates.name:
            return OpenWeatherMapCoordinates(openweathermap_api_key: from.owm_api ?? "")
        default:
            throw FunctionError.noAvailableFunctionWithName(name: type)
        }
    }
}

enum FunctionError : Error {
    case noAvailableFunctionWithName(name : String)
    case executionFailed(message: String)
    case malformedInput
}
