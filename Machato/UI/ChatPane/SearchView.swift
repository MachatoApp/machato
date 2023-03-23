//
//  SearchView.swift
//  Machato
//
//  Created by Théophile Cailliau on 11/04/2023.
//

import Combine
import SwiftUI

class DictModel: ObservableObject {
    @Published var dict: [String: Bool] = [:]
    var loading : Bool {
        true
    }
}


struct SearchView: View, Equatable {

    // Never redraw the search view, it's always there
    static func == (lhs: Self, rhs: Self) -> Bool {
        true
    }
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Conversation.userOrder, ascending: true), NSSortDescriptor(keyPath: \Conversation.date, ascending: false)], animation: .none) var conversations: FetchedResults<Conversation>;
    @Binding private var text: String;
    @Binding private var scope: MainView.SearchScope;
    @Binding private var current : Conversation?;
    private var goToMessage : ((Message) -> Void);
    @Environment(\.isSearching) var isSearching
    
    @ObservedObject private var loading : DictModel = DictModel();
    
    var body: some View {
        if isSearching {
            ScrollView {
                VStack (alignment: .leading, spacing: 0) {
                    if !loading.dict.allSatisfy({ $0.value == false }) {
                        HStack {
                            Spacer ()
                            ProgressView().padding([.top, .bottom], 20)
                            Spacer()
                        }
                    }
                    if scope == .all || current == nil {
                        ForEach(conversations) { convo in
                            ConversationSearchMatches(convo: convo, text: $text, loading: loading, goToMessage: goToMessage)
                        }
                    } else {
                        ConversationSearchMatches(convo: current!, text: $text, loading: loading, goToMessage: goToMessage)
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    init(text: Binding<String>, scope: Binding<MainView.SearchScope>, current: Binding<Conversation?>, goToMessage: @escaping ((Message) -> Void)) {
        _text = text
        _scope = scope
        _current = current
        self.goToMessage = goToMessage
    }
}

struct MessageMatch : Identifiable {
    let id: UUID = UUID();
    
    let content : String
    let message: Message
    var previousContext : String = "";
    var nextContext : String = "";
    
    init(content: Substring, message: Message) {
        self.content = String(content)
        self.message = message
    }
    
    init(_ m: Message, range: Range<String.Index>) {
        message = m
        let fc = m.content ?? ""
        content = String(fc[range])
        let previousContextRange = (fc.index(range.lowerBound, offsetBy: -50, limitedBy: fc.startIndex) ?? fc.startIndex)..<range.lowerBound
        previousContext = String(fc[previousContextRange]).replacing(#/\n+/#, with: {_ in return " "})
        if previousContextRange.lowerBound != fc.startIndex {
            previousContext = "…" + previousContext
        }
        let nextContextRange = range.upperBound..<(fc.index(range.upperBound, offsetBy: 50, limitedBy: fc.endIndex) ?? fc.endIndex)
        nextContext = String(fc[nextContextRange]).replacing(#/\n+/#, with: {_ in return " "})
        if nextContextRange.upperBound != fc.endIndex {
            nextContext += "…"
        }
    }
}

struct ConversationSearchMatches: View {
    private var convo: Conversation;
    @Binding private var text: String;
    private var goToMessage : ((Message) -> Void);
    
    @State private var matchings : [MessageMatch] = []
    
    func getMatches() -> [MessageMatch] {
        guard let msgs = convo.has_messages else { return [] }
        guard text.isEmpty == false else { return [] }
        var matches : [MessageMatch] = []
        msgs.forEach { maybeMessage in
            
            guard let m = maybeMessage as? Message else { return }
            guard let content = m.content else { return }
            
            var searchRange = content.startIndex..<content.endIndex

            while let range = content.range(of: text, options: .caseInsensitive, range: searchRange) {
                matches.append(MessageMatch(m, range: range))
                searchRange = range.upperBound..<content.endIndex
            }
        }
        return matches
    }
    
    @State private var matchTask : Task<Void, Error>? = nil;
    private var loading : DictModel;
    
    func updateMatches() {
        guard let id = convo.id?.uuidString else { return }
        matchings = []
        loading.dict[id] = true
        matchTask?.cancel()
        matchTask = Task {
            if !text.isEmpty {
                try await Task.sleep(until: .now + .seconds(0.5), clock: .continuous)
            }
            try Task.checkCancellation()
            matchings = getMatches()
            DispatchQueue.main.async {
                loading.dict[id] = false
            }
        }
    }
    
    init(convo: Conversation, text: Binding<String>, loading: DictModel, goToMessage: @escaping ((Message) -> Void)) {
        self.convo = convo
        self._text = text
        self.goToMessage = goToMessage
        self.loading = loading
    }
    
    var body: some View {
        VStack {
            if !matchings.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Divider()
                    HStack (spacing: 0) {
                        Text(convo.title ?? "Untitled").bold().padding([.leading], 5)
                        Spacer()
                    }.padding(2).background(.ultraThinMaterial)
                    Divider()
                    HStack(alignment: .top, spacing: 0) {
                        Spacer().frame(width: 50)
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(matchings) { matching in
                                Button {
                                    goToMessage(matching.message)
                                } label: {
                                    HStack (alignment: .top, spacing: 0) {
                                        Text(matching.message.is_response ? "→" : "←").padding([.trailing], 10).foregroundColor(.gray)
                                        Text(matching.previousContext).foregroundColor(.gray) + Text(matching.content).bold().foregroundColor(AppColors.chatForegroundColor) + Text(matching.nextContext).foregroundColor(.gray)
                                        Spacer()
                                    }.padding([.top, .bottom], 5)
                                } .buttonStyle(.borderless)
                            }
                        }
                    }
                }
            }
        }.onAppear(perform: updateMatches)
            .onChange(of: text) { newValue in
                updateMatches()
            }
    }
}
