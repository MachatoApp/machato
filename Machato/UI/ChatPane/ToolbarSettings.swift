//
//  ToolbarSettings.swift
//  Machato
//
//  Created by Théophile Cailliau on 10/04/2023.
//

import SwiftUI

struct ToolbarSettings: View {
    private var c : Conversation;
    @ObservedObject private var cs : ConversationSettings;
    @State private var openConvoSettingsPane : Bool = false;
    @StateObject private var currentSettings : ConversationSettings = ConversationSettings();
    
    var body: some View {
        Chip(cs.model.rawValue.uppercased())
        Chip(cs.typeset.description.uppercased())
        Button() {
            openConvoSettingsPane = true
        } label: {
            Label("Conversation settings", systemImage: "gearshape")
                .labelStyle(.iconOnly)
        }
        .buttonStyle(.bordered)
        .sheet(isPresented: $openConvoSettingsPane) {
            currentSettings.copyInto(cs)
            guard let cse = c.has_settings else { return }
            cs.save(cse)
            c.update.toggle()
        } content: {
            ConversationSpecificSettings(forConvo: c).environmentObject(currentSettings)
        } .onAppear {
            cs.copyInto(currentSettings)
        } .onChange(of: openConvoSettingsPane) { nv in
            guard nv == true else { return }
            cs.copyInto(currentSettings)
        }
    }
    
    init(_ c: Conversation) {
        self.c = c
        self.cs = PreferencesManager.getConversationSettings(c)
    }
}
