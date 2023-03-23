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

struct ChatElement: View, Equatable {
    fileprivate var finished: Bool;
    fileprivate var id : UUID;

    static func == (lhs: ChatElement, rhs: ChatElement) -> Bool {
        return lhs.finished == rhs.finished &&
            lhs.id == rhs.id &&
            lhs.allowEdit == rhs.allowEdit
    }
    
    @AppStorage(PreferencesManager.StoredPreferenceKey.useServiceIcons) var useServiceIcons : Bool = true;
    @State private var update : Bool = false;
    private var convoSettings: ConversationSettings;
    @StateObject private var message : Message;
    @State private var hovering : Bool = false;
    public var onAction : ((ChatElementAction, Message) -> Void) = DataActions.shared.onMessageAction(_:_:);
    @State private var copied : Bool = false;
    @State private var copyHover: Bool = false;
    @State private var deleteHover: Bool = false;
    @State private var branchHover: Bool = false;
    @State private var collapseHover: Bool = false;
    @State private var excludeHover : Bool = false;
    @ObservedObject private var pref = PreferencesManager.shared;
    
    fileprivate let allowEdit : Bool;
    @Binding private var editing : Bool;
    @State private var editHover : Bool = false;
    @State private var regenerateHover : Bool = false;
    @State private var selfHeight : Double = .zero;
    @Binding private var collapsed : Bool;
    
    @Environment(\.managedObjectContext) var moc;

    private var chatButtonBackground : Color;
    
    private var backgroundColor : some View {
        message.is_function ? message.is_finished ? message.is_error ? Color.red.opacity(0.1).background(AppColors.chatBackgroundColor) : Color.green.opacity(0.1).background(AppColors.chatBackgroundColor) : Color.yellow.opacity(0.1).background(AppColors.chatBackgroundColor)
        : message.is_response ? AppColors.receivedMessageBackground.background(AppColors.chatBackgroundColor) : AppColors.sentMessageBackground.background(AppColors.chatBackgroundColor)
    }
        
    @FocusState private var editFocus;
    
    @Environment(\.colorScheme) var colorScheme;
    
    @ViewBuilder
    var contentView: some View {
        if editing && allowEdit {
            TextEditor(text: Binding {
                return message.content ?? ""
            } set: { msg in message.content = msg})
            .font(.system(size: pref.fontSize))
            .focused($editFocus, equals: true)
            .onAppear() {
                Task {
                    try? await Task.sleep(for: .milliseconds(10))
                    editFocus = true
                }
            }
            Button {
                editing = false
            } label: {EmptyView()}.buttonStyle(.borderless).keyboardShortcut(.escape, modifiers: [])
        } else {
            if message.is_function {
                FunctionContent(message: message, $collapsed).opacity(message.include_in_requests ? 1 : 0.5)
            } else {
                ChatElementContent(message.content ?? "", !message.is_finished, collapsed, convoSettings.typeset, message.include_in_requests, $selfHeight)
                    .equatable()
                    .onAppear() {
                        collapsed = message.collapsed
                    }
            }
        }
    }
    
    var body: some View {
#if DEBUG
        //        if message.content?.hasPrefix("You can use") ?? false {
        //            let _ = Self._printChanges()
        //        }
#endif
        VStack (spacing: 0) {
            ZStack(alignment: .top) {
                HStack(alignment: .center) {
                    Group {
                        if message.is_function {
                            Image(systemName: "f.cursive")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 15*pref.fontSize/13, height: 15*pref.fontSize/13)
                                .padding([.leading, .trailing], 10)
                                .foregroundColor(message.is_error ? .red : .primary)
                        } else if message.is_response {
                            if message.is_finished {
                                if !useServiceIcons {
                                    Image(systemName: "bubbles.and.sparkles")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 15*pref.fontSize/13, height: 15*pref.fontSize/13)
                                        .padding(10)
                                } else {
                                    Image(convoSettings.model.type?.rawValue ?? "openai")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 15*pref.fontSize/13, height: 15*pref.fontSize/13)
                                        .padding(10)
                                }
                            } else {
                                ProgressView().scaleEffect(0.5).frame(width: 15*pref.fontSize/13).padding([.leading, .trailing], 10).padding([.bottom, .top], 2)
                            }
                        } else {
                            Image(systemName: "arrowshape.right.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 15*pref.fontSize/13, height: 15*pref.fontSize/13)
                                .padding(10)
                        }
                    }.opacity(message.include_in_requests ? 1 : 0.4)
                    if message.is_error && !message.is_function {
                        Markdown(message.content ?? "").padding(10).textSelection(.enabled).id(update).markdownBlockStyle(\.codeBlock) { config in
                            config.label.markdownTextStyle {
                                FontFamilyVariant(.monospaced)
                                ForegroundColor(.red)
                            }.background(.red.opacity(0.25)).padding([.leading, .trailing], 15).padding([.bottom], 20).padding([.top], 8)
                        }.markdownTextStyle(\.text) {
                            ForegroundColor(.red)
                        }.markdownTextStyle(\.link) {
                            UnderlineStyle(.single)
                        }
                    } else {
                        contentView
                    }
                    Spacer()
                } .onChange(of: colorScheme) { nv in
                    Task {
                        try await Task.sleep(for: .milliseconds(100))
                        update.toggle()
                    }
                }.zIndex(0)
                    .padding([.top, .bottom], 5)
                    .frame(maxWidth: pref.narrowMessages ? PreferencesManager.shared.maxWidth : nil)
                HStack(spacing: 0) {
                    Spacer()
                    if message.is_finished {
                        if pref.messageTimestamp {
                            HStack {
                                Text(message.date?.formatted(.dateTime) ?? "").opacity(0.5).padding([.trailing, .leading], 5)
                                    .frame(height: 25)
                            }.zIndex(2)
                                .padding(3)
                                .padding([.leading, .trailing], 1)
                                .background(backgroundColor.opacity(hovering ? 1 : 0))
                                .opacity((hovering) ? 1 : 0)
                                .cornerRadius(7)
                                .background(RoundedRectangle(cornerRadius: 7).trim(from: 0.5, to: 1).stroke(.gray).opacity(hovering ? 0.4 : 0), alignment: .bottom)
                                .padding([.trailing, .leading], 5)
                        }
                        HStack {
                            
                            if pref.allowMessageExclusion {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        message.include_in_requests.toggle()
                                        message.belongs_to_convo?.countTokens()
                                    }
                                } label: {
                                    Image(systemName: message.include_in_requests ? "minus.square"
                                          : "plus.square")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 15, height: 15)
                                    .padding(5)
                                }
                                .buttonStyle(.borderless)
                                .foregroundColor(AppColors.chatForegroundColor)
                                .background(excludeHover ? AppColors.chatButtonBackgroundHover : chatButtonBackground)
                                .cornerRadius(5)
                                .onHover { b in
                                    self.excludeHover = b
                                }
                                .help(message.include_in_requests ? "Exclude in requests" : "Include in requests")
                            }
                            if collapsed || selfHeight > pref.fontSize * 4 || message.is_function {
                                Button {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        collapsed.toggle()
//                                        message.collapsed = collapsed
                                        try? moc.save()
                                    }
                                } label: {
                                    Image(systemName: collapsed ? "arrow.up.and.line.horizontal.and.arrow.down"
                                          : "arrow.down.and.line.horizontal.and.arrow.up")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 15, height: 15)
                                    .padding(5)
                                }
                                .buttonStyle(.borderless)
                                .foregroundColor(AppColors.chatForegroundColor)
                                .background(collapseHover ? AppColors.chatButtonBackgroundHover : chatButtonBackground)
                                .cornerRadius(5)
                                .onHover { b in
                                    self.collapseHover = b
                                }
                                .help(collapsed ? "Expand" : "Collapse")
                            }
                            if allowEdit {
                                Button {
                                    self.editing.toggle()
                                    if editing == false {
                                        DataActions.shared.onMessageAction(.regenerate, message)
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
                                .background(editHover ? AppColors.chatButtonBackgroundHover : chatButtonBackground)
                                .cornerRadius(5)
                                .onHover { b in
                                    self.editHover = b
                                }
                                .help("Edit")
                                Button {
                                    DataActions.shared.onMessageAction(.regenerate, message)
                                } label: {
                                    Image(systemName: "arrow.2.squarepath")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 15, height: 15)
                                        .padding(5)
                                }
                                .buttonStyle(.borderless)
                                .keyboardShortcut("R", modifiers: .command)
                                .foregroundColor(AppColors.chatForegroundColor)
                                .background(regenerateHover ? AppColors.chatButtonBackgroundHover : chatButtonBackground)
                                .cornerRadius(5)
                                .onHover { b in
                                    self.regenerateHover = b
                                }
                                .help("Re-generate")
                            }
                            //Spacer()
                            Button {
                                DataActions.shared.onMessageAction(.branch, message)
                                // TODO: select convo
                            } label: {
                                Image(systemName: "arrow.triangle.branch")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 15, height: 15)
                                    .padding(5)
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(AppColors.chatForegroundColor)
                            .background(branchHover ? AppColors.chatButtonBackgroundHover : chatButtonBackground)
                            .cornerRadius(5)
                            .onHover { b in
                                self.branchHover = b
                            }
                            .help("Branch from here")
#if os(macOS)
                            Button {
                                DataActions.shared.onMessageAction(.copy, message)
                                copied = true
                                Task {
                                    try await Task.sleep(for: .seconds(2))
                                    copied = false
                                }
                                
                            } label: {
                                Image(systemName: copied ? "checkmark" : "doc.on.clipboard")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 15, height: 15)
                                    .padding(5)
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(AppColors.chatForegroundColor)
                            .background(copyHover ? AppColors.chatButtonBackgroundHover : chatButtonBackground)
                            .cornerRadius(5)
                            .disabled(copied)
                            .onHover { b in
                                self.copyHover = b
                            }
                            .help("Copy")
#endif
                            Button {
                                DataActions.shared.onMessageAction(.delete, message)
                            } label: {
                                Image(systemName: "trash")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 15, height: 15)
                                    .padding(5)
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(AppColors.deleteButtonForeground)
                            .background(deleteHover ? AppColors.chatButtonBackgroundHover : chatButtonBackground)
                            .cornerRadius(5)
                            .onHover { b in
                                self.deleteHover = b
                            }
                            .help("Delete")
                        }.zIndex(2)
                            .padding(3)
                            .padding([.leading, .trailing], 1)
                            .background(backgroundColor.opacity(hovering ? 1 : 0))
                            .opacity((hovering) ? 1 : 0)
                            .cornerRadius(7)
                            .background(RoundedRectangle(cornerRadius: 7).trim(from: 0.5, to: 1).stroke(.gray).opacity(hovering ? 0.4 : 0), alignment: .bottom)
                        Spacer().frame(width: 10)
                    }
                } .padding([.top], -15.5)
            }
            .onHover { over in
                withAnimation(Animation.easeInOut(duration: 0.15)) {
                    hovering = over
                }
            }.background(backgroundColor)
            
                
            Divider()
//                .tint(.clear)
//                .frame(height: 0.5)
//                .overlay(.gray.opacity(0.6))
                .zIndex(-1)
        }
    }
    
    init(_ m: Message, allowEdit: Bool, editing: Binding<Bool>) {
        _message = StateObject(wrappedValue: m)
        if let c = m.belongs_to_convo {
            convoSettings = PreferencesManager.getConversationSettings(c)
        } else {
            convoSettings = ConversationSettings(csEntity: nil)
        }
        self.allowEdit = allowEdit
        _editing = editing
        finished = m.is_finished
        id = m.id ?? UUID()
        chatButtonBackground = m.is_response ? AppColors.sentMessageBackground : AppColors.receivedMessageBackground
        _collapsed = Binding {
            m.collapsed
        } set: { v in
            m.collapsed = v
        }
    }
}
