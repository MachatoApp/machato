//
//  Greetings.swift
//  Machato
//
//  Created by Théophile Cailliau on 24/04/2023.
//

import SwiftUI
import MarkdownUI

#if !MAS
struct GumroadLicenseInputForm : View {
    @AppStorage(PreferencesManager.StoredPreferenceKey.licenseKey) private var licenseKey : String = "";
    @AppStorage(PreferencesManager.StoredPreferenceKey.apiKey) var apiKey : String = "";

    @State private var gumroadStatus : ApiKeyStatus = .unchecked;
    
    @Binding private var status : Bool;
    
    func checkGumroad<T>(_ _: T) {
        checkGumroad()
    }
    
    func checkGumroad() {
        guard !(licenseKey.count < 35) else {
            gumroadStatus = .unchecked
            return
        }
        Task {
            let checked = await LicenseManager.shared.checkLicense()
            DispatchQueue.main.async {
                gumroadStatus = checked ? .valid : .invalid
                status = gumroadStatus == .valid
            }
        }
    }

    var body: some View {
        VStack {
            HStack {
                Text("Gumroad license key: ")
                Group {
                    if gumroadStatus == .valid {
                        Spacer()
                        Text(licenseKey).font(.body.monospaced()).onTapGesture {
                            gumroadStatus = .unchecked
                        }
                        Spacer()
                    } else {
                        GumroadLicenseInput(key: $licenseKey)
                    }
                }
                .onChange(of: licenseKey, perform: checkGumroad)
                KeyStatusIcon(status: gumroadStatus)
            } .onAppear(perform: checkGumroad)
        }
    }
    
    init(status: Binding<Bool>) {
        _status = status
    }
    
    init() {
        _status = Binding.constant(false)
    }
}
#endif

enum ApiKeyStatus {
    case valid, invalid, unchecked
}

struct OpenAIApiInputField : View {
    
    @State private var status : ApiKeyStatus = .unchecked;
    
    @Binding var apiKey : String
    
    func checkStatus<T>(_ _ : T) {
        checkStatus()
    }
    
    func checkStatus() {
        guard !(apiKey.count < 4) else {
            status = .unchecked
            return
        }
        Task {
            let checked = await ChatAPIManager.shared.checkOpenAIAPIKey(apiKey)
            DispatchQueue.main.async {
                status = checked ? .valid : .invalid;
            }
        }
    }
    
    var body: some View {
        HStack {
            TextField("sk-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", text: $apiKey)
                .onChange(of: apiKey, perform: checkStatus)
            KeyStatusIcon(status: status)
        }.onAppear(perform: checkStatus)
    }
}

struct KeyStatusIcon : View {
    var status : ApiKeyStatus
    var body : some View {
        let iconName : String;
        let color : Color;
        switch status {
        case .unchecked:
            iconName =  "square"
            color = .gray
        case .valid:
            iconName = "checkmark.square"
            color = .green
        case .invalid:
            iconName = "xmark.square"
            color = .red
        }
        return Image(systemName: iconName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 15, height: 15)
            .foregroundColor(color)
    }
}

struct Greetings: View {
    @Environment(\.dismiss) private var dismiss;
    
    @State private var showHelp : Bool = false;
    #if !MAS
    @State private var gumroadStatus : Bool = false;
    #else
    @State private var gumroadStatus : Bool = true;
    #endif
    
    var profileStatus : Bool {
        (models.first?.openai_api_key?.count ?? 0) > 4
        || (models.first?.azure_api_key?.count ?? 0) > 4
    }
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Model.date_added, ascending: true)]) var models : FetchedResults<Model>;
    
    @AppStorage(PreferencesManager.StoredPreferenceKey.hasLaunched) private var hasLaunched = false;
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                VStack(alignment: .leading) {
                    Text("Welcome to Machato!").font(.largeTitle).padding([.bottom], 15)
                    Text("Let's get you set up. You will need your **Gumroad** license key and your **ChatGPT** API key(s)")
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            #if !MAS
            Divider()
            GumroadLicenseInputForm(status: $gumroadStatus)
            #endif
            Divider()
            ProfilesSettings()
            Divider()
            HStack {
                if !(profileStatus && gumroadStatus) {
                    Button {
                        hasLaunched = true
                        dismiss()
                    } label: {
                        Text("Continue without creating a profile").foregroundColor(.gray).underline()
                    }.buttonStyle(.link)
                }
                Spacer()
                Button {
                    showHelp = true
                } label: {
                    Image(systemName: "questionmark.circle")
                }.buttonStyle(.borderless)
                    .popover(isPresented: $showHelp, arrowEdge: .top) {
                        VStack {
                            Text("Check out the [Machato FAQ](https://machato.app/faq)")
                                .fixedSize(horizontal: false, vertical: true).padding([.leading, .trailing])
                        }.frame(height: 40)
                    }
                Button {
                    hasLaunched = true
                    dismiss()
                } label: {
                    Text("Get started !")
                }.buttonStyle(.borderedProminent)
                    .disabled(!(profileStatus && gumroadStatus))
            }
        }
        .padding()
        .frame(width: 540)
        .background(.clear)
        .makeWindowFloat()
        .onAppear {
            if gumroadStatus {
                hasLaunched = true
                dismiss()
            }
        }
    }
}
