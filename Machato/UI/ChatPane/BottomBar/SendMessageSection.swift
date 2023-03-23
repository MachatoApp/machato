//
//  SendMessageSection.swift
//  Machato
//
//  Created by Théophile Cailliau on 23/05/2023.
//

import SwiftUI
import AlertToast

struct SendMessageSection: View {
    
    @Binding var editing : Bool;
    @State var message : String = "";
    var current : Conversation;
    @State private var showToast : Bool = false;
    @State private var toastText : String  = "";
    var isGenerating : Bool {
        current.last_message?.is_finished == false
    }
    
    @AppStorage(PreferencesManager.StoredPreferenceKey.hideTokenCount) var hideTokenCount : Bool = false;
    
    @State private var countTokensTask : Task<Void, Error>? = nil;
    @State private var tokenCount : Int = 0;
    
    
    @MainActor
    func sendMessage() {
        guard isGenerating == false else {
            print("Attempting to send while previous message is still being generated")
            toastText = "Can't send while generating"
            showToast = true
            return
        }
        if message.count == 0 {
            return
        }
        DataActions.shared.onSend(conversation: current, messageString: message)
        message = ""
    }
        
    @MainActor
    func countTokens() {
        countTokensTask?.cancel()
        countTokensTask = Task.detached {
            if !message.isEmpty {
                try await Task.sleep(until: .now + .seconds(0.5), clock: .continuous)
            }
            try Task.checkCancellation()
            let count = Int(TokenCounter.shared.countTokens(message))
            DispatchQueue.main.async {
                tokenCount = count
            }
        }
    }
    
    var lastSent : Message? {
        current.has_messages?.sortedArray(using: [NSSortDescriptor(keyPath: \Message.date, ascending: true)]).filter { ($0 as? Message)?.is_response == false && ($0 as? Message)?.is_function == false }.last as? Message
    }
    
    var body: some View {
        VStack (spacing: 0) {
            Divider()
            if editing {
                Button {
                    editing = false
                    if let m = lastSent {
                        DataActions.shared.onMessageAction(.regenerate, m)
                    }
                } label: {
                    Spacer()
                    Label("Send edit", systemImage: "paperplane").padding([.top, .bottom], 14)
                    Spacer()
                }
                .buttonStyle(.borderless)
                .background(.thickMaterial)
                .foregroundColor(AppColors.chatForegroundColor)
                .keyboardShortcut(.return, modifiers: .command)
                .help("Send edit (Cmd+Return)")
                // .disabled(isGenerating)
            } else {
                HStack {
                    CustomTextField(string: $message, prompt: "Type your message", onSend: sendMessage, editing: $editing)
                        .textFieldStyle(.plain)
                        .submitLabel(.send)
                        .padding([.top, .bottom], 14)
                        .scrollContentBackground(.hidden)
                        .background(AppColors.chatBackgroundColor)
                        .toast(isPresenting: $showToast, duration: 2) {
                            AlertToast(displayMode: .banner(.pop), type: .regular, title: toastText)
                        }

                    if !hideTokenCount {
                        Text(tokenCount.description)
                            .foregroundColor(.gray)
                            .onChange(of: message) { _ in
                                countTokens()
                            }
                            .help("Tokens in your message")
                        
                    }
                    Button() {
                        self.sendMessage()
                    } label: {
                        VStack {
                            Image(systemName: "paperplane")
                            Text("⌘+⏎").font(.subheadline).foregroundColor(.gray.opacity(0.5))
                        }
                    } .buttonStyle(.borderless) .disabled(message.count == 0)
                        .keyboardShortcut(.return, modifiers: .command)
                }
                .padding([.leading, .trailing], 15)
            }
        }
    }
}
