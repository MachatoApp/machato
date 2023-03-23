//
//  PiePiece.swift
//  Machato
//
//  Created by Théophile Cailliau on 22/04/2023.
//

import SwiftUI

struct Arc: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var clockwise: Bool = false;
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width / 2, startAngle: startAngle, endAngle: endAngle, clockwise: clockwise)
        path.addLine(to: CGPoint(x: rect.midX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

fileprivate struct PiePiece: View {
    var body: some View {
        Arc(startAngle: .degrees(0), endAngle: .degrees(220))
            .fill(.blue)
            .frame(width: 300, height: 300)
    }
}

struct PiePiece_Previews: PreviewProvider {
    static var previews: some View {
        PiePiece()
    }
}
