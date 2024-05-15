//
//  APICost.swift
//  Machato
//
//  Created by Théophile Cailliau on 14/04/2023.
//

import Foundation


struct ModelCost {
    var sent : Double = .zero;
    var received: Double = .zero;
    
    static let gpt3 : ModelCost = .init(sent: 0.0005, received: 0.0015)
    static let gpt4 : ModelCost = .init(sent: 0.03, received: 0.06)
    static let gpt4_32k : ModelCost = .init(sent: 0.06, received: 0.12)
    static let gpt4_turbo : ModelCost = .init(sent: 0.01, received: 0.03)
    static let gpt4_o : ModelCost = .init(sent: 0.005, received: 0.015)
    
    static func getOpenAIModelCost(model: String) -> ModelCost {
        switch OpenAIChatModel.fromString(model) {
        case .gpt_35_turbo:
            return gpt3
        case .gpt_4:
            return gpt4
        case .gpt_4_32k:
            return gpt4_32k
        case .gpt_4_turbo:
            return gpt4_turbo
        case .gpt_4_turbo_preview:
            return gpt4_turbo
        case .gpt_4_turbo_vision:
            return gpt4_turbo
        case .gpt_4o:
            return gpt4_o
        }
    }
    
    static func getAnthropicModelCost(model : String) -> ModelCost {
        switch AnthropicModel.fromString(model) {
        case .claude_instant_v1:
            return .init(sent: 0.8 / 1_000, received: 2.4 / 1_000)
        case .claude_v2, .claude_v2_1:
            return .init(sent: 8.0 / 1_000, received: 24.0 / 1_000)
        case .claude_haiku:
            return .init(sent: 0.25 / 1_000, received: 1.25 / 1_000)
        case .claude_sonnet:
            return .init(sent: 3.0 / 1_000, received: 15.0 / 1_000)
        case .claude_opus:
            return .init(sent: 15.0 / 1_000, received: 75.0 / 1_000)
        }
    }
    
    static func getCost(model: OpenAIChatModel) -> ModelCost {
        return getOpenAIModelCost(model: model.rawValue)
    }
}

