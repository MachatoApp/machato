//
//  SettingsView.swift
//  Machato
//
//  Created by Théophile Cailliau on 28/03/2023.
//

import SwiftUI
import Sparkle

struct ConversationSpecificSettings: View {

    @EnvironmentObject private var currentSettings : ConversationSettings;
    private var convo: Conversation;
    @Environment(\.dismiss) var dismiss
    @State private var temperatureInt = 7;
    private var temperature : Float {
        return Float(temperatureInt) / 10.0
    }
    
    @ViewBuilder
    var commonSettings: some View {
        Toggle(isOn: $currentSettings.stream) {
            Text("Stream chat response")
        }
        Picker(selection: $currentSettings.typeset, label: Text("Text rendering capabilities")) {
            ForEach(TypesetFunctionality.allCases) { fun in
                Text(fun.description).tag(fun)
            }
        }
        Picker(selection: $currentSettings.model, label: Text("Model")) {
            ForEach(OpenAIChatModel.allCases) { fun in
                Text(fun.rawValue).tag(fun)
            }
        }
        HStack {
            Text("Temperature")
            Spacer()
            Stepper {
                Text(temperature.description)
            } onIncrement: {
                temperatureInt += 1
                temperatureInt = min(20, temperatureInt)
            } onDecrement: {
                temperatureInt -= 1
                temperatureInt = max(temperatureInt, 0)
            } .onChange(of: temperatureInt) { _ in
                currentSettings.temperature = temperature
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
                Text("Settings for conversation: \(convo.title ?? "Untitled")").lineLimit(2)
            Toggle(isOn: $currentSettings.overrideGlobal) {
                    Text("Conversation settings override global settings")
                }
                if currentSettings.overrideGlobal {
                    commonSettings
                }
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text("Done!")
                } .buttonStyle(.borderedProminent)
            }
        }
        .padding(15)
        .onAppear {
            temperatureInt = Int(currentSettings.temperature * 10)
        }
    }
    
    init(forConvo c: Conversation) {
        self.convo = c;
    }
}
