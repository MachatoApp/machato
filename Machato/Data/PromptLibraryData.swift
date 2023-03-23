//
//  PromptLibrary.swift
//  Machato
//
//  Created by Théophile Cailliau on 06/05/2023.
//

import Combine
import Foundation

protocol PromptLike : Hashable {
    var emoji : String? { get }
    var title : String? { get }
    var prompt : String? { get }
    var id : UUID? { get }
    var system : Bool { get }
}

struct PresetPrompt : PromptLike, Identifiable {
    var emoji : String?
    var title : String?
    var prompt : String?
    var id : UUID? = UUID();
    var system : Bool
    
    static func parsePresets(_ csv: String, system: Bool = false) -> [PresetPrompt] {
        csv.split(separator: "\n").map { line in
            let lineContent = line.split(separator: "%%")
            guard lineContent.count == 3 else { return PresetPrompt(system: true) }
            return PresetPrompt(emoji: String(lineContent[0]), title: String(lineContent[1]), prompt: String(lineContent[2]), system: system)
        }
    }
}

extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
}

class PromptSelectionSingleton : ObservableObject {
    static let shared = PromptSelectionSingleton()
    
    var systemPublisher = PassthroughSubject<String, Never>()
    var promptPublisher = PassthroughSubject<String, Never>()
    
    public var recent : [any PromptLike] = [];
    
    func selectPrompt(_ prompt : String, system: Bool) {
        (system ? self.systemPublisher : self.promptPublisher).send(prompt)
    }
    
    func selectPrompt<T : PromptLike>(_ prompt: T, system : Bool) {
        recent.removeAll { pl in
            pl.id == prompt.id
        }
        recent.insert(prompt, at: 0)
        selectPrompt(prompt.prompt ?? "", system: system)
    }
    
    func removeFromRecents<T : PromptLike>(_ prompt: T) {
        recent.removeAll { pl in
            pl.id == prompt.id
        }
        self.objectWillChange.send()
    }
}

extension PromptEntity : PromptLike {
    // nothing to do
}
