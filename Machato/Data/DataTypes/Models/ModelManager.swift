//
//  ModelManager.swift
//  Machato
//
//  Created by Théophile Cailliau on 05/06/2023.
//

import Foundation

enum ModelDescriptor : Identifiable {
    
    case openai(name: String, model : Model, associatedModel: OpenAIChatModel, pricing: ModelCost)
    case azure(name: String, model: Model, associatedModel: OpenAIChatModel, pricing: ModelCost)
    case anthropic(name: String, model: Model, associatedModel : AnthropicModel, pricing: ModelCost)
    case local(name: String, modelName: String, endpoint: String)
    case none
    
    var supportsFunctions : Bool {
        switch self {
        case let .openai(_,_, associatedModel,_), let .azure(_,_, associatedModel, _):
            return associatedModel.supportsFunctionCalling
        default:
            return false
        }
    }
    
    var api_key : String {
        switch self {
        case .openai(_, let m, _, _):
            return m.openai_api_key ?? ""
        case .azure(_, let m, _, _):
            return m.azure_api_key ?? ""
        case .anthropic(_, let m, _, _):
            return m.anthropic_api_key ?? ""
        case .none, .local(_, _, _):
            return ""
        }

    }
    
    var type : ModelType? {
        switch self {
        case .openai(_,_,_,_):
            return .openai
        case .azure(_,_,_,_):
            return .azure
        case .anthropic(_,_,_, _):
            return .anthropic
        case .local(_,_, _):
            return .local
        case .none:
            return nil
        }
    }
    
    var id: String {
        switch self {
        case .openai(let name, let m, _, _), .anthropic(let name, let m, _, _), .azure(let name, let m, _, _):
            return name + (m.date_added?.timeIntervalSince1970.description ?? "")
        case .local(let name, let modelName, let endPoint):
            return name + endPoint + modelName
        case .none:
            return "none"
        }

    }
    
    var name : String {
        switch self {
        case .openai(let name, _, _, _),
                .anthropic(let name, _, _, _),
                .azure(let name, _, _, _),
                .local(let name, _, _):
            return name
        case .none:
            return "none"
        }
    }
    
    var contextLength : Int32 {
        switch self {
        case .openai(_, _, let a, _), .azure(_, _, let a, _):
            return a.contextLength
        case .anthropic(_, _, let a, _):
            return a.contextLength
        case .none, .local:
            return .zero
        }
    }
}

class ModelManager : ObservableObject {
    public static let shared = ModelManager()
    
    public var availableModels : [ModelDescriptor] = []
    
    func modelDescriptor(for str: String?) -> ModelDescriptor {
        availableModels.filter { md in
            switch md {
            case .openai(let name, _, _, _):
                return name == str
            case .azure(let name, _, _, _):
                return name == str
            case .anthropic(let name, _, _, _):
                return name == str
            case .local(let name, _, _):
                return name == str
            case .none:
                return false
            }
        }.first ?? .none
    }
    
    func updateAvailableModels() {
        availableModels = []
        let fr = Model.fetchRequest()
        fr.sortDescriptors = [NSSortDescriptor(keyPath: \Model.date_added, ascending: true)]
        guard let results = try? PreferencesManager.shared.persistentContainer.viewContext.fetch(fr) else {
            print("Could not fetch models")
            return
        }
        results.forEach { model in
            switch ModelType.fromString(model.type) {
            case .openai:
                guard let prefix = model.openai_prefix, let enabled = model.openai_enabled_models?.split(separator: ";") else { break }
                enabled.filter { !$0.isEmpty }.map { String($0) }.forEach { rawName in
                    let modelName = "\(prefix)\(prefix.hasSuffix("-") || prefix.isEmpty ? "" : "-")\(rawName)"
                    availableModels.append(
                        .openai(
                            name: modelName,
                            model: model,
                            associatedModel: .fromString(rawName),
                            pricing: ModelCost.getOpenAIModelCost(model: rawName)
                        )
                    )
                }
            case .anthropic:
                guard let prefix = model.anthropic_prefix, let enabled = model.anthropic_enabled_models?.split(separator: ";") else { break }
                enabled.filter { !$0.isEmpty }.map { String($0) }.forEach { rawName in
                    let modelName = "\(prefix)\(prefix.hasSuffix("-") || prefix.isEmpty ? "" : "-")\(rawName)"
                    availableModels.append(
                        .anthropic(
                            name: modelName,
                            model: model,
                            associatedModel: .fromString(rawName),
                            pricing: ModelCost.getAnthropicModelCost(model: rawName)
                        )
                    )
                }
            case .azure:
                guard let modelName = model.azure_model_name else { break }
                availableModels.append(
                    .azure(name: modelName,
                           model: model,
                           associatedModel: OpenAIChatModel.fromString(model.azure_associated_chatgpt_model),
                           pricing: ModelCost.getOpenAIModelCost(model: model.azure_associated_chatgpt_model ?? "")))
            case .local:
                guard let enabled = model.localai_enabled_models?.split(separator: ";"), let endpoint = model.localai_endpoint, let prefix = model.localai_prefix else { break }
                enabled.filter { !$0.isEmpty }.map { String($0) }.forEach { rawName in
                    let modelName = "\(prefix)\(prefix.hasSuffix("-") || prefix.isEmpty ? "" : "-")\(rawName)"
                    availableModels.append(
                        .local(
                            name: modelName,
                            modelName: rawName,
                            endpoint: endpoint
                        )
                    )
                }
            }
        }
        if availableModels.isEmpty {
            availableModels.append(.none)
        }
        self.objectWillChange.send()
    }
}
