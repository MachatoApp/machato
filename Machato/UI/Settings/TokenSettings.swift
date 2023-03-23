//
//  TokenSettings.swift
//  Machato
//
//  Created by Théophile Cailliau on 14/04/2023.
//

import SwiftUI
import Charts

enum TokenCountTimespan: String, CaseIterable, Identifiable {
    case day
    case week
    case month
    case all_time = "all time"
    
    var id : String { return self.rawValue }
    static let default_case : Self = .day
    static func fromString(_ sm: String?) -> Self {
        guard let s = sm else { return default_case }
        for c in Self.allCases {
            if c.rawValue == s {
                return c
            }
        }
        return default_case
    }
}


struct TokenSettings: View {
    @AppStorage(PreferencesManager.StoredPreferenceKey.hideTokenCount) var hideTokenCount = false;
    @AppStorage(PreferencesManager.StoredPreferenceKey.defaultTokenCountTimespan) var tokenTimespan = TokenCountTimespan.day.rawValue;
    
    @State private var confirmDialogVisible : Bool = false;
    @State private var offset : Int = .zero;
    
    var body: some View {
        VStack (alignment: .leading) {
            Toggle(isOn: $hideTokenCount) {
                VStack (alignment: .leading){
                    Text("Hide cost estimate")
                    Text("This will hide the cost estimation at the bottom of the side pane. Cost estimation continues to happen in the background.")
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(0.5)
                }
            }.toggleStyle(.checkboxRight)
            Picker("Cost estimate timespan", selection: $tokenTimespan) {
                ForEach(TokenCountTimespan.allCases) { timespan in
                    Text(timespan.rawValue.capitalized).tag(timespan.rawValue)
                }
            }.onChange(of: tokenTimespan) { _ in
                TokenUsageManager.shared.updateCost()
            }
                .pickerStyle(.segmented)
            HStack {
                Spacer()
                Button("Clear token count") {
                    confirmDialogVisible = true
                }.confirmationDialog(
                    "You're about to clear the full history of token usage",
                    isPresented: $confirmDialogVisible
                ) {
                    Button("Clear all", role: .destructive) {
                        TokenUsageManager.shared.clearTokenHistory()
                    }
                    Button("Cancel", role: .cancel) {
                        confirmDialogVisible = false
                    }
                }
            }
            Divider().padding([.bottom, .top], 10)
            HStack(alignment: .bottom) {
                VStack {
                    Button {
                        offset -= 1
                    } label: {
                        VStack {
                            Spacer()
                            Label("Move backwards", systemImage: "chevron.compact.left").labelStyle(.iconOnly)
                                .padding([.leading, .trailing], 10)
                            Spacer()
                        }
                    }.buttonStyle(.borderless)
                        .opacity((PreferencesManager.shared.defaultTokenCountTimespan == .all_time) ? 0 : 1)
                    
                    
                    Spacer().frame(height: 60)
                } .onChange(of: PreferencesManager.shared.defaultTokenCountTimespan) { newValue in
                    offset = 0
                }
                TokenChart(pageOffset: offset, timespan: PreferencesManager.shared.defaultTokenCountTimespan)
                if PreferencesManager.shared.defaultTokenCountTimespan != .all_time {
                    
                    VStack {
                        Button {
                            offset += 1
                            offset = min(0, offset)
                            
                        } label: {
                            VStack {
                                Spacer()
                                Label("Move backwards", systemImage: "chevron.compact.right").labelStyle(.iconOnly)
                                    .padding([.leading, .trailing], 10)
                                Spacer()
                            }
                        }.buttonStyle(.borderless)
                        
                            .opacity((PreferencesManager.shared.defaultTokenCountTimespan == .all_time) || (offset >= 0) ? 0 : 1)
                        
                        Spacer().frame(height: 60)
                    }
                }
                
            }
        }
    }
}

