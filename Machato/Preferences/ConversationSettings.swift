//
//  ConversationSettings.swift
//  Machato
//
//  Created by Théophile Cailliau on 29/03/2023.
//

import Foundation

struct ConversationSettings {
    var stream: Bool
    var temperature: Float
    var typeset: TypesetFunctionality
    var prompt: String
    var model: OpenAIChatModel
    
    init() {
        stream = PreferencesManager.shared.streamChat
        temperature = PreferencesManager.shared.defaultTemperature
        typeset = PreferencesManager.shared.defaultTypeset
        prompt = PreferencesManager.shared.defaultPrompt
        model = PreferencesManager.shared.defaultModel
    }
}

extension PreferencesManager {
    static func getConversationSettings(_ c: Conversation) -> ConversationSettings {
        guard let coreSettings = c.has_settings else { return ConversationSettings() }
        guard coreSettings.override_global else { return ConversationSettings() }
        var settings = ConversationSettings()
        settings.stream = coreSettings.stream
        settings.model = OpenAIChatModel.fromString(coreSettings.model ?? "")
        settings.prompt = coreSettings.prompt ?? ""
        settings.typeset = TypesetFunctionality.fromString(coreSettings.rendering ?? "")
        settings.temperature = coreSettings.temperature
        return settings
    }
}
