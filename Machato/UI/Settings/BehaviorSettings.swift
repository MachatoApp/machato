//
//  BehaviorSettings.swift
//  Machato
//
//  Created by Théophile Cailliau on 21/04/2023.
//

import SwiftUI

struct BehaviorSettings: View {
    @AppStorage(PreferencesManager.StoredPreferenceKey.sendWithShiftEnter) var sendWithShiftEnter : Bool = false;
    @AppStorage(PreferencesManager.StoredPreferenceKey.allowMessageExclusion) var allowMessageExclusion : Bool = false;
    @AppStorage(PreferencesManager.StoredPreferenceKey.autoScroll) var autoScroll : Bool = true;
    
    var body: some View {
        VStack {
            Toggle(isOn: $sendWithShiftEnter) {
                VStack(alignment: .leading) {
                    Text("Send messages with Shift+Enter")
                    Text("This setting switches the roles of Enter and Shift+Enter in the text field. When enabled, Shift+Enter sends the message and Enter inputs a newline.")
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(0.5)

                }
            }.toggleStyle(.checkboxRight)
            Toggle(isOn: $allowMessageExclusion) {
                VStack(alignment: .leading) {
                    Text("Allow excluding messages from requests")
                    Text("When enabled, an extra button on each message will allow you to exclude messages from requests to the OpenAI API. This will save tokens when used properly.")
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(0.5)
                }
            }.toggleStyle(.checkboxRight)
            Toggle(isOn: $autoScroll) {
                VStack(alignment: .leading) {
                    Text("Automatically scroll down")
                    Text("When enabled, conversations will automatically scroll down to the last line of the last message when one is received when the app is scrolled near the bottom.")
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(0.5)
                }
            }.toggleStyle(.checkboxRight)
        }.padding()
    }
}
