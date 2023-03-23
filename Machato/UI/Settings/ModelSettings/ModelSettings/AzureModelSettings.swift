//
//  AzureModelSettings.swift
//  Machato
//
//  Created by Théophile Cailliau on 05/07/2023.
//

import Foundation
import SwiftUI

struct AzureModelSettings : View {
    @Binding var model: Model?
    
    @Environment(\.managedObjectContext) var moc
    
    @State var endpoint : String = ""
    @State var apiKey : String = ""
    @State var modelName : String = ""
    @State var deployment : String = ""
    @State var name : String = "";
    
    @State var update : Bool = false;
    
    var body: some View {
        if let model = model {
            VStack (alignment: .leading) {
                HStack {
                    Text("Profile name:").help("This name is only used in this window")
                    TextField("Profile name", text: $name)
                        .onChange(of: name) { newValue in
                            model.name = newValue
                            try? moc.save()
                        }
                }
                HStack {
                    Text("Azure endpoint")
                    TextField("https://XXX.openai.azure.com/", text: $endpoint)
                        .onChange(of: endpoint) { newValue in
                            model.azure_company_endpoint = newValue
                            try? moc.save()
                        }
                }
                HStack {
                    Text("Azure API key")
                    TextField("", text: $apiKey)
                        .onChange(of: apiKey) { newValue in
                            model.azure_api_key = newValue
                            try? moc.save()
                        }
                }
                HStack {
                    Text("Azure Deployment name")
                    TextField("", text: $deployment)
                        .onChange(of: deployment) { newValue in
                            model.azure_deployment_name = newValue
                            try? moc.save()
                        }
                }
                HStack {
                    Text("Model name")
                    TextField("", text: $modelName).font(.body.monospaced())
                        .onChange(of: modelName) { newValue in
                            model.azure_model_name = newValue
                            try? moc.save()
                            ModelManager.shared.updateAvailableModels()
                        }
                }
                HStack (alignment: .top) {
                    VStack (alignment: .leading) {
                        Text("Associated model")
                        Text("This is used to choose the right cost estimates.").font(.subheadline)
                    }
                    Picker("", selection: Binding(get: {
                        model.azure_associated_chatgpt_model ?? "gpt-3.5-turbo"
                    }, set: { v in
                        model.azure_associated_chatgpt_model = v
                        update.toggle()
                    })) {
                        ForEach(OpenAIChatModel.allCases) { m in
                            Text(m.rawValue).tag(m.rawValue)
                        }
                    }.id(update)
                }
            }.onAppear() {
                updateValues()
            } .onChange(of: model) { _ in
                updateValues()
            }
        }
    }
    
    func updateValues() {
        if let model = model {
            name = model.name ?? "OpenAI"
            endpoint = model.azure_company_endpoint ?? ""
            apiKey = model.azure_api_key ?? ""
            modelName = model.azure_model_name ?? ""
            deployment = model.azure_deployment_name ?? ""
        }
    }
}
