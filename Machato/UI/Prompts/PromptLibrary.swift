//
//  PromptLibrary.swift
//  Machato
//
//  Created by Théophile Cailliau on 06/05/2023.
//

import SwiftUI
import Colorful

struct PromptView: View {
    
    var prompt : any PromptLike
    @State var showPopup : Bool = false;
    @State var hover : Bool = false;
    
    @Environment(\.managedObjectContext) private var moc;
    
    var body: some View {
        VStack {
            Text(prompt.emoji ?? "🤓").font(.largeTitle).scaleEffect(hover ? 1.1 : 1)
            Text(prompt.title ?? "Prompt Title")
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
                .padding([.leading, .trailing], 5)
        }.frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(AppColors.chatBackgroundColor).cornerRadius(8)
            .onTapGesture {
                showPopup.toggle()
            }
            .onHover(perform: { h in
                withAnimation(Animation.interpolatingSpring(mass: 1.0,stiffness: 150.0,damping: 10,initialVelocity: 0)) {
                    hover = h
                }
            })
            .popover(isPresented: $showPopup, arrowEdge: .bottom) {
                VStack {
                    if let prompt = prompt as? PresetPrompt {
                        ScrollView {
                            VStack {
                                Text(prompt.prompt ?? "N/A")
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(5)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(nil)
                                    .textSelection(.enabled)
                            }
                        }.frame(height: 150) .background(AppColors.chatBackgroundColor).cornerRadius(8)
                            .padding(10)
                    } else if let prompt = prompt as? PromptEntity {
                            VStack {
                                TextField("Emoji", text: Binding(get: {
                                    prompt.emoji ?? ""
                                }, set: { v in
                                    prompt.emoji = v
                                    try? moc.save()
                                })).textFieldStyle(.roundedBorder)
                                TextField("Title", text: Binding(get: {
                                    prompt.title ?? ""
                                }, set: { v in
                                    prompt.title = v
                                    try? moc.save()
                                })).textFieldStyle(.roundedBorder)
                                TextEditor(text: Binding(get: {
                                    prompt.prompt ?? ""
                                }, set: { v in
                                    prompt.prompt = v
                                    try? moc.save()
                                }))
                                    .padding(5)
                                    .frame(width: 380, height: 150) .background(AppColors.chatBackgroundColor).cornerRadius(8)
                            }.padding(10)

                        
                    }
                    HStack {
                        Spacer()
                        if let prompt = prompt as? PromptEntity {
                            Button {
                                PromptSelectionSingleton.shared.removeFromRecents(prompt)
                                moc.delete(prompt)
                                try? moc.save()
                            } label: {
                                Label("Trash", systemImage: "trash").labelStyle(.titleAndIcon)
                                    .foregroundColor(.red)
                            }.padding([.trailing], 5)
                        }
                        Button {
                            PromptSelectionSingleton.shared.selectPrompt(prompt, system: prompt.system)
                        } label: {
                            Label("Use", systemImage: "arrow.forward").labelStyle(.titleAndIcon)
                        }.buttonStyle(.borderedProminent)
                            .padding([.trailing], 10)
                    }.padding([.leading, .bottom], 10)
                }.frame(maxWidth: 400)
            }
    }
    
    init(_ prompt : any PromptLike) {
        self.prompt = prompt
    }
}

struct PromptLibrary: View {
    @Environment(\.managedObjectContext) private var moc;
    
    private var presets : [PresetPrompt] = [];
    @State private var filter : String = "";
    let system : Bool
    
    let columns = [
        GridItem(.adaptive(minimum: 110), alignment: .leading)
    ]
    
    func filterPrompts(_ prompts: [any PromptLike], _ filter: String) -> [any PromptLike] {
        let words = filter.split(separator: #/\s+/#).map { String($0).lowercased() }
        return prompts.filter { prompt in
            return words.isEmpty || words.allSatisfy { word in
                return prompt.prompt?.lowercased().contains(word) == true || prompt.title?.lowercased().contains(word) == true
            }
        }
    }
    
    @FetchRequest private var prompts : FetchedResults<PromptEntity>;
    
    @State private var showNewCustomPromptPopover : Bool = false;
    @State private var newEmoji : String = "";
    @State private var newTitle : String = "";
    @State private var newPrompt : String = "";
    
    @ObservedObject private var promptSelection = PromptSelectionSingleton.shared;
    
    var body: some View {
        TabView {
            ScrollView(.vertical) {
                TextField("Filter...", text: $filter).textFieldStyle(.roundedBorder)
                    .padding([.leading, .trailing], 5)
                LazyVGrid(columns: columns) {
                    ForEach(filterPrompts(presets, filter), id: \.id) { preset in
                        PromptView(preset)
                    }
                }.padding([.leading, .trailing], 5)
            }.tabItem {
                Label("Presets", systemImage: "tray.full").labelStyle(.titleAndIcon)
            }
            ScrollView(.vertical) {
                Button {
                    guard !showNewCustomPromptPopover else { return }
                    newEmoji = "🔨"
                    newTitle = ""
                    newPrompt = "Be helpful."
                    showNewCustomPromptPopover = true
                } label: {
                    Label("New", systemImage: "plus.app.fill").labelStyle(.titleAndIcon)
                } .frame(maxWidth: .infinity)
                    .padding(10)
                    .buttonStyle(.borderless)
                    .background(AppColors.chatBackgroundColor)
                    .cornerRadius(8)
                    .padding([.leading, .trailing], 5)
                    .popover(isPresented: $showNewCustomPromptPopover) {
                        VStack {
                            TextField("Emoji", text: $newEmoji)
                                .textFieldStyle(.roundedBorder)
                            TextField("Title", text: $newTitle)
                                .textFieldStyle(.roundedBorder)
                            TextEditor(text: $newPrompt)
                                .frame(height: 200)
                                .font(.body)
                                .background(AppColors.chatBackgroundColor)
                            Divider()
                            HStack {
                                Spacer()
                                Button {
                                    showNewCustomPromptPopover = false
                                    let p = PromptEntity(context: moc)
                                    p.date = .now
                                    p.emoji = newEmoji
                                    p.prompt = newPrompt
                                    p.title = newTitle
                                    p.id = UUID();
                                    p.system = system
                                    try? moc.save()
                                } label: {
                                    Text("Add")
                                }.buttonStyle(.borderedProminent)
                            }
                        }.padding(5)
                            .frame(width: 400)
                    }
                TextField("Filter...", text: $filter).textFieldStyle(.roundedBorder)
                    .padding([.leading, .trailing], 5)
                LazyVGrid(columns: columns) {
                    ForEach(filterPrompts(Array(prompts), filter), id: \.id) { prompt in
                        PromptView(prompt)
                    }
                } .padding([.leading, .trailing], 5)
            } .tabItem {
                Label("User", systemImage: "person").labelStyle(.titleAndIcon)
            }
            ScrollView(.vertical) {
                TextField("Filter...", text: $filter).textFieldStyle(.roundedBorder)
                    .padding([.leading, .trailing], 5)
                LazyVGrid(columns: columns) {
                    ForEach(filterPrompts(promptSelection.recent.filter { $0.system == system }, filter), id: \.id) { preset in
                        PromptView(preset)
                    }
                }.padding([.leading, .trailing], 5)
            }.tabItem {
                Label("Recent", systemImage: "tray.full").labelStyle(.titleAndIcon)
            }
        }.background(AppColors.chatBackgroundColor)
            .frame(minWidth: 300, minHeight: 500)
    }
    
    init(system : Bool = false) {
        self.system = system
        presets = []
        _prompts = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \PromptEntity.date, ascending: false)], predicate: NSPredicate(format: "system == \(system.description)"))
        if let fileURL = Bundle.main.url(forResource: system ? "personalities" : "preset-prompts", withExtension: "csv")
        {
            do {
                let fileContents = try String(contentsOf: fileURL, encoding: .utf8)
                presets = PresetPrompt.parsePresets(fileContents, system: system)
            } catch {
                fatalError("Error loading contents of file: \(error)")
            }
        }
    }
}

struct PromptLibrary_Previews: PreviewProvider {
    static var previews: some View {
        PromptLibrary()
    }
}
