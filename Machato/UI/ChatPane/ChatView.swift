//
//  ChatView.swift
//  Machato
//
//  Created by Théophile Cailliau on 25/03/2023.
//

import SwiftUI
import CoreData

struct ChatView: View {
    @State private var message : String = "";
    @FetchRequest private var messages: FetchedResults<Message>;
    @Environment(\.managedObjectContext) var moc;
    private var convo : Conversation;
    private var onSend : ((Conversation, String) -> Void)?;
    private var onStopGenerating: ((Message) -> Void)? = nil;
    private var onMessageAction : ((ChatElementAction, Message) -> Void)? = nil;
    @Namespace var bottomID;
    private var lastMessageSize : Int {
        return messages.last?.content?.count ?? 0
    }
    @State private var lastSent: Message? = nil;
    @State private var editing: Bool = false;
    
    func updateLastSent() {
        lastSent = messages.filter { $0.is_response == false }.last;
    }
    
    var body: some View {
        VStack (alignment: .leading, spacing: 0) {
            ZStack (alignment: .bottomLeading){
                ScrollViewReader { sv in
                    ScrollView(.vertical) {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            // Text(convo.date.description)
                            Divider().padding([.bottom], 0)
                            ForEach(messages) { message in
                                ChatElement(message, allowEdit: message == lastSent, editing: $editing) { (action, message) in
                                    onMessageAction?(action, message)
                                    if [.regenerate, .delete].contains(action) {
                                        updateLastSent()
                                    }
                                }  .contextMenu {
                                    Button {
                                        if let om = onMessageAction { om(.delete, message) }
                                    } label: {
                                        Text("Delete")
                                    }
                                }
                            } .onChange(of: lastMessageSize) { _ in
                                sv.scrollTo(bottomID)
                            } .onChange(of: messages.count) { _ in
                                updateLastSent()
                            } .onAppear(perform: updateLastSent)
                        }
                        Spacer().id(bottomID).frame(maxWidth: .infinity, minHeight: 10, maxHeight: 10)
                    }.onAppear {
                        sv.scrollTo(bottomID)
                    }
                }
                HStack{
                    Spacer()
                    if let m = convo.last_message, m.is_finished == false, let cs = m.belongs_to_convo?.has_settings, cs.stream == true {
                        Button {
                            onStopGenerating?(m)
                        } label: {
                            Label("Stop generating", systemImage: "stop.fill").labelStyle(.titleAndIcon).foregroundColor(AppColors.redButtonForeground)
                        }
                        .buttonStyle(.borderless)
                        .padding(10)
                        .background(AppColors.redButtonBackground)
                        .cornerRadius(5) .zIndex(1)
                        .padding([.bottom], 10)
                        .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                    }
                    Spacer()
                }
            }
            Divider()
            if editing {
                Button {
                    editing = false
                    if let m = lastSent {
                        onMessageAction?(.regenerate, m)
                    }
                    updateLastSent()
                } label: {
                    Spacer()
                    Label("Send edit", systemImage: "paperplane").padding([.top, .bottom], 14)
                    Spacer()
                }
                .buttonStyle(.borderless)
                .background(.thickMaterial)
                .foregroundColor(AppColors.chatForegroundColor)
            } else {
                HStack {
                    
                    CustomTextField(string: $message, prompt: "Type your message", onSend: sendMessage)
                        .textFieldStyle(.plain)
                        .submitLabel(.send)
                        .onSubmit(sendMessage)
                        .padding([.top, .bottom], 14)
                        .scrollContentBackground(.hidden)
                        .background(AppColors.chatBackgroundColor)
                    Button() {
                        self.sendMessage()
                    } label: {
                        Label("Send", systemImage: "paperplane").labelStyle(.iconOnly)
                    } .buttonStyle(.borderless) .disabled(message.count == 0)
                }
                .padding([.leading, .trailing], 15)
                
            }
        }.background(AppColors.chatBackgroundColor)
    }
    
    func sendMessage() {
        if message.count == 0 {
            return
        }
        onSend?(self.convo, message)
        message = ""
    }
    
    init(_ ce: Conversation, onSend: ((Conversation, String) -> Void)? = nil, onMessageAction: ((ChatElementAction, Message) -> Void)? = nil, onStopGenerating : ((Message) -> Void)? = nil) {
        self.onSend = onSend;
        self.convo = ce;
        self.onStopGenerating = onStopGenerating
        _messages = FetchRequest(entity: Message.entity(),
                                 sortDescriptors: [NSSortDescriptor(keyPath: \Message.date, ascending: true)],
                                 predicate: NSPredicate(format: "%K == %@", #keyPath(Message.belongs_to_convo), ce as CVarArg),
                                 animation: .none)
        self.onMessageAction = onMessageAction
    }
}

struct CustomTextField: View {
    
    @Binding var string: String;
    @State var localString: String
    let prompt: String
    @FocusState var editorFocused: Bool?;
    private var send : () -> Void;
    
    init(string: Binding<String>, prompt: String, onSend: @escaping () -> Void) {
        _string = string
        _localString = State(initialValue: string.wrappedValue)
        self.prompt = prompt
        self.send = onSend
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: Binding {
                return localString
            } set: { v in
                guard v != "" else {
                    localString = ""
                    return
                }
                if v.last == "\n" && !isShiftKeyPressed() && v.count - localString.count == 1 {
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
                .font(.body)
                .multilineTextAlignment(.leading)
                .frame(minHeight: 15, maxHeight: 75)
                .fixedSize(horizontal: false, vertical: true)
                .focused($editorFocused, equals: true)
            Text(localString == "" ? prompt : localString)
                .padding(.leading, 4)
                .foregroundColor(Color(.placeholderTextColor))
                .opacity(localString == "" ? 1 : 0)
                .onTapGesture {
                    editorFocused = true
                }
                .lineLimit(2)
        }.defaultFocus($editorFocused, true)
    }
    
    func isShiftKeyPressed() -> Bool {
        let shiftKeyMask = NSEvent.ModifierFlags.shift
        let currentFlags = NSEvent.modifierFlags
        return currentFlags.contains(shiftKeyMask)
    }
}
