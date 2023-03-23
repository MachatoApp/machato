//
//  SwiftUIView.swift
//  Machato
//
//  Created by Théophile Cailliau on 02/10/2023.
//

import SwiftUI

struct LocalAIModelSettings: View {
    
    @Binding var model: Model?
    @State var name : String = ""
    @State var endpoint : String = ""
    @State var prefix : String = ""
    @State var update : Bool = false;
    @State var error : Bool = false;
    
    var availableModels : [String] {
        model?.localai_available_models?.components(separatedBy: ";").filter { $0 != "" } ?? []
    }

    @Environment(\.managedObjectContext) var moc;
    
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
                    Text("LocalAI endpoint:")
                    TextField("http://...", text: $endpoint)
                        .onChange(of: endpoint) { newValue in
                            model.localai_endpoint = newValue
                            try? moc.save()
                            ModelManager.shared.updateAvailableModels()
                        }
                }
                HStack {
                    Text("Model prefix:")
                    TextField("", text: $prefix)
                        .onChange(of: prefix) { newValue in
                            model.localai_prefix = newValue
                            try? moc.save()
                            ModelManager.shared.updateAvailableModels()
                        }
                }
                HStack (alignment: .top){
                    Text("Enabled models:")
                    VStack (alignment: .leading) {
                        Button("Refresh available models") {
                            Task { @MainActor in
                                guard let available = try? await ChatAPIManager.shared.fetchLocalAIModelNames(endpoint: endpoint) else {
                                    error = true
                                    return
                                }
                                error = false
                                model.localai_available_models = available.joined(separator: ";")
                                print(available)
                            }
                        }
                        ForEach(availableModels, id: \.self) { modelName in
                            Toggle("\(prefix)\(prefix.isEmpty || prefix.hasSuffix("-") ? "" : "-")\(modelName)", isOn: Binding(get: {
                                return self.model?.localai_enabled_models?.contains(modelName) ?? false
                            }, set: { v in
                                self.model?.localai_enabled_models = self.model?.localai_enabled_models ?? ""
                                if v == true && !(self.model?.localai_enabled_models?.contains(modelName) ?? false) {
                                    self.model?.localai_enabled_models? += modelName
                                } else if v == false {
                                    self.model?.localai_enabled_models = self.model?.localai_enabled_models?.replacingOccurrences(of: modelName, with: "")
                                }
                                try? PreferencesManager.shared.persistentContainer.viewContext.save()
                                print("Updating models!")
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
            name = model.name ?? "LocalAI"
            prefix = model.localai_prefix ?? ""
            endpoint = model.localai_endpoint ?? ""
        }
    }
}
