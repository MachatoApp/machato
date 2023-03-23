//
//  SettingsView.swift
//  Machato
//
//  Created by Théophile Cailliau on 28/03/2023.
//

import SwiftUI

struct ConversationSpecificSettings: View {
    
    enum Fields: String, CaseIterable {
        case temperature, top_p, model, typeset, max_tokens, presence_penalty, frequency_penalty, stream, functions
    }

    @EnvironmentObject private var currentSettings : ConversationSettings;
    private var convo: Conversation;
    @Environment(\.dismiss) var dismiss
    @State private var temperatureInt = 7;
    private var temperature : Float {
        return Float(temperatureInt) / 10.0
    }
    
    @State private var topPInt = 10
    private var topP : Float {
        return topPInt > 0 ? Float(topPInt) / 10.0 : Float(9+topPInt) / 100.0
    }
    
    @State private var presencePenaltyInt = 0;
    private var presencePenalty : Float {
        return Float(presencePenaltyInt) / 10.0
    }
    
    @State private var frequencyPenaltyInt = 0;
    private var frequencyPenalty : Float {
        return Float(frequencyPenaltyInt) / 10.0
    }
    @State private var manageMax : Bool = true;
    @State private var maxTokensLog : Double = 0;
    var maxTokens : Int32 {
        Int32(pow(2,maxTokensLog))
    }
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "type", ascending: true)]) var functions : FetchedResults<Function>;
    
    var fields : [Fields];
    
    @ViewBuilder
    var commonSettings: some View {
        if fields.contains(.temperature) {
            HStack {
                Text("Temperature")
                Spacer()
                Stepper {
                    Text(String(format: "%1.1f", temperature))
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
        if fields.contains(.max_tokens) {
            Toggle(isOn: $manageMax) {
                Text("Auto max_tokens")
            } .onChange(of: manageMax) { _ in
                currentSettings.manageMax = manageMax
            }.toggleStyle(.checkboxRight)
            if !manageMax {
                HStack {
                    Text("\(maxTokens)").font(.body.monospaced()).frame(minWidth: 70)
                    Slider(value: $maxTokensLog, in: 0...17)
                        .onChange(of: maxTokensLog) { _ in
                            currentSettings.maxTokens = maxTokens
                        }
                }
            }
        }
        if fields.contains(.top_p) {
            HStack {
                Text("Top P")
                Spacer()
                Stepper {
                    Text(String(format: "%1.\(topP > 0 ? 1 : 2)f", topP))
                } onIncrement: {
                    topPInt += 1
                    topPInt = min(10, topPInt)
                } onDecrement: {
                    topPInt -= 1
                    topPInt = max(topPInt, -8)
                } .onChange(of: topPInt) { _ in
                    currentSettings.topP = topP
                }
            }
        }
        if fields.contains(.presence_penalty) {
            HStack {
                Text("Presence Penalty")
                Spacer()
                Stepper {
                    Text(String(format: "%1.1f", presencePenalty))
                } onIncrement: {
                    presencePenaltyInt += 1
                    presencePenaltyInt = min(20, presencePenaltyInt)
                } onDecrement: {
                    presencePenaltyInt -= 1
                    presencePenaltyInt = max(presencePenaltyInt, -20)
                } .onChange(of: presencePenaltyInt) { _ in
                    currentSettings.presencePenalty = presencePenalty
                }
            }

        }
        if fields.contains(.frequency_penalty) {
            HStack {
                Text("Frequency Penalty")
                Spacer()
                Stepper {
                    Text(String(format: "%1.1f", frequencyPenalty))
                } onIncrement: {
                    frequencyPenaltyInt += 1
                    frequencyPenaltyInt = min(20, frequencyPenaltyInt)
                } onDecrement: {
                    frequencyPenaltyInt -= 1
                    frequencyPenaltyInt = max(frequencyPenaltyInt, -20)
                } .onChange(of: frequencyPenaltyInt) { _ in
                    currentSettings.frequencyPenalty = frequencyPenalty
                }
            }
        }
        if fields.contains(.functions) && currentSettings.model.supportsFunctions {
            let s = VStack(alignment: .leading) {
                ForEach(functions) { fun in
                    if let type = fun.type {
                        Toggle(isOn: Binding(get: {
                            currentSettings.enabledFunctions.contains(fun)
                        }, set: { v in
                            currentSettings.enabledFunctions = currentSettings.enabledFunctions.filter { $0.type != type }
                            if v {
                                currentSettings.enabledFunctions.append(fun)
                            }
                        })) {
                            Text(type).font(.body.monospaced())
                        }.toggleStyle(.checkboxRight)
                    }
                }
            }.padding(.leading, 15)
            if fields.count == 1 {
                s
            }else {
                DisclosureGroup("Enabled functions") {
                    s
                }
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            commonSettings.frame(width: 240)
        }
        .padding(15)
        .onAppear {
            temperatureInt = Int(currentSettings.temperature * 10)
            topPInt = Int(currentSettings.topP == 0 ? 10 : currentSettings.topP < 0.1 ? currentSettings.topP * 100 - 9 : currentSettings.topP * 10)
            presencePenaltyInt = Int(currentSettings.presencePenalty * 10)
            frequencyPenaltyInt = Int(currentSettings.frequencyPenalty * 10)
            manageMax = currentSettings.manageMax
            maxTokensLog = log2(Double(currentSettings.maxTokens))
        }
    }
    
    init(forConvo c: Conversation, fields : [Fields] = Fields.allCases) {
        self.convo = c;
        self.fields = fields
    }
}
