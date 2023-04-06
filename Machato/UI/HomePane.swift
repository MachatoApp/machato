//
//  HomePane.swift
//  Machato
//
//  Created by Théophile Cailliau on 30/03/2023.
//

import SwiftUI

struct HomePane: View {
    public var newConvo : () -> Void;
    public var openSettings : () -> Void;
    
    var body: some View {
        ZStack {
            VStack {
                Text("Make sure to set your **API key** and your **license key** in the settings !").font(.title2).frame(width: 300).multilineTextAlignment(.center)
                HStack {
                    Button {
                        openSettings()
                    } label: {
                        Label("App settings", systemImage: "gearshape").labelStyle(.titleAndIcon)
                    } .buttonStyle(.borderedProminent)
                    Button() {
                        newConvo()
                    } label: {
                        Label("Start a new conversation", systemImage: "text.bubble.fill").labelStyle(.titleAndIcon)
                    }.buttonStyle(.bordered)
                }
            }
            VStack(alignment: .leading) {
                Spacer()
                HStack {
                    Image(systemName: "arrow.left")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 15, height: 15)
                    Text("Check out the settings !")
                    Spacer()
                }.padding([.bottom, .leading], 14)
            }
        }
    }
    
    init(newConvo: @escaping (() -> Void), openSettings: @escaping (() -> Void)) {
        self.newConvo = newConvo
        self.openSettings = openSettings
    }
}

struct HomePane_Previews: PreviewProvider {
    static var previews: some View {
        HomePane() { } openSettings: {
            
        }
    }
}
