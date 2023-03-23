//
//  ChatElementContent.swift
//  Machato
//
//  Created by Théophile Cailliau on 12/05/2023.
//

import SwiftUI
import MarkdownUI
import LaTeXSwiftUI

struct ChatElementContent: View, Equatable {
    static func == (lhs: ChatElementContent, rhs: ChatElementContent) -> Bool {
        return lhs.content == rhs.content && lhs.generating == rhs.generating && lhs.collapsed == rhs.collapsed && lhs.typeset == rhs.typeset && lhs.include == rhs.include
    }
    
    
    var content : String
    var generating : Bool
    var collapsed : Bool
    var typeset : TypesetFunctionality
    var include : Bool
    
    @Binding var selfHeight : Double
    
    @ObservedObject var pref = PreferencesManager.shared
    
    // TODO: Temporary hack awaiting latex-swuiftui patch
    var messageContentLatexPatched : String {
        var m = content
        guard typeset == .mathjax else { return m }
        m.replace(#/\$\$\n/#) { _ in "$$" }
        m.replace(#/\\\[\n/#) { _ in "\\[" }
        m.replace(#/\n\\\]/#) { _ in "\\]" }
        m.replace(#/\n\$\$/#) { _ in "$$" }
        m.replace(#/\\\(|\\\)/#) { _ in "$" }
        return m
    }
    
    private var cursorString : String {
        generating ? " ▏"  : "" //(Int(Date.now.timeIntervalSince1970*10) % 10) < 5
    }
    
    init(_ content : String, _ generating : Bool, _ collapsed : Bool, _ typeset: TypesetFunctionality, _ include : Bool, _ selfHeight : Binding<Double>) {
        self.content = content
        self.generating = generating
        self.collapsed = collapsed
        self.typeset = typeset
        self.include = include
        self._selfHeight = selfHeight
    }
    
    var body: some View {
        Group {
            switch (collapsed ? .plain : typeset) {
            case .markdown:
                Markdown((content) + cursorString).padding(10).textSelection(.enabled)
                    .markdownCodeSyntaxHighlighter(HighlightrSyntaxHighlighter.shared)
                    .markdownBlockStyle(\.codeBlock) { config in
                        config.label.markdownTextStyle(textStyle: {
                            FontSize(pref.fontSize)
                        })
                        .padding([.leading, .trailing], 15).padding([.bottom], 20).padding([.top], 8)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .markdownTextStyle {
                        FontSize(pref.fontSize)
                    } .id(pref.lightTheme + pref.darkTheme)
#if DEBUG
//                    .background(.random)
#endif
            case .plain:
                Text((content) + cursorString).padding(10).textSelection(.enabled)
                    .font(.system(size: pref.fontSize))
                    .lineSpacing(2)
                    .lineLimit(collapsed ? 1 : nil)
#if DEBUG
//                    .background(.random)
//                  .drawingGroup()
#endif
            case .mathjax:
                LaTeX(messageContentLatexPatched + cursorString/*, scale: pref.fontSize/13 */).padding(10).textSelection(.enabled)
                    .foregroundColor(AppColors.chatForegroundColor)
                    .parsingMode(.onlyEquations)
                    .errorMode(.original)
                    .font(.system(size: pref.fontSize))
            }
        }
        .opacity(include ? 1 : 0.4) //.background(.random)
//        .onChange(of: pref.fontSize) { _ in
//            update.toggle()
//        }
//        .onChange(of: pref.narrowMessages) { _ in
//            DispatchQueue.main.async {
//                withAnimation(.easeInOut(duration: 0.2)) {
//                    update.toggle()
//                }
//            }
//        }
        .background(GeometryReader { geometry in
            Color.clear
                .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .global).height)
        })
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            selfHeight = value
        }
    }
}
