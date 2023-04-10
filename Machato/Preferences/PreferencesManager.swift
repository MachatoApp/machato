//
//  StoredPreferencesManager.swift
//  Machato
//
//  Created by Théophile Cailliau on 29/03/2023.
//

import Foundation
import SwiftUI
import CoreData
import Sparkle

class PreferencesManager: ObservableObject {
    lazy public var updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    public struct StoredPreferenceKey {
        static let stream_chat = "stream_chat"
        static let default_temperature = "default_temperature"
        static let default_typeset = "default_typeset"
        static let default_model = "default_model"
        static let current_conversation = "current_uuid"
        static let default_prompt = "default_prompt"
        static let api_key = "api_key"
        static let license_key = "license_key"
        static let hide_conversation_summary = "hide_summary"
        static let defaults_initialized = "defaults_initialized"
    }
    public static var shared = PreferencesManager()
    public static func restoreDefaults() {
        shared.defaultModel = .gpt_35_turbo
        shared.defaultTemperature = 1.0
        shared.streamChat = true
        shared.defaultTypeset = .markdown
        shared.defaultPrompt = "You are ChatGPT, a large language model trained by OpenAI."
        shared.hide_conversation_summary = false
        shared.defaults_initialized = true
    }
    
    func willChange() {
        self.objectWillChange.send()
    }
    
    var hide_conversation_summary : Bool {
        get { return UserDefaults.standard.bool(forKey: StoredPreferenceKey.hide_conversation_summary) }
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.hide_conversation_summary); willChange() }
    }
    var defaults_initialized : Bool {
        get { return UserDefaults.standard.bool(forKey: StoredPreferenceKey.defaults_initialized) }
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.defaults_initialized); willChange() }
    }
    var api_key : String {
        get { return UserDefaults.standard.string(forKey: StoredPreferenceKey.api_key) ?? "" }
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.api_key); willChange() }
    }
    var license_key : String {
        get { return UserDefaults.standard.string(forKey: StoredPreferenceKey.license_key) ?? "" }
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.license_key); willChange() }
    }
    var streamChat: Bool {
        get { return UserDefaults.standard.bool(forKey: StoredPreferenceKey.stream_chat) }
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.stream_chat); willChange() }
    }
    var defaultTemperature : Float {
        get { return UserDefaults.standard.float(forKey: StoredPreferenceKey.default_temperature) }
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.default_temperature); willChange() }
    }
    var defaultTypeset : TypesetFunctionality {
        get { return TypesetFunctionality.fromString(UserDefaults.standard.string(forKey: StoredPreferenceKey.default_typeset)) }
        set(v) { UserDefaults.standard.set(v.rawValue, forKey: StoredPreferenceKey.default_typeset); willChange() }
    }
    var defaultModel : OpenAIChatModel {
        get { return OpenAIChatModel.fromString(UserDefaults.standard.string(forKey: StoredPreferenceKey.default_model)) }
        set(v) { UserDefaults.standard.set(v.rawValue, forKey: StoredPreferenceKey.default_model); willChange() }
    }
    var currentConversation : String {
        get { return UserDefaults.standard.string(forKey: StoredPreferenceKey.current_conversation) ?? ""}
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.current_conversation); willChange() }
    }
    var defaultPrompt : String {
        get { return UserDefaults.standard.string(forKey: StoredPreferenceKey.default_prompt) ?? "You are ChatGPT, a large language model trained by OpenAI." }
        set(v) {UserDefaults.standard.set(v, forKey: StoredPreferenceKey.default_prompt); willChange() }
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
