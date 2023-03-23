//
//  FunctionSettings.swift
//  Machato
//
//  Created by Théophile Cailliau on 25/06/2023.
//

import SwiftUI
import MarkdownUI

struct FunctionsSettings: View {
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "type", ascending: true)]) var functions : FetchedResults<Function>;
    @State private var selection : Function? = nil;
    @Environment(\.managedObjectContext) var moc;
    
    @State private var register : RegisterableFunctionType? = nil
    @State private var data : [String : String] = [:]
    
    var body: some View {
        HStack(alignment: .top) {
            VStack {
                List(selection: $selection) {
                    Section("No auth required") {
                        let noauth = functions.filter { $0.authfamily == "none" }
                        ForEach(noauth) { fun in
                            Text(fun.type ?? "No type").tag(fun)
                        }
                    }
                    let owm = functions.filter { $0.authfamily == "owm" }
                    if !owm.isEmpty {
                        Section("OpenWeatherMap") {
                            ForEach(owm) { fun in
                                Text(fun.type ?? "No type").tag(fun)
                            }
                        }
                    }
                }
                VStack (alignment: .leading, spacing: 0) {
                    Divider()
                    HStack(spacing: 0) {
                        Menu {
                            ForEach(RegisterableFunctionType.allCases) { type in
                                Button(type.description) {
                                    data = [:]
                                    register = type
                                }
                            }
                        } label: {
                            Image(systemName: "plus").padding(3).foregroundColor(.primary)
                        }.menuStyle(.borderlessButton).menuOrder(.fixed).menuIndicator(.hidden).fixedSize().foregroundColor(.primary)
                        Divider()
                        Button {
                            if let selection = selection {
                                moc.delete(selection)
                                try? moc.save()
                                FunctionsManager.shared.updateAvailableFunctions()
                            }
                            selection = nil
                        } label: {
                            Image(systemName: "minus").padding(3)
                        }.buttonStyle(.borderless)
                            .disabled(selection?.customisable == false)
                        Divider()
                    }
                }.frame(height: 20)
            }.frame(maxWidth: 200)
            Divider()
            VStack(alignment: .leading) {
                if let selection = selection, let implem = try? FunctionsManager.shared.function(from: selection) {
                    (Text("Function name: ").bold() + Text(implem.name).font(.body.monospaced())).lineLimit(nil).fixedSize(horizontal: false, vertical: true)
                    (Text("Function description: ").bold() + Text(implem.description).italic()).lineLimit(nil).fixedSize(horizontal: false, vertical: true)
                                        
                    if let jsonp = try? JSONSerialization.data(withJSONObject: implem.parameters, options: .prettyPrinted) {
                        Markdown("**JSONP Arguments description:**\n```json\n\(String(data: jsonp, encoding: .utf8) ?? "Couldn't parse json description")\n```")
                            .markdownCodeSyntaxHighlighter(HighlightrSyntaxHighlighter.shared)
                            .markdownBlockStyle(\.codeBlock) { config in
                                config.label.padding([.leading, .trailing], 15).padding([.bottom], 20).padding([.top], 8)
                            }.fixedSize(horizontal: false, vertical: true)
                    }
                    if selection.authfamily == "owm" {
                        HStack {
                            Text("OpenWeatherMap API Key: ")
                            TextField("OpenWeatherMap API Key", text: Binding(get: {
                                selection.owm_api ?? ""
                            }, set: { v in
                                selection.owm_api = v
                            }))
                        }
                    }
                } else {
                    Text("Select a function from the right panel").opacity(0.5)
                }
            }
            Spacer()
        }.sheet(item: $register) { type in
            VStack {
                switch type {
                case .owm:
                    TextField("OpenWeatherMap API key", text: Binding(get: {
                        data["owm_api_key"] ?? ""
                    }, set: { v in
                        data["owm_api_key"] = v
                    })).frame(minWidth: 200)
                }
                Button("Register") {
                    type.register(data: data)
                    try? moc.save()
                    FunctionsManager.shared.updateAvailableFunctions()
                    register = nil
                }.buttonStyle(.borderedProminent)
            }.padding(10)
        }
    }
}
