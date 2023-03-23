//
//  SettingsView.swift
//  Machato
//
//  Created by Théophile Cailliau on 28/03/2023.
//

import SwiftUI
//import Sparkle

struct SettingsView: View {
    @State private var stream : Bool = PreferencesManager.shared.streamChat;
    @State private var model : String = PreferencesManager.shared.defaultModel;
    @State private var defaultTemperatureInt : Int = Int(PreferencesManager.shared.defaultTemperature * 10);
    @State private var manageMax : Bool = !PreferencesManager.shared.maxTokensManual;
    @State private var maxTokensLog : Double = log2(Double(PreferencesManager.shared.maxTokens));
    var maxTokens : Int32 {
        Int32(pow(2,maxTokensLog))
    }
    private var defaultTemperature : Float {
        return Float(defaultTemperatureInt) / 10.0
    }
    
    @State private var topPInt = Int(PreferencesManager.shared.defaultTopP == 0
                                     ? 10
                                     : PreferencesManager.shared.defaultTopP < 0.1
                                     ? PreferencesManager.shared.defaultTopP * 100 - 9
                                     : PreferencesManager.shared.defaultTopP * 10)
    private var topP : Float {
        return topPInt > 0 ? Float(topPInt) / 10.0 : Float(9+topPInt) / 100.0
    }
    
    @State private var presencePenaltyInt = Int(PreferencesManager.shared.defaultPresencePenalty*10);
    private var presencePenalty : Float {
        return Float(presencePenaltyInt) / 10.0
    }
    
    @State private var frequencyPenaltyInt = Int(PreferencesManager.shared.defaultFrequencyPenalty*10);
    private var frequencyPenalty : Float {
        return Float(frequencyPenaltyInt) / 10.0
    }
    
    @Environment(\.openWindow) var openWindow;
    
    @ViewBuilder
    var commonSettings: some View {
        Toggle(isOn: $stream) {
            VStack(alignment: .leading) {
                Text("Stream chat response")
                Text("When enabled, ChatGPT's response is streamed token-per-token and displayed in real time.")
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(0.5)
            }
        } .onChange(of: stream, perform: save).toggleStyle(.checkboxRight)
        Toggle(isOn: $manageMax) {
            VStack(alignment: .leading) {
                Text("Automatically manage max_tokens")
                Text("When enabled, Machato automatically calculates the max_tokens value to avoid exceeding the available context length.")
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(0.5)
            }
        } .onChange(of: manageMax, perform: save).toggleStyle(.checkboxRight)
        if !manageMax {
            HStack {
                Text("max_tokens:   ")
                Text("\(maxTokens)").font(.body.monospaced()).frame(minWidth: 70)
                Slider(value: $maxTokensLog, in: 0...17).onChange(of: maxTokensLog, perform: save)
            }
        }
        HStack (alignment: .top) {
            VStack(alignment: .leading) {
                Text("Default model")
                Text("Choose the model that will be used for conversations. You can add third-party models in the \"Keys & Sync\" tab.")
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(0.5)
            }.fixedSize(horizontal: false, vertical: true)
            Spacer()
            Picker(selection: $model, label: EmptyView()) {
                ForEach(ModelManager.shared.availableModels) { model in
                    Text(model.name).tag(model.name)
                }
            }.labelsHidden().frame(width: 150)
                .onChange(of: model, perform: save)
        }
        HStack (alignment: .top) {
            VStack (alignment: .leading) {
                Text("Default temperature")
                Text("Between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic.  Defaults to 1.0")
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(0.5)
            }
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
        HStack (alignment: .top) {
            VStack (alignment: .leading) {
                Text("Default top_p")
                Text("An alternative to sampling with temperature, called nucleus sampling, where the model considers the results of the tokens with top_p probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered. Defaults to 1.0")
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(0.5)
            }
            Spacer()
            Stepper {
                Text(String(format: "%1.\(topP > 0 ? 1 : 2)f", topP))
            } onIncrement: {
                topPInt += 1
                topPInt = min(10, topPInt)
            } onDecrement: {
                topPInt -= 1
                topPInt = max(topPInt, -8)
            } .onChange(of: defaultTemperatureInt, perform: save)
        }
        HStack (alignment: .top) {
            VStack (alignment: .leading) {
                Text("Default presence penalty")
                Text("Number between -2.0 and 2.0. Positive values penalize new tokens based on whether they appear in the text so far, increasing the model's likelihood to talk about new topics. Defaults to 0")
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(0.5)
            }
            Spacer()
            Stepper {
                Text(String(format: "%1.1f", presencePenalty))
            } onIncrement: {
                presencePenaltyInt += 1
                presencePenaltyInt = min(20, presencePenaltyInt)
            } onDecrement: {
                presencePenaltyInt -= 1
                presencePenaltyInt = max(presencePenaltyInt, -20)
            } .onChange(of: defaultTemperatureInt, perform: save)
        }
        HStack (alignment: .top) {
            VStack (alignment: .leading) {
                Text("Default frequency penalty")
                Text("Number between -2.0 and 2.0. Positive values penalize new tokens based on their existing frequency in the text so far, decreasing the model's likelihood to repeat the same line verbatim. Defaults to 0")
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(0.5)
            }
            Spacer()
            Stepper {
                Text(String(format: "%1.1f", frequencyPenalty))
            } onIncrement: {
                frequencyPenaltyInt += 1
                frequencyPenaltyInt = min(20, frequencyPenaltyInt)
            } onDecrement: {
                frequencyPenaltyInt -= 1
                frequencyPenaltyInt = max(frequencyPenaltyInt, -20)
            } .onChange(of: defaultTemperatureInt, perform: save)
        }
        HStack(alignment: .top) {
            VStack (alignment: .leading) {
                Text("Default system prompt")
                Text("This instruction will guide your model's behavior throughout the conversation.")
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(0.5)
            }
            Spacer()
            Button {
                openWindow(id: "system-prompt")
            } label: {
                Label("Edit", systemImage: "pencil.line")
            }
            Button {
                UserDefaults.standard.removeObject(forKey: PreferencesManager.StoredPreferenceKey.defaultPrompt)
                PreferencesManager.shared.objectWillChange.send()
            } label: {
                Image(systemName: "arrow.2.squarepath")
            }.help("Reset")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Spacer()
                Text("These settings apply only to new conversations").bold().italic()
                Spacer()
            }.padding([.top, .bottom], 5)
            commonSettings
        }
        .padding([.bottom, .leading, .trailing], 15)
        .onAppear() {
            getPreferences()
        }
    }
    
    func save<V>(_ _: V? = nil) {
        save()
    }
    
    func save() {
        PreferencesManager.shared.defaultModel = model
        PreferencesManager.shared.defaultTemperature = defaultTemperature
        PreferencesManager.shared.defaultTopP = topP
        PreferencesManager.shared.defaultPresencePenalty = presencePenalty
        PreferencesManager.shared.defaultFrequencyPenalty = frequencyPenalty
        PreferencesManager.shared.maxTokensManual = !manageMax
        PreferencesManager.shared.maxTokens = maxTokens
        PreferencesManager.shared.streamChat = stream
    }
    
    func getPreferences() {
        defaultTemperatureInt = Int(PreferencesManager.shared.defaultTemperature * 10)
        model = PreferencesManager.shared.defaultModel
        stream = PreferencesManager.shared.streamChat
    }
}
