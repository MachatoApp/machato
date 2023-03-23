//
//  OpenAIModelSettings.swift
//  Machato
//
//  Created by Théophile Cailliau on 05/07/2023.
//

import Foundation
import SwiftUI


struct OpenAIModelSettings : View {
    @Binding var model : Model?
    
    @Environment(\.managedObjectContext) var moc
    
    @State var apiKey : String = ""
    @State var name : String = ""
    @State var prefix : String = ""
    
    @State var update : Bool = false;
    
    var body: some View {
        if let model = model {
            VStack (alignment: .leading) {
                HStack {
                    Text("Profile name").help("This name is only used in this window")
                    TextField("Profile name", text: $name)
                        .onChange(of: name) { newValue in
                            model.name = newValue
                            try? moc.save()
                        }
                }
                HStack {
                    Text("OpenAI API Key:")
                    OpenAIApiInputField(apiKey: $apiKey)
                        .onChange(of: apiKey) { newValue in
                            model.openai_api_key = newValue
                            try? moc.save()
                        }
                }
                HStack {
                    Text("Model prefix").help("This prefix helps distinguish models from different profiles")
                    TextField("", text: Binding(get: {
                        prefix.replacing(#/-+$/#, with: "-")
                    }, set: { v in
                        prefix = v.lowercased()
                        prefix = prefix.replacing(#/[^a-z\-]/#, with: "")
                        prefix = prefix.replacing(#/-+/#, with: "-")
                    }))
                    .onChange(of: prefix) { newValue in
                        model.openai_prefix = newValue
                        try? moc.save()
                        ModelManager.shared.updateAvailableModels()
                    }
                }
                HStack (alignment: .top){
                    Text("Enabled models:")
                    VStack (alignment: .leading) {
                        ForEach(OpenAIChatModel.allCases) { m in
                            let modelName = "\(m.rawValue);"
                            Toggle("\(prefix)\(prefix.isEmpty || prefix.hasSuffix("-") ? "" : "-")\(m.rawValue)", isOn: Binding(get: {
                                return self.model?.openai_enabled_models?.contains(modelName) ?? false
                            }, set: { v in
                                self.model?.openai_enabled_models = self.model?.openai_enabled_models ?? ""
                                if v == true && !(self.model?.openai_enabled_models?.contains(modelName) ?? false) {
                                    self.model?.openai_enabled_models? += modelName
                                } else if v == false {
                                    self.model?.openai_enabled_models = self.model?.openai_enabled_models?.replacingOccurrences(of: modelName, with: "")
                                }
                                try? PreferencesManager.shared.persistentContainer.viewContext.save()
                                ModelManager.shared.updateAvailableModels()
                                update.toggle()
                            }))
                        }
                    }.id(update)
                }
            }.onAppear() {
                updateValues()
            }.onChange(of: model) { _ in
                updateValues()
            }
        }
    }
    
    func updateValues() {
        if let model = model {
            name = model.name ?? "OpenAI"
            apiKey = model.openai_api_key ?? ""
            prefix = model.openai_prefix ?? "prefix"
        }
    }
}
