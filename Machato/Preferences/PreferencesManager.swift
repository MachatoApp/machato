//
//  StoredPreferencesManager.swift
//  Machato
//
//  Created by Théophile Cailliau on 29/03/2023.
//

import Foundation
import SwiftUI

struct PreferencesManager {
    struct StoredPreferenceKey {
        static let stream_chat = "stream_chat"
        static let default_temperature = "default_temperature"
        static let default_typeset = "default_typeset"
        static let default_model = "default_model"
        static let current_conversation = "current_uuid"
        static let default_prompt = "default_prompt"
        static let api_key = "api_key"
        static let license_key = "license_key"
    }
    static var shared = PreferencesManager()
    
    var api_key : String {
        get { return UserDefaults.standard.string(forKey: StoredPreferenceKey.api_key) ?? "" }
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.api_key) }
    }
    var license_key : String {
        get { return UserDefaults.standard.string(forKey: StoredPreferenceKey.license_key) ?? "" }
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.license_key) }
    }
    var streamChat: Bool {
        get { return UserDefaults.standard.bool(forKey: StoredPreferenceKey.stream_chat) }
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.stream_chat) }
    }
    var defaultTemperature : Float {
        get { return UserDefaults.standard.float(forKey: StoredPreferenceKey.default_temperature) }
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.default_temperature) }
    }
    var defaultTypeset : TypesetFunctionality {
        get { return TypesetFunctionality.fromString(UserDefaults.standard.string(forKey: StoredPreferenceKey.default_typeset)) }
        set(v) { UserDefaults.standard.set(v.rawValue, forKey: StoredPreferenceKey.default_typeset) }
    }
    var defaultModel : OpenAIChatModel {
        get { return OpenAIChatModel.fromString(UserDefaults.standard.string(forKey: StoredPreferenceKey.default_model)) }
        set(v) { UserDefaults.standard.set(v.rawValue, forKey: StoredPreferenceKey.default_model) }
    }
    var currentConversation : String {
        get { return UserDefaults.standard.string(forKey: StoredPreferenceKey.current_conversation) ?? ""}
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.current_conversation) }
    }
    var defaultPrompt : String {
        get { return UserDefaults.standard.string(forKey: StoredPreferenceKey.default_prompt) ?? "You are ChatGPT, a large language model trained by OpenAI." }
        set(v) {UserDefaults.standard.set(v, forKey: StoredPreferenceKey.default_prompt) }
    }
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ChatModel")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        return container
    }()
}
