//
//  ConversationSettings.swift
//  Machato
//
//  Created by Théophile Cailliau on 29/03/2023.
//

import Foundation
import Combine

class ConversationSettings: ObservableObject, Equatable {
    static func == (lhs: ConversationSettings, rhs: ConversationSettings) -> Bool {
        return lhs.stream == rhs.stream &&
        lhs.model.name == rhs.model.name &&
        lhs.prompt == rhs.prompt &&
        lhs.typeset == rhs.typeset &&
        lhs.temperature == rhs.temperature &&
        lhs.topP == rhs.topP &&
        lhs.frequencyPenalty == rhs.frequencyPenalty &&
        lhs.presencePenalty == rhs.presencePenalty &&
        lhs.enabledFunctions.count == rhs.enabledFunctions.count &&
        zip(lhs.enabledFunctions, rhs.enabledFunctions).allSatisfy({ (a, b) in a.id == b.id})
    }
    
    private var csEntity : ConversationSettingsEntity?;
        
    @Published var stream: Bool
    @Published var temperature: Float
    @Published var typeset: TypesetFunctionality;
    @Published var prompt: String
    @Published var model: ModelDescriptor;
    @Published var maxTokens : Int32;
    @Published var manageMax : Bool;
    @Published var topP : Float
    @Published var presencePenalty : Float
    @Published var frequencyPenalty : Float
    @Published var enabledFunctions : [Function]
    
    private var saveSink : Cancellable? = nil;
    
    @MainActor
    func updateModel() {
        self.model = ModelManager.shared.modelDescriptor(for: self.model.name)
    }
    
    init(csEntity: ConversationSettingsEntity?) {
        self.csEntity = csEntity
        if let cse = csEntity {
            stream = cse.stream
            temperature = cse.temperature
            typeset = TypesetFunctionality.fromString(cse.rendering)
            prompt = cse.prompt ?? PreferencesManager.shared.defaultPrompt
            model = ModelManager.shared.modelDescriptor(for: cse.model)
            topP = cse.top_p
            presencePenalty = cse.presence_penalty
            frequencyPenalty = cse.frequency_penalty
            manageMax = cse.manage_max
            maxTokens = cse.max_tokens
            enabledFunctions = FunctionsManager.shared.functionsEntities(from: cse.active_functions)
        } else {
            stream = PreferencesManager.shared.streamChat
            temperature = PreferencesManager.shared.defaultTemperature
            typeset = PreferencesManager.shared.defaultTypeset
            prompt = PreferencesManager.shared.defaultPrompt
            model = ModelManager.shared.modelDescriptor(for: PreferencesManager.shared.defaultModel)
            topP = PreferencesManager.shared.defaultTopP
            presencePenalty = PreferencesManager.shared.defaultPresencePenalty
            frequencyPenalty = PreferencesManager.shared.defaultFrequencyPenalty
            manageMax = !PreferencesManager.shared.maxTokensManual
            maxTokens = PreferencesManager.shared.maxTokens
            enabledFunctions = FunctionsManager.shared.functionsEntities(from: PreferencesManager.shared.defaultFunctions)
        }
        saveSink = self.objectWillChange
            .receive(on: RunLoop.main)
            .sink { _ in
                self.save()
            }
    }
    
    func save() {
        guard let cse = csEntity else { return }
        save(cse)
    }
    
    private func save(_ cs: ConversationSettingsEntity) {
        cs.temperature = temperature
        cs.stream = stream
        cs.model = model.name
        cs.prompt = prompt
        cs.rendering = typeset.rawValue
        cs.top_p = topP
        cs.frequency_penalty = frequencyPenalty
        cs.presence_penalty = presencePenalty
        cs.manage_max = manageMax
        cs.max_tokens = maxTokens
        cs.active_functions = NSSet(array: enabledFunctions)
        do {
            try PreferencesManager.shared.persistentContainer.viewContext.save()
        } catch {
            print(error)
        }
    }
    
    func getFunction(name: String) throws -> any OpenAIFunction {
        if let f = enabledFunctions.first(where: { $0.type == name }) {
            return try FunctionsManager.shared.function(from: f)
        }
        throw FunctionError.noAvailableFunctionWithName(name: name)
    }
}
