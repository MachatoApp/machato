//
//  SettingsView.swift
//  Machato
//
//  Created by Théophile Cailliau on 28/03/2023.
//

import SwiftUI

struct SettingsView: View {
    @State private var stream : Bool = PreferencesManager.shared.streamChat;
    @State private var typeset : TypesetFunctionality = PreferencesManager.shared.defaultTypeset;
    @State private var model : OpenAIChatModel = PreferencesManager.shared.defaultModel;
    @State private var defaultTemperatureInt : Int = Int(PreferencesManager.shared.defaultTemperature * 10);
    @State private var api_key : String = PreferencesManager.shared.api_key;
    private var convo: Conversation? = nil;
    @State private var convoOverride : Bool = false;
    @Environment(\.dismiss) var dismiss
    private var defaultTemperature : Float {
        return Float(defaultTemperatureInt) / 10.0
    }
    
    @ViewBuilder
    var commonSettings: some View {
        Toggle(isOn: $stream) {
            Text("Stream chat response")
        } .onChange(of: stream, perform: save)
        Picker(selection: $typeset, label: Text("Text rendering capabilities")) {
            ForEach(TypesetFunctionality.allCases) { fun in
                Text(fun.description).tag(fun)
            }
        }
        .pickerStyle(RadioGroupPickerStyle())
        .onChange(of: typeset, perform: save)
        Picker(selection: $model, label: Text(convo == nil ? "Default model" : "Model")) {
            ForEach(OpenAIChatModel.allCases) { fun in
                Text(fun.rawValue).tag(fun)
            }
        } .onChange(of: model, perform: save)
        HStack {
            Text(convo == nil ? "Default temperature" : "Temperature")
            Spacer()
            Stepper {
                Text(defaultTemperature.description)
            } onIncrement: {
                defaultTemperatureInt += 1
                defaultTemperatureInt = min(20, defaultTemperatureInt)
            } onDecrement: {
                defaultTemperatureInt -= 1
                defaultTemperatureInt = max(defaultTemperatureInt, 0)
            } .onChange(of: defaultTemperatureInt, perform: save)
        }
        if convo == nil {
            HStack {
                Text("API Key")
                TextField("API key", text: $api_key)
                    .onChange(of: api_key, perform: save)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if let c = convo {
                Text("Settings for conversation: \(c.title ?? "Untitled")").lineLimit(2)
                Toggle(isOn: $convoOverride) {
                    Text("Conversation settings override global settings")
                } .onChange(of: convoOverride, perform: save)
                if convoOverride {
                    commonSettings
                }
            } else {
                commonSettings
            }
            HStack {
                Spacer()
                Button {
                    save()
                    dismiss()
                } label: {
                    Text("Done!")
                } .buttonStyle(.borderedProminent)
            }
        }
        .padding(15)
        .frame(minWidth: 350, maxWidth: 350)
        .onAppear() {
            getPreferences()
        }
    }
    
    func save<V>(_ _: V? = nil) {
        save()
    }
    
    func save() {
        if let c = convo {
            guard let cs = c.has_settings else {
                print("Conversation had no settings entity while saving conversation-specific settings")
                return
            }
            cs.temperature = defaultTemperature
            cs.stream = stream
            cs.model = model.rawValue
            cs.rendering = typeset.rawValue
            cs.override_global = convoOverride
        } else {
            PreferencesManager.shared.api_key = api_key
            PreferencesManager.shared.defaultModel = model
            PreferencesManager.shared.defaultTemperature = defaultTemperature
            PreferencesManager.shared.defaultTypeset = typeset
            PreferencesManager.shared.streamChat = stream
        }
    }
    
    func getPreferences() {
        defaultTemperatureInt = Int(PreferencesManager.shared.defaultTemperature * 10)
        model = PreferencesManager.shared.defaultModel
        typeset = PreferencesManager.shared.defaultTypeset
        stream = PreferencesManager.shared.streamChat
        api_key = PreferencesManager.shared.api_key
        guard let cs = convo?.has_settings else { return }
        guard cs.override_global else { return } // keep default values if we previously were not overridign
        model = OpenAIChatModel.fromString(cs.model)
        typeset = TypesetFunctionality.fromString(cs.rendering)
        stream = cs.stream
        defaultTemperatureInt = Int(cs.temperature * 10)
        convoOverride = cs.override_global
    }
    
    init() {
        
    }
    
    init(forConvo c: Conversation) {
        self.convo = c;
    }
}
