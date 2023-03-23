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
    
    static let gpt3 : ModelCost = .init(sent: 0.0015, received: 0.002)
    static let gpt3_16k : ModelCost = .init(sent: 0.003, received: 0.004)
    static let gpt4 : ModelCost = .init(sent: 0.03, received: 0.06)
    static let gpt4_32k : ModelCost = .init(sent: 0.06, received: 0.12)
    static let gpt4_turbo : ModelCost = .init(sent: 0.01, received: 0.03)
    static let gpt3_1103 : ModelCost = .init(sent: 0.001, received: 0.002)
    
    static let claude : ModelCost = .init(sent: 11.02 / 1_000, received: 32.68 / 1_000)
    static let claude_instant : ModelCost = .init(sent: 1.63 / 1_000, received: 5.51 / 1_000)
    
    static func getOpenAIModelCost(model: String) -> ModelCost {
        switch OpenAIChatModel.fromString(model) {
        case .gpt_35_turbo:
            return gpt3
        case .gpt_4:
            return gpt4
        case .gpt_4_32k:
            return gpt4_32k
        case .gpt_35_turbo_16k:
            return gpt3_16k
        case .gpt_4_turbo:
            return gpt4_turbo
        case .gpt_35_turbo_1103:
            return gpt3_1103
        }
    }
    
    static func getAnthropicModelCost(model : String) -> ModelCost {
        switch AnthropicModel.fromString(model) {
        case .claude_instant_v1, .claude_instant_v1_100k:
            return .claude_instant
        case .claude_v2:
            return .claude
        }
    }
    
    static func getCost(model: OpenAIChatModel) -> ModelCost {
        return getOpenAIModelCost(model: model.rawValue)
    }
}

