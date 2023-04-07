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
    private var onMessageAction : ((ChatElementAction, Message) -> Void)? = nil;
    @Namespace var bottomID;
    private var lastMessageSize : Int {
        return messages.last?.content?.count ?? 0
    }
    
    var body: some View {
        VStack (alignment: .leading) {
            ScrollViewReader { sv in
                ScrollView(.vertical) {
                    VStack(alignment: .leading) {
                        // Text(convo.date.description)
                        Divider()
                        ForEach(messages) { message in
                            ChatElement(message, onAction: onMessageAction)  .contextMenu {
                                Button {
                                    if let om = onMessageAction { om(.delete, message) }
                                } label: {
                                    Text("Delete")
                                }
                            }
                        } .onChange(of: lastMessageSize) { _ in
                            // withAnimation {
                                sv.scrollTo(bottomID)
                            // }
                        }
                    }
                    Spacer().id(bottomID).frame(maxWidth: .infinity, minHeight: 10, maxHeight: 10)
                }.onAppear {
                    sv.scrollTo(bottomID)
                }
                
            }
            Divider()
            HStack {
                CustomTextField(string: $message, prompt: "Type your message")
                    .textFieldStyle(.plain)
                    .submitLabel(.send)
                    .onSubmit(sendMessage)
                Button() {
                    self.sendMessage()
                } label: {
                    Label("Send", systemImage: "paperplane").labelStyle(.iconOnly)
                } .buttonStyle(.borderless) .disabled(message.count == 0)
            }
            .padding([.bottom, .leading, .trailing], 15)
            .padding([.top], 5)
        }.background(AppColors.chatBackgroundColor)
    }
    
    func sendMessage() {
        if message.count == 0 {
            return
        }
        if let os = onSend {
            os(self.convo, message)
        }
        message = ""
    }
    
    init(_ ce: Conversation, onSend: ((Conversation, String) -> Void)? = nil, onMessageAction: ((ChatElementAction, Message) -> Void)? = nil) {
        self.onSend = onSend;
        self.convo = ce;
        _messages = FetchRequest(entity: Message.entity(),
                                 sortDescriptors: [NSSortDescriptor(keyPath: \Message.date, ascending: true)],
                                 predicate: NSPredicate(format: "%K == %@", #keyPath(Message.belongs_to_convo), ce as CVarArg),
                                 animation: .none)
        self.onMessageAction = onMessageAction
    }
}

// hack because i didn't find a better fix to the cursor jumping around
struct CustomTextField: View {
    
    @Binding var string: String;
    @State var localString: String
    let prompt: String
    
    init(string: Binding<String>, prompt: String) {
        
        _string = string
        _localString = State(initialValue: string.wrappedValue)
        self.prompt = prompt
    }
    
    var body: some View {
        TextField(prompt, text: $localString, axis: .vertical)
            .onChange(of: localString) { _ in
                string = localString
            }
            .onChange(of: string) { nv in
                if nv.isEmpty {
                    localString = ""
                }
            }
    }
}
