//
//  FunctionContent.swift
//  Machato
//
//  Created by Théophile Cailliau on 14/06/2023.
//

import SwiftUI

struct FunctionContent: View {
    @ObservedObject var message : Message;
    @ObservedObject var pref  = PreferencesManager.shared
    @Binding private var collapsed : Bool
    
    init(message: Message, _ collapsed: Binding<Bool>) {
        self._message = ObservedObject(initialValue: message)
        self._collapsed = collapsed
    }
    
    var body: some View {
        let content = message.content ?? ""
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(try! AttributedString(markdown: ((message.function_displaytext?.isEmpty == true) ? nil : message.function_displaytext) ??
                                           (
                                            (message.function_name ?? "") + ":" + (message.function_arguments?.replacing(#/\s+/#, with: " ") ?? "")
                                           )
                                          )
                )
                Spacer()
                if content.isEmpty {
                    ProgressView().scaleEffect(0.5).progressViewStyle(.circular)
                        .frame(width: 13*pref.fontSize/13, height: 13*pref.fontSize/13).foregroundColor(.red)
                } else {
                    if message.is_error {
                        Image(systemName: "exclamationmark.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 13*pref.fontSize/13, height: 13*pref.fontSize/13).foregroundColor(.red)
                    } else {
                        Image(systemName: "checkmark.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 13*pref.fontSize/13, height: 13*pref.fontSize/13).foregroundColor(.green)
                    }
                }
                
            }.onTapGesture {
                collapsed.toggle()
            }
            
            if message.is_finished && !collapsed {
                Line().stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                    .frame(height: 1).foregroundColor(.gray).opacity(0.35).padding(.top, 2).padding([.top, .bottom], 2)
                HStack {
                    Image(systemName: "arrow.right")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 10*pref.fontSize/13, height: 10*pref.fontSize/13).foregroundColor(.gray)
                    Spacer()
                    if content.isEmpty {
                        ProgressView().scaleEffect(0.5).progressViewStyle(.circular)
                            .frame(width: 13*pref.fontSize/13, height: 13*pref.fontSize/13).foregroundColor(.red)

                    } else {
                        Text(content).foregroundColor(message.is_error ? .red : .primary).multilineTextAlignment(.trailing)
                    }
                }
            }
        }.padding(.leading, 10).font(.system(size: pref.fontSize))
    }
}
