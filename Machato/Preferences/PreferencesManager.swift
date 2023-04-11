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
    static public var conversationSettings : [Conversation: ConversationSettings] = [:];

    static func getConversationSettings(_ c: Conversation) -> ConversationSettings {
        if let cs = conversationSettings[c] {
            return cs
        }
        conversationSettings[c] = ConversationSettings()
        updateConversationSettings(c)
        return conversationSettings[c]!
    }

    static func updateConversationSettings(_ c: Conversation) {
        guard let coreSettings = c.has_settings else { return }
        
        // Grab the instance of ConversationSettings related to conversation by uuid
        let settings = self.conversationSettings[c] ?? ConversationSettings()
        self.conversationSettings[c] = settings
        if coreSettings.override_global {
            settings.overrideGlobal = true
            settings.stream = coreSettings.stream
            settings.model = OpenAIChatModel.fromString(coreSettings.model ?? "")
            settings.prompt = coreSettings.prompt ?? ""
            settings.typeset = TypesetFunctionality.fromString(coreSettings.rendering ?? "")
            settings.temperature = coreSettings.temperature
        } else {
            settings.overrideGlobal = false
            settings.stream = PreferencesManager.shared.streamChat
            settings.temperature = PreferencesManager.shared.defaultTemperature
            settings.typeset = PreferencesManager.shared.defaultTypeset
            settings.prompt = PreferencesManager.shared.defaultPrompt
            settings.model = PreferencesManager.shared.defaultModel
        }
    }
    
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
        static let font_size = "font_size"
        static let code_light_theme = "code_light_theme"
        static let code_dark_theme = "code_dark_theme"
    }
    public static var shared = PreferencesManager()
    public static func restoreDefaults() {
        shared.defaultModel = .gpt_35_turbo
        shared.defaultTemperature = 0.7
        shared.fontSize = 13
        shared.streamChat = true
        shared.defaultTypeset = .markdown
        shared.defaultPrompt = "You are ChatGPT, a large language model trained by OpenAI."
        shared.hide_conversation_summary = false
        shared.defaults_initialized = true
        shared.lightTheme = "xcode"
        shared.darkTheme = "obsidian"
    }
    
    func willChange(_ updateConversationSettings : Bool = false) {
        if updateConversationSettings {
            PreferencesManager.conversationSettings.forEach { (c, s) in
                PreferencesManager.updateConversationSettings(c)
            }
        }
        updateUItag.toggle()
        self.objectWillChange.send()
    }
    
    var fontSize : CGFloat {
        get { return CGFloat(UserDefaults.standard.integer(forKey: StoredPreferenceKey.font_size)) }
        set(v) { UserDefaults.standard.set(Int(v), forKey: StoredPreferenceKey.font_size); willChange(true) }
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
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.stream_chat); willChange(true) }
    }
    var defaultTemperature : Float {
        get { return UserDefaults.standard.float(forKey: StoredPreferenceKey.default_temperature) }
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.default_temperature); willChange(true) }
    }
    var defaultTypeset : TypesetFunctionality {
        get { return TypesetFunctionality.fromString(UserDefaults.standard.string(forKey: StoredPreferenceKey.default_typeset)) }
        set(v) { UserDefaults.standard.set(v.rawValue, forKey: StoredPreferenceKey.default_typeset); willChange(true) }
    }
    var defaultModel : OpenAIChatModel {
        get { return OpenAIChatModel.fromString(UserDefaults.standard.string(forKey: StoredPreferenceKey.default_model)) }
        set(v) { UserDefaults.standard.set(v.rawValue, forKey: StoredPreferenceKey.default_model); willChange(true) }
    }
    var currentConversation : String {
        get { return UserDefaults.standard.string(forKey: StoredPreferenceKey.current_conversation) ?? ""}
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.current_conversation); willChange() }
    }
    var defaultPrompt : String {
        get { return UserDefaults.standard.string(forKey: StoredPreferenceKey.default_prompt) ?? "You are ChatGPT, a large language model trained by OpenAI." }
        set(v) {UserDefaults.standard.set(v, forKey: StoredPreferenceKey.default_prompt); willChange(true) }
    }
    var lightTheme : String {
        get { return UserDefaults.standard.string(forKey: StoredPreferenceKey.code_light_theme) ?? "xcode" }
        set(v) {UserDefaults.standard.set(v, forKey: StoredPreferenceKey.code_light_theme); willChange()}
    }
    var darkTheme : String {
        get { return UserDefaults.standard.string(forKey: StoredPreferenceKey.code_dark_theme) ?? "obsidian" }
        set(v) {UserDefaults.standard.set(v, forKey: StoredPreferenceKey.code_dark_theme); willChange() }
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
    @Published var updateUItag: Bool = false;
}
