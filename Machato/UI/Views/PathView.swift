//
//  PathView.swift
//  Machato
//
//  Created by Théophile Cailliau on 17/06/2023.
//

import Foundation
import SwiftUI

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}
