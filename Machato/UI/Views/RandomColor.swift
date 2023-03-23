//
//  RandomColor.swift
//  Machato
//
//  Created by Théophile Cailliau on 12/04/2023.
//

import Foundation
import SwiftUI

extension ShapeStyle where Self == Color {
    static var random: Color {
        return Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}
