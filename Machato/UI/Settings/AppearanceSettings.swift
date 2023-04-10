//
//  AppearanceSettings.swift
//  Machato
//
//  Created by Théophile Cailliau on 09/04/2023.
//

import SwiftUI

struct AppearanceSettings: View {
    @AppStorage(PreferencesManager.StoredPreferenceKey.hide_conversation_summary) var hideConversationSummary : Bool = false;
    private var update : Bool = false;
    @ObservedObject var prefs = PreferencesManager.shared;
    @Environment(\.colorScheme) var colorScheme;

    var body: some View {
        VStack (alignment: .leading) {
            HStack {
                Text("Font size            ")
                Image(systemName: "textformat.size.smaller")
                Slider(value: $prefs.fontSize, in: 10...31, step: 3)
                    .onChange(of: prefs.fontSize) { _ in
                        MainView.updateCodeHighlightTheme(colorScheme)
                    }
                Image(systemName: "textformat.size.larger")
            }
            Picker(selection: $prefs.defaultTypeset, label: Text("Render text by default as: ")) {
                ForEach(TypesetFunctionality.allCases) { fun in
                    Text(fun.description).tag(fun)
                }
            }.id(update)
            #if os(macOS)
            .pickerStyle(.radioGroup)
            #endif
            Toggle(isOn: $hideConversationSummary) {
                Text("Hide conversation summary")
            }

        }
    }
}
