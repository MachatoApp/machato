//
//  WindowAccessor.swift
//  Machato
//
//  Created by Théophile Cailliau on 25/04/2023.
//

import Foundation
import SwiftUI

struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.window = view.window   // << right after inserted in window
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

extension View {
    func makeWindowFloat()  -> some View {
        self.background(WindowAccessor(window: Binding(get: {
            nil
        }, set: { v in
            v?.level = .floating
            v?.isMovableByWindowBackground = true
        })))
    }
    
    func onWindowDefined(perform: @escaping ((NSWindow?) -> Void)) -> some View {
        self.background(WindowAccessor(window: Binding(get: {
            nil
        }, set: perform)))
    }
}
