//
//  Memoize.swift
//  Machato
//
//  Created by Théophile Cailliau on 28/03/2023.
//

import Foundation

struct Memoize {
    static func memoize<Input: Hashable, Output>(_ function: @escaping (Input) -> Output) -> (Input) -> Output {
        // our item cache
        var storage = [Input: Output]()

        // send back a new closure that does our calculation
        return { input in
            if let cached = storage[input] {
                return cached
            }

            let result = function(input)
            storage[input] = result
            return result
        }
    }
}
