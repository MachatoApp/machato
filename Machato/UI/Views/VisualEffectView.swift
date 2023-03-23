//
//  VisualEffectView.swift
//  Machato
//
//  Created by Théophile Cailliau on 07/06/2023.
//

import SwiftUI

// Visual effect est la pour rendre le fond effet transparent
struct VisualEffect: NSViewRepresentable {
    
    func makeNSView(context: Self.Context) -> NSView {
        let effect = NSVisualEffectView()
        effect.blendingMode = .behindWindow
        effect.state = NSVisualEffectView.State.active  // this is this state which says transparent all of the time
        effect.material = .underWindowBackground
        return effect
    }
    
    func updateNSView(_ nsView: NSView, context: Context) { }
}
