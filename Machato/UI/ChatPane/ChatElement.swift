//
//  ChatElement.swift
//  Machato
//
//  Created by Théophile Cailliau on 25/03/2023.
//

import SwiftUI
import LaTeXSwiftUI
import MarkdownUI

enum ChatElementAction {
    case delete
    case copy
    case edit
    case branch
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
        switch convoSettings.typeset {
        case .markdown:
            Markdown(message.content ?? "").padding(10).textSelection(.enabled).id(update)
                .markdownCodeSyntaxHighlighter(HighlightrSyntaxHighlighter.shared).markdownBlockStyle(\.codeBlock) { config in
                    config.label.padding([.leading, .trailing], 15).padding([.bottom], 25).padding([.top], 15)
                }
        case .plain:
            Text(message.content ?? "").padding(10).textSelection(.enabled).id(update)
        case .mathjax:
            LaTeX(messageContentLatexPatched).padding(10).textSelection(.enabled).id(update)
                .foregroundColor(AppColors.chatForegroundColor)
                .parsingMode(.onlyEquations)
                .errorMode(.error)
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // TODO: change icon alignment to .top and ajust padding values accordingly
            HStack(alignment: .top) {
                if message.is_response {
                    if message.is_finished {
                        Label("Received", systemImage: "arrowshape.turn.up.left.fill").labelStyle(.iconOnly) .padding(10).padding([.top], 1)
                    } else {
                        ProgressView().scaleEffect(0.5).padding([.leading, .trailing], 3).padding([.bottom, .top], 2)
                    }
                } else {
                    Label("Sent", systemImage: "arrowshape.right.fill").labelStyle(.iconOnly) .padding(10) .padding([.top], 1)
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
            }
            HStack {
                //Spacer()
                Button {
                    if let oa = onAction {
                        oa(.branch, message)
                    }
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
                    if let oa = onAction {
                        oa(.copy, message)
                        copied = true
                        Task {
                            try await Task.sleep(for: .seconds(2))
                            copied = false
                        }
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
                    if let oa = onAction {
                        oa(.delete, message)
                    }
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

            }
        } .onHover { over in
            hovering = over
        }
        
        Divider()
    }
    
    init(_ m: Message, onAction: ((ChatElementAction, Message) -> Void)? = nil) {
        _message = StateObject(wrappedValue: m)
        self.onAction = onAction
        if let c = m.belongs_to_convo {
            convoSettings = PreferencesManager.getConversationSettings(c)
        } else {
            convoSettings = ConversationSettings()
        }
    }
}
