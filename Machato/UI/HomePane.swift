//
//  HomePane.swift
//  Machato
//
//  Created by Théophile Cailliau on 30/03/2023.
//

import SwiftUI
import Colorful

struct HomePane: View {
    let columns = [
        GridItem(.adaptive(minimum: 450), alignment: .center)
    ]
    
    @State private var timespan : TokenCountTimespan = PreferencesManager.shared.defaultTokenCountTimespan;
    
    @State private var newHover : Bool = false
    
    var body: some View {
        ScrollView(.vertical) {
            VStack {
                Spacer().frame(maxWidth: .infinity, maxHeight: 0).padding([.top], 50)
                HStack {
                    #if os(macOS)
                    Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                    #else
                    Image(uiImage: UIImage(named: "AppIcon") ?? UIImage())
                    #endif
                    Divider().tint(.clear).frame(minWidth: 1).overlay(.gray.opacity(0.5))
                    VStack {
                        Text("Welcome to **Machato** !").font(.title2).padding()
                        Button {
                            Signals.shared.selectConversation(DataActions.shared.newConversation())
                        } label: {
                            Label("New conversation", systemImage: "plus").labelStyle(.titleAndIcon).padding().foregroundColor(.primary)
                        }
                        .buttonStyle(.borderless)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .onHover { h in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                newHover = h
                            }
                        }.overlay {
                            RoundedRectangle(cornerRadius: 8).stroke(lineWidth: 1).foregroundColor(.gray.opacity(0.5))
                        }.scaleEffect(newHover ? 1.03 : 1)
                    }
                }//.background(ColorfulView(colors:[AppColors.matcha]))
                    .cornerRadius(8)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8).stroke(lineWidth: 1).foregroundColor(.gray.opacity(0.5))
                    }.padding([.bottom], 50)
                Divider()
                
                VStack {
                    HStack {
                        Text("Show usage for:")
                        Picker(selection: $timespan) {
                            ForEach(TokenCountTimespan.allCases, id: \.self) { ts in
                                Text(ts.rawValue.capitalized).tag(ts)
                            }
                        } label: {
                            EmptyView()
                        }
                        .pickerStyle(.segmented)
                    }.padding([.top, .bottom], 20)
                    TokenChart(pageOffset: 0, timespan: timespan)
                }
                .frame(maxWidth: 450, maxHeight: 450)
            }
        }
    }
}
