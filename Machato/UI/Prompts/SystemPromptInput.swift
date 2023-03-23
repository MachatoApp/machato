//
//  SwiftUIView.swift
//  Machato
//
//  Created by Théophile Cailliau on 25/04/2023.
//

import SwiftUI

struct SystemPromptInputView: View {
    
    @Binding var convoid : UUID?;
    @Environment(\.managedObjectContext) private var moc;
    
    @State private var convo : Conversation? = nil
    @State private var settings : ConversationSettings? = nil;
    @State private var showPlaceholder : Bool = false
    
    @State var update : Bool = false;
    
    var body: some View {
        VStack {
            ZStack (alignment: .topLeading){
                
                TextEditor(text: Binding(get: {
                    guard convoid != nil else {
                        return PreferencesManager.shared.defaultPrompt
                    }
                    return settings?.prompt ?? ""
                }, set: { v in
                    guard convoid != nil else {
                        PreferencesManager.shared.defaultPrompt = v
                        return
                    }
                    settings?.prompt = v
                    settings?.save()
                    showPlaceholder = v.isEmpty
                })).id(update)
                
                .frame(height: 100)
                .font(.body)
                .padding(15)
                Text("Write your prompt...")
                    .foregroundColor(.gray)
                    .opacity(showPlaceholder ? 1 : 0)
                    .padding([.leading], 5)
                    .padding([.leading, .top], 15)
            }
            //            Divider()
            PromptLibrary(system: true)
                .onReceive(PromptSelectionSingleton.shared.systemPublisher) { s in
                    settings?.prompt = s
                    settings?.save()
                    update.toggle()
                }
        }.frame(width: 500)
            .onAppear() {
                if let id = convoid {
                    self.convoid = id
                    let fr = Conversation.fetchRequest()
                    fr.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                    let res = try? PreferencesManager.shared.persistentContainer.viewContext.fetch(fr)
                    if let first = res?.first {
                        convo = first
                        settings = PreferencesManager.getConversationSettings(first)
                    }
                }
            }.background(AppColors.chatBackgroundColor)
    }
    
    init(convoid: Binding<UUID?>) {
        _convoid = convoid
    }
}

struct SystemPromptInputView_Previews: PreviewProvider {
    static var previews: some View {
        SystemPromptInputView(convoid: Binding.constant(nil))
    }
}
