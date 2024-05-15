//
//  ModelSettingsView.swift
//  Machato
//
//  Created by Théophile Cailliau on 05/06/2023.
//

import Foundation
import SwiftUI

struct ModelSettings : View {
    @Binding var model : Model?
    
    var body : some View {
        if let model = model {
            switch ModelType.fromString(model.type ?? "") {
            case .azure:
                AzureModelSettings(model: $model)
            case .openai:
                OpenAIModelSettings(model: $model)
            case .anthropic:
                AnthropicModelSettings(model: $model)
            case .local:
                OllamaModelSettings(model: $model)
            }
        } else {
            Spacer()
            Text("Add and modify profiles here")
        }
    }
}



