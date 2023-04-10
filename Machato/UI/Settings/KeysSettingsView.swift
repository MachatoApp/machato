//
//  KeysSettingsView.swift
//  Machato
//
//  Created by Théophile Cailliau on 09/04/2023.
//

import SwiftUI

struct KeysSettingsView: View {
    @AppStorage(PreferencesManager.StoredPreferenceKey.api_key) var api_key : String = "";
    @AppStorage(PreferencesManager.StoredPreferenceKey.license_key) var license_key : String = "";
    
    var body: some View {
        VStack {
            HStack {
                Text("API Key")
                TextField("OpenAI API key", text: $api_key)
            }

            HStack {
                Text("License Key")
                TextField("Gumroad license key", text: $license_key)
            }
        }.padding()
    }
}
