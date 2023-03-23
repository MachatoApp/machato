//
//  AppearanceSettings.swift
//  Machato
//
//  Created by Théophile Cailliau on 09/04/2023.
//

import SwiftUI

struct AppearanceSettings: View {
    @AppStorage(PreferencesManager.StoredPreferenceKey.hideConversationSummary) var hideConversationSummary : Bool = false;
    @AppStorage(PreferencesManager.StoredPreferenceKey.colorScheme) var colorSchemeString : String = AppColorScheme.system.rawValue;
    @AppStorage(PreferencesManager.StoredPreferenceKey.useServiceIcons) var useServiceIcons : Bool = true;
    private var update : Bool = false;
    @ObservedObject var prefs = PreferencesManager.shared;
    @Environment(\.colorScheme) var colorScheme;

    var body: some View {
        VStack (alignment: .leading) {
            Picker(selection: $colorSchemeString) {
                ForEach(AppColorScheme.allCases) { cs in
                    Text(cs.rawValue.capitalized).tag(cs.rawValue)
                }
            } label: {
                Text("App theme") + Text(" (needs a restart)").foregroundColor(.gray)
            }
#if os(macOS)
            .pickerStyle(.segmented)
#endif
            HStack {
                Text("Font size              ")
                Image(systemName: "textformat.size.smaller")
                Slider(value: $prefs.fontSize, in: 11...31, step: 2)
                Image(systemName: "textformat.size.larger")
            }
            Toggle(isOn: $prefs.narrowMessages) {
                VStack (alignment: .leading) {
                    Text("Narrow conversation in large windows")
                    Text("When enabled, messages have a maximum width.")
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(0.5)
                }
            }.toggleStyle(.checkboxRight)
            if prefs.narrowMessages {
                HStack {
                    Text("Max message width       ")
                    Slider(value: $prefs.maxWidth, in: 500...1200, step: 100)
                    Text(Int(prefs.maxWidth).description + "pt").frame(width: 50)
                }
            }
            Picker(selection: $prefs.defaultTypeset, label: Text("Render text by default as: ")) {
                ForEach(TypesetFunctionality.allCases) { fun in
                    Text(fun.description).tag(fun)
                }
            }.id(update)
            #if os(macOS)
                .pickerStyle(.segmented)
            #endif
            Toggle(isOn: $hideConversationSummary) {
                Text("Hide conversation summary in side pane")
            }.toggleStyle(.checkboxRight)
            Toggle(isOn: $prefs.messageTimestamp) {
                VStack (alignment: .leading) {
                    Text("Show timestamps")
                    Text("When enabled, message timestamps appear upon hovering on each message.")
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(0.5)
                }
            }.toggleStyle(.checkboxRight)
            Toggle(isOn: $useServiceIcons) {
                VStack (alignment: .leading) {
                    Text("Use the model's service icon in messages")
                    Text("When enabled, the icon that indicates a reply will correspond to the model that was used to generate this message.")
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(0.5)
                }
            }.toggleStyle(.checkboxRight)
        }
    }
}
