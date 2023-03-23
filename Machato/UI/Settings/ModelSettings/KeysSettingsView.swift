//
//  KeysSettingsView.swift
//  Machato
//
//  Created by Théophile Cailliau on 09/04/2023.
//

import SwiftUI

struct ProfilesSettings : View {
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Model.date_added, ascending: true)]) var models : FetchedResults<Model>;
    @State var selection : Model? = nil;
        
    @Environment(\.managedObjectContext) var moc;

    var body: some View {
        if models.isEmpty {
            HStack {
                Spacer()
                
            VStack {
                Text("Add a profile to Machato")
                
//                ScrollView(.horizontal) {
                    HStack {
                        ForEach(ModelType.allCases) { type in
                            Button {
                                let model = Model(context: moc)
                                model.date_added = Date.now
                                model.name = "Default"
                                model.openai_prefix = ""
                                model.type = type.rawValue
                                selection = model
                                try? moc.save()
                            } label: {
                                VStack {
                                    Image(type.rawValue)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundColor(.primary)
                                        .frame(height: 30)
                                    Text(type.description)
                                }.padding(5).padding([.leading, .trailing], 5)
                            } .buttonStyle(.borderless)
                                .background(.gray.opacity(0.2))
                                .cornerRadius(5)
                        }
                    }
//                }
            }
                Spacer()
            }

        } else {
            VStack  {
                HStack (spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        List(selection: $selection) {
                            ForEach(models) { model in
                                Text("\(ModelType.fromString(model.type).description): \(model.name ?? "N/A")").tag(model)
                            }
                        }.background(AppColors.chatBackgroundColor).frame(minHeight: 150).padding(5)
                            .onAppear() {
                                selection = models.first
                            }
                        Spacer()
                        VStack (alignment: .leading, spacing: 0) {
                            Divider()
                            HStack(spacing: 0) {
                                Menu {
                                    ForEach(ModelType.allCases) { type in
                                        Button(type.description) {
                                            let model = Model(context: moc)
                                            model.date_added = Date.now
                                            model.name = "New"
                                            model.openai_prefix = "new"
                                            model.type = type.rawValue
                                            selection = model
                                            try? moc.save()
                                            ModelManager.shared.updateAvailableModels()
                                        }
                                    }
                                } label: {
                                    Image(systemName: "plus").padding(3)
                                }.menuStyle(.borderlessButton).menuOrder(.fixed).menuIndicator(.hidden).fixedSize()
                                Divider()
                                Button {
                                    if let selection = selection {
                                        moc.delete(selection)
                                        try? moc.save()
                                        ModelManager.shared.updateAvailableModels()
                                    }
                                    selection = nil
                                } label: {
                                    Image(systemName: "minus").padding(3)
                                }.buttonStyle(.borderless)
                                Divider()
                            }
                        }.frame(height: 20)
                    }.background(AppColors.chatBackgroundColor)
                        .frame(maxWidth: 200)
                    Divider()
                    HStack(alignment: .top, spacing: 0) {
                        VStack {
                            ModelSettings(model: $selection)
                            Spacer()
                        }.padding(10)
                        Spacer()
                    }
                }.background(AppColors.chatBackgroundColor).padding(5)
            }
        }
    }

}

struct KeysSettingsView: View {
    @ObservedObject var prefs = PreferencesManager.shared;

    var body: some View {
        VStack {
            #if !MAS
            GumroadLicenseInputForm().padding()
            #endif
            ProfilesSettings()
//            TODO: enable this when CloudKit crash is fixed. // BUG IN CLIENT OF CLOUDKIT: Not entitled to listen to push notifications. Please add the 'com.apple.private.aps-connection-initiate' entitlement.
            Divider()
            Toggle(isOn: $prefs.iCloudSync) {
                VStack (alignment: .leading) {
                    Text("iCloud Sync")
                    Text("Sync conversations, messages, and settings via iCloud. Useful if you are using Machato on multiple devices. You need to enable this feature on all devices you wish to sync. You also need to restart the app after enabling this feature.")
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(0.5)
                }
            }.toggleStyle(.checkboxRight)
                .padding([.leading, .trailing], 10)
        }
        
    }
}
