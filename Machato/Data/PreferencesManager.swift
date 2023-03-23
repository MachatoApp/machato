//
//  StoredPreferencesManager.swift
//  Machato
//
//  Created by Théophile Cailliau on 29/03/2023.
//

import Foundation
import SwiftUI
import CoreData
#if !MAS
import Sparkle
#endif
import Combine

class PreferencesManager: ObservableObject {
    static public var conversationSettings : [Conversation?: ConversationSettings] = [:];

    static func getConversationSettings(_ c: Conversation?) -> ConversationSettings {
        if let cs = conversationSettings[c] {
            return cs
        }
        conversationSettings[c] = ConversationSettings(csEntity: c?.has_settings)
        return conversationSettings[c]!
    }
   
    #if !MAS
    lazy public var updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    #endif
    
    public struct StoredPreferenceKey {
        static let streamChat = "stream_chat"
        static let defaultTemperature = "default_temperature"
        static let defaultTypeset = "default_typeset"
        static let defaultModel = "default_model"
        static let currentConversation = "current_uuid"
        static let defaultPrompt = "default_prompt"
        static let apiKey = "api_key" // no longer used except to transition users to the new profiles system
        static let licenseKey = "license_key"
        static let hideConversationSummary = "hide_summary"
        static let defaultsInitialized = "defaults_initialized"
        static let fontSize = "font_size"
        static let codeLightTheme = "code_light_theme"
        static let codeDarkTheme = "code_dark_theme"
        static let colorScheme = "color_scheme"
        static let hideTokenCount = "hide_token_count"
        static let defaultTokenCountTimespan = "default_token_count_timespan"
        static let hideLineNos = "hide_line_numbers"
        static let sendWithShiftEnter = "send_with_shift_enter"
        static let allowMessageExclusion = "allow_message_exclusion"
        static let hasLaunched = "has_launched"
        static let narrowMessages = "narrow_messages"
        static let maxWidth = "max_width"
        static let iCloudSync = "icloud_sync"
        static let messageTimestamp = "message_timestamp"
        static let defaultTopP = "default_top_p"
        static let defaultPresencePenalty = "default_presence_penalty"
        static let defaultFrequencyPenalty = "default_freq_penalty"
        static let maxTokensManual = "manual_max_tokens"
        static let maxTokens = "max_tokens"
        static let autoScroll = "auto_scroll"
        static let useServiceIcons = "use_service_icons"
        static let defaultFunctions = "default_functions"
    }
    public static var shared = PreferencesManager()
    public static func restoreDefaults() {
        shared.defaultModel = "gpt-3.5-turbo"
        shared.defaultTemperature = 1
        shared.defaultTopP = 1
        shared.defaultPresencePenalty = 0
        shared.defaultPresencePenalty = 0
        shared.fontSize = 13
        shared.streamChat = true
        shared.defaultTypeset = .markdown
        shared.defaultPrompt = "You are ChatGPT, a large language model trained by OpenAI."
        shared.hideConversationSummary = false
        shared.defaultsInitialized = true
        shared.lightTheme = "xcode"
        shared.darkTheme = "obsidian"
        shared.colorScheme = .system
        shared.hideTokenCount = false
        shared.defaultTokenCountTimespan = .day
        shared.maxWidth = 800
        shared.iCloudSync = false
        shared.messageTimestamp = false
        shared.maxTokensManual = false
        shared.maxTokens = .max
        shared.iCloudSync = false
        shared.narrowMessages = true
        shared.defaultFunctions = []
    }

    func willChange() {
        updateUItag.toggle()
        self.objectWillChange.send()
    }
    
    var defaultFunctions : [UUID] {
        get { return UserDefaults.standard.string(forKey: StoredPreferenceKey.defaultFunctions)?.split(separator: ";").compactMap({ uuidString in
            UUID(uuidString: String(uuidString))
        }) ?? [] }
        set(v) { UserDefaults.standard.set(v.reduce("", { partialResult, uuid in
            partialResult + uuid.uuidString + ";"
        }), forKey: StoredPreferenceKey.defaultFunctions); willChange() }
    }
    
    var maxTokensManual : Bool {
        get { return UserDefaults.standard.bool(forKey: StoredPreferenceKey.maxTokensManual) }
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.maxTokensManual); willChange() }
    }
    
    var maxTokens : Int32 {
        get { return UserDefaults.standard.object(forKey: StoredPreferenceKey.maxTokens) as? Int32 ?? .max }
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.maxTokens); willChange() }
    }
    
    var defaultTopP : Float {
        get { return UserDefaults.standard.float(forKey: StoredPreferenceKey.defaultTopP) }
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.defaultTopP); willChange() }
    }
    var defaultPresencePenalty : Float {
        get { return UserDefaults.standard.float(forKey: StoredPreferenceKey.defaultPresencePenalty) }
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.defaultPresencePenalty); willChange() }
    }
    var defaultFrequencyPenalty : Float {
        get { return UserDefaults.standard.float(forKey: StoredPreferenceKey.defaultFrequencyPenalty) }
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.defaultFrequencyPenalty); willChange() }
    }
    
    var fontSize : CGFloat {
        get { return CGFloat(UserDefaults.standard.integer(forKey: StoredPreferenceKey.fontSize)) }
        set(v) { UserDefaults.standard.set(Int(v), forKey: StoredPreferenceKey.fontSize); willChange() }
    }
    
    var maxWidth : CGFloat {
        get { return CGFloat(UserDefaults.standard.integer(forKey: StoredPreferenceKey.maxWidth)) }
        set(v) { UserDefaults.standard.set(Int(v), forKey: StoredPreferenceKey.maxWidth); willChange() }
    }
    var iCloudSync : Bool {
        get { return UserDefaults.standard.bool(forKey: StoredPreferenceKey.iCloudSync) }
        set(v) {
            UserDefaults.standard.set(v, forKey: StoredPreferenceKey.iCloudSync);
            willChange()
            try? persistentContainer.viewContext.save()
            try? backgroundContext.save()
            self.persistentContainer.persistentStoreDescriptions.first?.cloudKitContainerOptions = v ? NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.machato.Machato") : nil
        }
    }
    var messageTimestamp : Bool {
        get { return UserDefaults.standard.bool(forKey: StoredPreferenceKey.messageTimestamp) }
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.messageTimestamp); willChange() }
    }
    var hideConversationSummary : Bool {
        get { return UserDefaults.standard.bool(forKey: StoredPreferenceKey.hideConversationSummary) }
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.hideConversationSummary); willChange() }
    }
    var defaultsInitialized : Bool {
        get { return UserDefaults.standard.bool(forKey: StoredPreferenceKey.defaultsInitialized) }
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.defaultsInitialized); willChange() }
    }
    var api_key : String {
        get { return UserDefaults.standard.string(forKey: StoredPreferenceKey.apiKey) ?? "" }
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.apiKey); willChange() }
    }
    var license_key : String {
        get { return UserDefaults.standard.string(forKey: StoredPreferenceKey.licenseKey) ?? "" }
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.licenseKey); willChange() }
    }
    var streamChat: Bool {
        get { return UserDefaults.standard.bool(forKey: StoredPreferenceKey.streamChat) }
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.streamChat); willChange() }
    }
    var narrowMessages: Bool {
        get { return UserDefaults.standard.bool(forKey: StoredPreferenceKey.narrowMessages) }
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.narrowMessages); willChange() }
    }
    var defaultTemperature : Float {
        get { return UserDefaults.standard.float(forKey: StoredPreferenceKey.defaultTemperature) }
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.defaultTemperature); willChange() }
    }
    var defaultTypeset : TypesetFunctionality {
        get { return TypesetFunctionality.fromString(UserDefaults.standard.string(forKey: StoredPreferenceKey.defaultTypeset)) }
        set(v) { UserDefaults.standard.set(v.rawValue, forKey: StoredPreferenceKey.defaultTypeset); willChange() }
    }
    var defaultModel : String {
        get { return UserDefaults.standard.string(forKey: StoredPreferenceKey.defaultModel) ?? "gpt-3.5-turbo" }
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.defaultModel); willChange() }
    }
    var currentConversation : String {
        get { return UserDefaults.standard.string(forKey: StoredPreferenceKey.currentConversation) ?? ""}
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.currentConversation); willChange() }
    }
    var defaultPrompt : String {
        get { return UserDefaults.standard.string(forKey: StoredPreferenceKey.defaultPrompt) ?? "You are ChatGPT, a large language model trained by OpenAI." }
        set(v) {UserDefaults.standard.set(v, forKey: StoredPreferenceKey.defaultPrompt); willChange() }
    }
    var lightTheme : String {
        get { return UserDefaults.standard.string(forKey: StoredPreferenceKey.codeLightTheme) ?? "xcode" }
        set(v) {UserDefaults.standard.set(v, forKey: StoredPreferenceKey.codeLightTheme); willChange()}
    }
    var darkTheme : String {
        get { return UserDefaults.standard.string(forKey: StoredPreferenceKey.codeDarkTheme) ?? "obsidian" }
        set(v) {UserDefaults.standard.set(v, forKey: StoredPreferenceKey.codeDarkTheme); willChange() }
    }
    var colorScheme : AppColorScheme {
        get { return AppColorScheme.fromString(UserDefaults.standard.string(forKey: StoredPreferenceKey.colorScheme)) }
        set(v) {UserDefaults.standard.set(v.rawValue, forKey: StoredPreferenceKey.colorScheme); willChange() }
    }
    var hideTokenCount : Bool {
        get { return UserDefaults.standard.bool(forKey: StoredPreferenceKey.hideTokenCount) }
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.hideTokenCount); willChange() }
    }
    var hideLineNos : Bool {
        get { return UserDefaults.standard.bool(forKey: StoredPreferenceKey.hideLineNos) }
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.hideLineNos); willChange() }
    }
    var allowMessageExclusion : Bool {
        get { return UserDefaults.standard.bool(forKey: StoredPreferenceKey.allowMessageExclusion) }
        set(v) { UserDefaults.standard.set(v, forKey: StoredPreferenceKey.allowMessageExclusion); willChange() }
    }
    var defaultTokenCountTimespan : TokenCountTimespan {
        get { return TokenCountTimespan.fromString(UserDefaults.standard.string(forKey: StoredPreferenceKey.defaultTokenCountTimespan)) }
        set(v) {UserDefaults.standard.set(v.rawValue, forKey: StoredPreferenceKey.defaultTokenCountTimespan); willChange() }
    }

    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "ChatModel")
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("###\(#function): Failed to retrieve a persistent store description.")
        }
        if(UserDefaults.standard.bool(forKey: StoredPreferenceKey.iCloudSync)){
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.machato.Machato")
        } else {
            description.cloudKitContainerOptions = nil
        }
        // TODO: remove this line when CloudKit crash is fixed
        //description.cloudKitContainerOptions = nil
        
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
#if DEBUG
        do {
            // Use the container to initialize the development schema.
            try container.initializeCloudKitSchema(options: [])
        } catch {
            // Handle any errors.
        }
#endif
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        //container.viewContext.retainsRegisteredObjects = true
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()
    
    lazy var backgroundContext : NSManagedObjectContext = persistentContainer.newBackgroundContext()
    @Published var updateUItag: Bool = false;
}
