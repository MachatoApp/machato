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
    
    var body: some View {
        //        #if DEBUG
        //        Text(cs.overrideGlobal.description)
        //        #endif
//        Picker(selection: $cs.model) {
//            ForEach(OpenAIChatModel.allCases) { model in
//                Text(model.rawValue.uppercased())
//                    .font(.subheadline.monospaced())
//                    .tag(model)
//            }
//        } label: { }
//        Picker(selection: $cs.typeset) {
//            ForEach(TypesetFunctionality.allCases) { typ in
//                Text(typ.description)
//                    .font(.subheadline.monospaced())
//                    .tag(typ)
//            }
//        } label: { }
        
        Button() {
            openConvoSettingsPane = true
        } label: {
            Label("Conversation settings", systemImage: "doc.badge.gearshape")
                .labelStyle(.iconOnly)
        }.help("Conversation settings")
            .buttonStyle(.bordered)
            .popover(isPresented: $openConvoSettingsPane, arrowEdge: .bottom) {
                ConversationSpecificSettings(forConvo: c).environmentObject(cs)
            }
    }
    
    init(_ c: Conversation) {
        self.c = c
        self.cs = PreferencesManager.getConversationSettings(c)
    }
}
