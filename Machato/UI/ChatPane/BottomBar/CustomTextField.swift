//
//  CustomTextField.swift
//  Machato
//
//  Created by Théophile Cailliau on 14/04/2023.
//

import Foundation
import SwiftUI
import Combine


struct CustomTextField: View {
    
    @Binding var string: String;
    @State private var localString: String
    let prompt: String
    @FocusState var editorFocused: Bool?;
    private var send : @MainActor () -> Void;
    @AppStorage(PreferencesManager.StoredPreferenceKey.sendWithShiftEnter) var sendWithShiftEnter : Bool = false;
    @Binding var editing : Bool;
    @State var texteditorHeight : CGFloat = .zero;
    
    init(string: Binding<String>, prompt: String, onSend: @escaping @MainActor () -> Void, editing: Binding<Bool>) {
        _string = string
        _localString = State(initialValue: string.wrappedValue)
        self.prompt = prompt
        self.send = onSend
        self._editing = editing
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if localString.isEmpty {
                Button {
                    editing = true
                } label: {
                    EmptyView()
                }.buttonStyle(.borderless)
                    .keyboardShortcut(.upArrow, modifiers: [])
            }
            Button {
                editorFocused = true
            } label: {
                EmptyView()
            }.buttonStyle(.borderless)
                .keyboardShortcut("I", modifiers: .command)
            Text(localString == "" ? prompt : "")
                .padding(.leading, 4)
                .foregroundColor(Color(.placeholderTextColor))
                .opacity(localString == "" ? 1 : 0)
                .onTapGesture {
                    editorFocused = true
                }
                .font(.system(size: PreferencesManager.shared.fontSize))
                .lineLimit(1)
            TextEditor(text: Binding {
                return localString
            } set: { v in
                guard v != "" else {
                    localString = ""
                    return
                }
                let condition = v.last == "\n" && v.count - localString.count == 1
                if condition && ((sendWithShiftEnter && isShiftKeyPressed()) || (!sendWithShiftEnter && !isShiftKeyPressed())) {
                    self.send()
                } else {
                    localString = v
                }
            })
            .onChange(of: localString) { _ in
                string = localString
            }
            .onChange(of: string) { nv in
                if nv.isEmpty {
                    localString = ""
                }
            }
            .font(.system(size: PreferencesManager.shared.fontSize))
            .multilineTextAlignment(.leading)
            .frame(minHeight: 15, maxHeight: 75*3)
            .fixedSize(horizontal: false, vertical: true)
            .focused($editorFocused, equals: true)
            .focusable()
            .touchBar {
                Button {
                    self.send()
                } label: {
                    Label("Send", systemImage: "paperplane.fill").labelStyle(.titleAndIcon).padding([.leading, .trailing], 10)
                }
            }
        }
        .defaultFocus($editorFocused, true)
        .task {
            editorFocused = true
        }
        .onReceive(PromptSelectionSingleton.shared.promptPublisher) { s in
            localString = s
        }
    }
    
    func isShiftKeyPressed() -> Bool {
        let shiftKeyMask = NSEvent.ModifierFlags.shift
        let currentFlags = NSEvent.modifierFlags
        return currentFlags.contains(shiftKeyMask)
    }
}
