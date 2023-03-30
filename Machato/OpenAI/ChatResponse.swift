//
//  ChatResponse.swift
//  Machato
//
//  Created by Théophile Cailliau on 26/03/2023.
//

import Foundation

struct ChatResponse: Codable {
    var id: String;
    var object: String;
    var created: UInt32;
    var model: String;
    var usage: UsageStats;
    var choices: [ResponseMessage];
    
    struct UsageStats: Codable {
        var prompt_tokens: Int;
        var completion_tokens: Int;
        var total_tokens: Int;
    }

    struct ResponseMessage: Codable {
        struct ResponseMessageContent: Codable {
            var role: String;
            var content: String;
        }
        var finish_reason: String?;
        var index: Int;
        var message: ResponseMessageContent;
    }
}

struct StreamedChatDelta : Codable {
    var id : String;
    var object: String;
    var created: UInt32;
    var model: String;
    var choices: [DeltaMessage]
    
    struct DeltaMessage : Codable {
        var delta : DeltaMessageContent;
        var index: Int;
        var finish_reason: String?
        struct DeltaMessageContent : Codable {
            var content : String;
        }
    }
}
