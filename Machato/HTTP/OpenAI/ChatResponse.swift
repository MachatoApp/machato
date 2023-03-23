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
    var object: String;
    var model: String;
    var choices: [DeltaMessage]
    
    struct DeltaMessage : Codable {
        var delta : DeltaMessageContent;
        var index: Int;
        var finish_reason: String?
        struct DeltaMessageContent : Codable {
            var content : String?;
            var function_call : FunctionCall?
            struct FunctionCall : Codable {
                var name : String?
                var arguments: String?
            }
        }
    }
}

struct AnthropicChatDelta : Codable {
    var completion : String
    var stop_reason : String?
    var model : String    
}

public struct APIError: Error, Codable {
    struct Content: Codable {
        var message: String
        var type: String
        var param: String?
        var code: String?
    }
    var error: Content
}

struct ModelList : Codable {
    var data : [ModelId]
    struct ModelId : Codable {
        var id: String
        var object: String
    }
}
