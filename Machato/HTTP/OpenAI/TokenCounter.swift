//
//  TokenCounter.swift
//  Machato
//
//  Created by Théophile Cailliau on 14/04/2023.
//

import Foundation
import Tiktoken


class TokenCounter {
    static let shared : TokenCounter = .init();
        
    var encoder : Encoding? = nil
    
    func initEncoder() async {
        do {
            encoder = try await Tiktoken.shared.getEncoding("gpt-4")
        } catch {
            print(error)
        }
    }
    
    func countTokens(_ sm: String?) -> Int32 {
        if encoder == nil {
            Task {
                await initEncoder()
            }
        }
        guard let s = sm else { return 0 }
        return Int32(encoder?.encode(value: s).count ?? 0)
    }
}
