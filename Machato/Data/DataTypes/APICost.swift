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
    static let gpt4_turbo : ModelCost = .init(sent: 0.01, received: 0.03)
    static let gpt4_o : ModelCost = .init(sent: 0.005, received: 0.015)
    static let gpt4_o_20240806 : ModelCost = .init(sent: 0.0025, received: 0.010)
    static let gpt_4o_mini : ModelCost = .init(sent: 0.00015, received: 0.0006)

    static func getOpenAIModelCost(model: String) -> ModelCost {
        switch OpenAIChatModel.fromString(model) {
        case .gpt_35_turbo:
            return gpt3
        case .gpt_4:
            return gpt4
        case .gpt_4_turbo:
            return gpt4_turbo
        case .gpt_4o:
            return gpt4_o
        case .gpt_4o_20240806:
            return gpt4_o_20240806
        case .gpt_4o_mini:
            return gpt_4o_mini
        }
    }
    
    static func getAnthropicModelCost(model : String) -> ModelCost {
        switch AnthropicModel.fromString(model) {
        case .claude_3_haiku:
            return .init(sent: 0.25 / 1_000, received: 1.25 / 1_000)
        case .claude_3_sonnet, .claude_35_sonnet:
            return .init(sent: 3.0 / 1_000, received: 15.0 / 1_000)
        case .claude_3_opus:
            return .init(sent: 15.0 / 1_000, received: 75.0 / 1_000)
        }
    }
    
    static func getCost(model: OpenAIChatModel) -> ModelCost {
        return getOpenAIModelCost(model: model.rawValue)
    }
}

