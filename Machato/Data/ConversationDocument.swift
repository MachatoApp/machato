//
//  ConversationDocument.swift
//  Machato
//
//  Created by Théophile Cailliau on 20/04/2023.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct ConversationDocument: FileDocument {
    
    private enum Role : String {
        case system, user, assistant
    }
    
    static var readableContentTypes: [UTType] { [.text] }
    
    private var messages: [(Role, Date, String)] = [];
    
    private var fileContent : String {
        messages.reduce("") { (acc, v) in
            let (role, date, message) = v
            return acc + """

## \(role.rawValue.capitalized): \(date.description)

\(message)

"""
        }
    }
    
    var title : String?
    
    init(convo: Conversation) {
        guard let messages = convo.has_messages?.sortedArray(using: [NSSortDescriptor(keyPath: \Message.date, ascending: true)]) as? [Message]
        else { return }
        self.messages = messages.map { ($0.is_response ? .assistant : .user, $0.date ?? Date.now, $0.content ?? "")}
        title = convo.title
        title? += ".md"
    }
    
    init(configuration: ReadConfiguration) throws {
        
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: fileContent.data(using: .utf8)!)
    }
    
}
