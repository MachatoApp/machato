//
//  String+Extension.swift
//  Machato
//
//  Created by Théophile Cailliau on 05/07/2023.
//

import Foundation

extension String {
    func matches<T : RegexComponent>(_ regex: T) -> Bool {
        return !self.ranges(of: regex).isEmpty
    }
}
