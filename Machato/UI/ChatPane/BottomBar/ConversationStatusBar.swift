//
//  ConversationStatusBar.swift
//  Machato
//
//  Created by Théophile Cailliau on 17/05/2023.
//

import SwiftUI

fileprivate typealias Field = ConversationSpecificSettings.Fields


struct ConversationStatusBar: View {
    @StateObject var convo : Conversation;
    @Environment(\.openWindow) var openWindow;

    @ObservedObject var convoSettingsObject : ConversationSettings;
    @ObservedObject var modelManager = ModelManager.shared;
    
    var body: some View {
        VStack (spacing: 0) {
            Divider().background(
                AppColors.chatBackgroundColor // any non-transparent background
                    .shadow(color: AppColors.chatForegroundColor, radius: 10, x: 0, y: 0)
                    .mask(Rectangle().padding(.top, -20))
            )
            if showSecondaryBar {
                    HStack {
                        Spacer()
                        Divider()
                        top_p; presence_penalty; frequency_penalty; max_tokens; functions; temperature; model; typeset
                    }.frame(height: 18)
                Divider()
            }
            HStack {
                Button {
                    openWindow(id: "prompt-library")
                } label: {
                    Label("Prompt library", systemImage: "tray.full").labelStyle(.titleAndIcon)
                }.buttonStyle(.borderless).fixedSize()
                Divider()
                Spacer()
                Divider()
                if let m = convo.last_message, m.is_finished == false, convo.settings.stream {
                    Button {
                        DataActions.shared.onMessageAction(.stop, m)
                    } label: {
                        Label("Stop", systemImage: "square.fill").labelStyle(.titleAndIcon)
                    }.buttonStyle(.borderless)
                        .foregroundColor(.red).fixedSize()
                    Divider()
                }
                Group {
                    Group {
                        convoSettings
                        ViewThatFits {
                            Text("\(convo.has_messages?.count ?? 0) messages").opacity(0.5).fixedSize()
                            Text("m:\(convo.has_messages?.count ?? 0)").opacity(0.5).fixedSize()
                        }.help("Number of messages in this conversation")
                        Divider()
                    }
                    HStack(spacing: 0) {
                        Text("\(convo.tokens - convo.excluded_tokens)").font(.subheadline.monospaced()).fixedSize()
                        Text(convo.excluded_tokens > 0 ? " (+ \(convo.excluded_tokens))" : "").font(.subheadline.monospaced()).opacity(0.5).fixedSize()
                        Text(" tokens").fixedSize()
                    }.opacity(0.5).fixedSize()
                        .help("Number of tokens in context (+ excluded tokens)")
                    Divider()
                    Text("\(convo.settings.model.contextLength / 1000)k context").opacity(0.5).fixedSize()
                        .help("The model's context length (in tokens)")
                    HStack(spacing: 0) {
                        Divider()
                        let per = min(1, max(0, Double(convo.tokens - convo.excluded_tokens) / Double(convo.settings.model.contextLength)))
                        ZStack(alignment: .bottomLeading) {
                            Spacer().background(GeometryReader { geo in
                                Rectangle()
                                    .foregroundColor(per < 0.7 ? .green : per < 0.9 ? .yellow : .red)
                                    .frame(width: per*geo.size.width, height: 18)
                                    .opacity(0.1)
                                    .transition(AnyTransition.scale)
                                    .animation(.easeInOut(duration: 0.5), value: per)
                            })
                            (Text("\(convo.settings.model.contextLength - convo.tokens + convo.excluded_tokens)").font(.subheadline.monospaced()) + Text(" remaining")).opacity(0.5).fixedSize()
                                .help("Remaining tokens in the model's context window").frame(height: 18).padding([.leading, .trailing], 5)
                        }
                    }
                }
            }.padding([.leading], 5).frame(height: 18)
            //Divider()
        }.font(.subheadline)
    }
    
    @ViewBuilder
    var convoSettings : some View {
        ViewThatFits {
            if !showSecondaryBar {
                HStack { top_p; presence_penalty; frequency_penalty; max_tokens; functions; temperature; model; typeset }
                HStack { moreButton; presence_penalty; frequency_penalty; max_tokens; functions; temperature; model; typeset }
                HStack { moreButton; frequency_penalty; max_tokens; functions; temperature; model; typeset }
                HStack { moreButton; top_p; max_tokens; functions; temperature; model; typeset }
                HStack { moreButton; max_tokens; functions; temperature; model; typeset }
                HStack { moreButton; functions; temperature; model; typeset }
                HStack { moreButton; temperature; model; typeset }
                HStack { moreButton; model; typeset }
                HStack { moreButton; model }
            }
            HStack { moreButton }
        }
    }
    
    @State var showSecondaryBar : Bool = false;
    @Namespace var labelId;
    
    @ViewBuilder
    var moreButton : some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                showSecondaryBar.toggle()
            }
        } label: {
            Label("Conversation settings", systemImage: "chevron.right.2")
                .id(labelId)
                .rotationEffect(Angle.degrees(90 * (showSecondaryBar ? 1 : -1))).labelStyle(.iconOnly)
                .animation(.easeInOut(duration: 0.2), value: showSecondaryBar)
        }.buttonStyle(.borderless).help("Conversation settings")
        Divider()
    }
        
    @State fileprivate var tooltip : Field? = nil
    
    @ViewBuilder
    var max_tokens : some View {
        Text("m_t:\(convo.settings.manageMax ? "auto" : convo.settings.maxTokens.description)")
            .convoSettingsSection(field: .max_tokens, tooltip: $tooltip, convo: convo)
        Divider()
    }
    
    @ViewBuilder
    var top_p : some View {
        Text("top_p:\(convo.settings.topP.description)")
            .convoSettingsSection(field: .top_p, tooltip: $tooltip, convo: convo)
        Divider()
    }

    @ViewBuilder
    var presence_penalty : some View {
        Text("p_p:\(convo.settings.presencePenalty.description)")
            .convoSettingsSection(field: .presence_penalty, tooltip: $tooltip, convo: convo)
        Divider()
    }
    
    @ViewBuilder
    var frequency_penalty : some View {
        Text("f_p:\(convo.settings.frequencyPenalty.description)")
            .convoSettingsSection(field: .frequency_penalty, tooltip: $tooltip, convo: convo)

        Divider()
    }
    
    @ViewBuilder
    var functions : some View {
        if convo.settings.model.supportsFunctions {
            Text("𝑓:\(convo.settings.enabledFunctions.count)")
                .convoSettingsSection(field: .functions, tooltip: $tooltip, convo: convo)
            Divider()
        }
    }

    
    @ViewBuilder
    var model : some View {
        let menu = Menu {
            ForEach(modelManager.availableModels) { model in
                Button(model.name) {
                    convo.settings.model = model
                }
            }
            Divider()
            Button("New model...") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                Signals.shared.selectKeysTab()
            }
        } label: {
            let t = Text("\(convo.settings.model.name.lowercased())").font(.subheadline)
            if case .none = convo.settings.model {
                t.foregroundColor(.red).bold().underline()
            } else {
                t
            }
        }.menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
        if case .none = convo.settings.model {
            menu
        } else {
            menu.opacity(0.5)
        }

        Divider()
    }
    
    @ViewBuilder
    var typeset : some View {
        Menu {
            ForEach(TypesetFunctionality.allCases) { typeset in
                Button(typeset.description) {
                    convo.settings.typeset = typeset
                }
            }
        } label: {
            Text("\(convo.settings.typeset.description.lowercased())").font(.subheadline)
        }.menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize().opacity(0.5)
        Divider()
    }
    
    @ViewBuilder
    var temperature : some View {
        Text("t:\(convo.settings.temperature.description)")
            .convoSettingsSection(field: .temperature, tooltip: $tooltip, convo: convo)
        Divider()
    }
        
    init(convo: Conversation) {
        self._convo = StateObject(wrappedValue: convo)
        _convoSettingsObject = ObservedObject(initialValue: convo.settings)
    }
}

fileprivate extension View {
    func convoSettingsSection(field f: Field, tooltip: Binding<Field?>, convo: Conversation) -> some View {
        self.font(.subheadline.monospaced()).opacity(0.5).fixedSize().help("This conversation's \(f.rawValue) value")
            .onTapGesture {
                tooltip.wrappedValue = f
            }
            .popover(isPresented: Binding {
                tooltip.wrappedValue == f
            } set: { v in
                tooltip.wrappedValue = v ? f : nil
            }) {
                ConversationSpecificSettings(forConvo: convo, fields: [f])
                    .environmentObject(convo.settings)
            }
    }
}
