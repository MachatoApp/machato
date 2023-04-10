//
//  ChatElement.swift
//  Machato
//
//  Created by Théophile Cailliau on 25/03/2023.
//

import SwiftUI
import LaTeXSwiftUI
import MarkdownUI
import Cocoa

enum ChatElementAction {
    case delete
    case copy
    case edit
    case branch
    case stop
    case regenerate
}

struct ChatElement: View {
    @State private var update : Int = 0;
    private var convoSettings: ConversationSettings;
    @StateObject private var message : Message;
    @State private var hovering : Bool = false;
    public var onAction : ((ChatElementAction, Message) -> Void)? = nil;
    @State private var copied : Bool = false;
    @State private var copyHover: Bool = false;
    @State private var deleteHover: Bool = false;
    @State private var branchHover: Bool = false;
    @ObservedObject private var pref = PreferencesManager.shared;
    private let allowEdit : Bool;
    @Binding private var editing : Bool;
    @State private var editHover : Bool = false;
    @State private var regenerateHover : Bool = false;

    @Environment(\.colorScheme) var colorScheme;
    
    // TODO: Temporary hack awaiting latex-swuiftui patch
    var messageContentLatexPatched : String {
        guard var m = message.content else { return "" }
        m.replace(#/\$\$\n/#) { _ in "$$" }
        m.replace(#/\\\[\n/#) { _ in "\\[" }
        m.replace(#/\n\\\]/#) { _ in "\\]" }
        m.replace(#/\n\$\$/#) { _ in "$$" }
        m.replace(#/\\\(|\\\)/#) { _ in "$" }
        return m
    }
    
    @ViewBuilder
    var contentView: some View {
        if editing && allowEdit {
            TextEditor(text: Binding {
                return message.content ?? ""
            } set: { msg in message.content = msg})
            .font(.system(size: pref.fontSize))
        } else {
            switch convoSettings.typeset {
            case .markdown:
                Markdown(message.content ?? "").padding(10).textSelection(.enabled).id(update)
                    .markdownCodeSyntaxHighlighter(HighlightrSyntaxHighlighter.shared).markdownBlockStyle(\.codeBlock) { config in
                        config.label.padding([.leading, .trailing], 15).padding([.bottom], 15).padding([.top], 15)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .markdownTextStyle {
                        FontSize(pref.fontSize)
                    } .onChange(of: pref.fontSize) { _ in
                        update += 1
                    }
            case .plain:
                Text(message.content ?? "").padding(10).textSelection(.enabled).id(update)
                    .font(.system(size: pref.fontSize))
                
            case .mathjax:
                LaTeX(messageContentLatexPatched, scale: pref.fontSize/13).padding(10).textSelection(.enabled).id(update)
                    .foregroundColor(AppColors.chatForegroundColor)
                    .parsingMode(.onlyEquations)
                    .errorMode(.original)
                    .font(.system(size: pref.fontSize))
                
            }
        }
    }
    
    var body: some View {
        VStack (spacing: 0){
            ZStack(alignment: .bottomTrailing) {
                // TODO: change icon alignment to .top and ajust padding values accordingly
                HStack(alignment: .top) {
                    if message.is_response {
                        if message.is_finished {
                            Image(systemName: "arrowshape.turn.up.left.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 15*pref.fontSize/13, height: 15*pref.fontSize/13)
                                .padding(10).padding([.top], 1)
                        } else {
                            ProgressView().scaleEffect(0.5).padding([.leading, .trailing], 3).padding([.bottom, .top], 2)
                        }
                    } else {
                        Image(systemName: "arrowshape.right.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 15*pref.fontSize/13, height: 15*pref.fontSize/13)
                            .padding(10).padding([.top], 1)
                    }
                    if message.is_error {
                        Markdown(message.content ?? "").padding(10).textSelection(.enabled).id(update).markdownBlockStyle(\.codeBlock) { config in
                            config.label.markdownTextStyle {
                                FontFamilyVariant(.monospaced)
                                ForegroundColor(.red)
                            }.background(.red.opacity(0.25))
                        }.markdownTextStyle(\.text) {
                            ForegroundColor(.red)
                        }
                    } else {
                        contentView
                    }
                    Spacer()
                } .onChange(of: colorScheme) { nv in
                    Task {
                        try await Task.sleep(for: .milliseconds(100))
                        update += 1
                    }
                }.padding([.top, .bottom], 5)
                    .background(message.is_response ? AppColors.receivedMessageBackground : AppColors.sentMessageBackground)
                HStack {
                    if allowEdit {
                        Button {
                            self.editing.toggle()
                            if editing == false {
                                onAction?(.regenerate, message)
                            }
                        } label: {
                            Image(systemName: "pencil")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 15, height: 15)
                                .padding(5)
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(AppColors.chatForegroundColor)
                        .background(editHover ? AppColors.chatButtonBackgroundHover : AppColors.chatButtonBackground)
                        .cornerRadius(5)
                        .opacity(hovering ? 1 : 0)
                        .onHover { b in
                            self.editHover = b
                        }
                        Button {
                            onAction?(.regenerate, message)
                        } label: {
                            Image(systemName: "arrow.2.squarepath")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 15, height: 15)
                                .padding(5)
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(AppColors.chatForegroundColor)
                        .background(regenerateHover ? AppColors.chatButtonBackgroundHover : AppColors.chatButtonBackground)
                        .cornerRadius(5)
                        .opacity(hovering ? 1 : 0)
                        .onHover { b in
                            self.regenerateHover = b
                        }
                    }
                    //Spacer()
                    Button {
                        onAction?(.branch, message)
                    } label: {
                        Image(systemName: "arrow.triangle.branch")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 15, height: 15)
                            .padding(5)
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(AppColors.chatForegroundColor)
                    .background(branchHover ? AppColors.chatButtonBackgroundHover : AppColors.chatButtonBackground)
                    .cornerRadius(5)
                    .opacity(hovering ? 1 : 0)
                    .onHover { b in
                        self.branchHover = b
                    }
#if os(macOS)
                    Button {
                        onAction?(.copy, message)
                        copied = true
                        Task {
                            try await Task.sleep(for: .seconds(2))
                            copied = false
                        }
                        
                    } label: {
                        Image(systemName: copied ? "checkmark" : "list.clipboard")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 15, height: 15)
                            .padding(5)
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(AppColors.chatForegroundColor)
                    .background(copyHover ? AppColors.chatButtonBackgroundHover : AppColors.chatButtonBackground)
                    .cornerRadius(5)
                    .disabled(copied)
                    .opacity(hovering ? 1 : 0)
                    .onHover { b in
                        self.copyHover = b
                    }
#endif
                    Button {
                        onAction?(.delete, message)
                    } label: {
                        Image(systemName: "trash")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 15, height: 15)
                            .padding(5)
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(AppColors.deleteButtonForeground)
                    .background(deleteHover ? AppColors.chatButtonBackgroundHover : AppColors.chatButtonBackground)
                    .cornerRadius(5)
                    .opacity(hovering ? 1 : 0)
                    .padding([.trailing], 20)
                    .onHover { b in
                        self.deleteHover = b
                    }
                    
                } .padding([.bottom], 10)
            } .onHover { over in
                hovering = over
            }
            Divider()
        }
    }
    
    init(_ m: Message, allowEdit: Bool, editing: Binding<Bool>, onAction: ((ChatElementAction, Message) -> Void)? = nil) {
        _message = StateObject(wrappedValue: m)
        self.onAction = onAction
        if let c = m.belongs_to_convo {
            convoSettings = PreferencesManager.getConversationSettings(c)
        } else {
            convoSettings = ConversationSettings()
        }
        self.allowEdit = allowEdit
        _editing = editing
    }
}
