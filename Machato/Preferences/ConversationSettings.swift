//
//  ConversationSettings.swift
//  Machato
//
//  Created by Théophile Cailliau on 29/03/2023.
//

import Foundation

class ConversationSettings: ObservableObject, Equatable {
    static func == (lhs: ConversationSettings, rhs: ConversationSettings) -> Bool {
        return lhs.stream == rhs.stream &&
        lhs.model == rhs.model &&
        lhs.prompt == rhs.prompt &&
        lhs.typeset == rhs.typeset &&
        lhs.temperature == rhs.temperature
    }
    
    @Published var stream: Bool
    @Published var temperature: Float
    @Published var typeset: TypesetFunctionality
    @Published var prompt: String
    @Published var model: OpenAIChatModel
    @Published var overrideGlobal: Bool;
    
    
    
    init() {
        stream = PreferencesManager.shared.streamChat
        temperature = PreferencesManager.shared.defaultTemperature
        typeset = PreferencesManager.shared.defaultTypeset
        prompt = PreferencesManager.shared.defaultPrompt
        model = PreferencesManager.shared.defaultModel
        overrideGlobal = false;
    }
    
    func save(_ cs: ConversationSettingsEntity) {
        cs.temperature = temperature
        cs.stream = stream
        cs.model = model.rawValue
        cs.rendering = typeset.rawValue
        cs.override_global = overrideGlobal
    }
}

extension ConversationSettings {
    func copyInto(_ cs: ConversationSettings) {
        cs.stream = stream
        cs.model = model
        cs.prompt = prompt
        cs.typeset = typeset
        cs.temperature = temperature
        cs.overrideGlobal = overrideGlobal
    }
}
