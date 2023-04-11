//
//  View.swift
//  Machato
//
//  Created by Théophile Cailliau on 11/04/2023.
//

import Foundation
import SwiftUI

extension NSTextView {
    open override var frame: CGRect {
        didSet {
            backgroundColor = .clear
            drawsBackground = true
        }
    }
}
