//
//  CodeContentView.swift
//  Machato
//
//  Created by Théophile Cailliau on 13/05/2023.
//

import SwiftUI


struct CodeContentView: View {
    var lines : Int;
    var originalCode : AttributedString;
    var rawCode : String;
    
    @State private var copied : Bool = false;
    @State private var copyHover: Bool = false;
    @State private var hovering : Bool = false;
    
    init(code: AttributedString, rawCode: String) {
        self.lines = rawCode.matches(of: #/\n/#).count + 1
        self.originalCode = code
        self.rawCode = rawCode
    }
    
    
    var body : some View {
#if DEBUG
        //return EmptyView()
#endif
        HStack (alignment: .top) {
            CodeContentStaticView(originalCode: originalCode, lines: lines).equatable()
                .padding([.leading, .trailing], 15).padding([.top], 10).padding([.bottom], CGFloat(integerLiteral: UserDefaults.standard.integer(forKey: "font_size"))  - 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.gray, lineWidth: 1).opacity(0.5)
                )
#if os(macOS)
                Button {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(self.rawCode, forType: .string)
                    copied = true
                    Task {
                        try await Task.sleep(nanoseconds: UInt64(1e9))
                        copied = false
                    }
                } label: {
                    Image(systemName: copied ? "checkmark" : "doc.on.clipboard")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 15, height: 15)
                }
                .buttonStyle(.borderless)
                .foregroundColor(copyHover || copied ? Color.primary : .gray)
                .disabled(copied)
                .onHover { b in
                    self.copyHover = b
                }
#endif
        }
            
    }
}

struct CodeContentStaticView : View, Equatable {
    static func == (lhs: CodeContentStaticView, rhs: CodeContentStaticView) -> Bool {
        return lhs.originalCode == rhs.originalCode && lhs.lines == rhs.lines
    }
    
    var originalCode: AttributedString
    var lines: Int
    
    @AppStorage(PreferencesManager.StoredPreferenceKey.hideLineNos) private var hideLineNos = false;

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if !hideLineNos {
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(1...lines, id: \.self) { i in
                        Text(i.description).padding([.trailing], 10).foregroundColor(.gray).font(.system(size: PreferencesManager.shared.fontSize).monospaced()).drawingGroup(opaque: false)
                    }
                }
                Divider().padding([.trailing], 10).foregroundColor(.gray)
            }
            ScrollView(.horizontal) {
                Text(originalCode)
                //                    if hovering {
                //                        code
                //                    } else {
                //                        code.drawingGroup()
                //                    }
                //                    AttributedText(attributedString: originalCode).equatable()
            }
        } //.background(.random)
    }
}
