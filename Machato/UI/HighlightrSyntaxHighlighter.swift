//
//  SplashSyntaxHighlighter.swift
//  Machato
//
//  Created by Théophile Cailliau on 28/03/2023.
//

import Foundation
import SwiftUI
import MarkdownUI
import Highlightr

class HighlightrSyntaxHighlighter: CodeSyntaxHighlighter {
    private var theme: String
    private var highlightr: Highlightr
    private var availableLanguages : [String];
    private var memoizedIsLanguageSupported: (String?) -> Bool = { _ in return true };
    
    public static let shared : HighlightrSyntaxHighlighter = HighlightrSyntaxHighlighter()
    
    func isLanguageSupported(_ lo: String?) -> Bool {
        guard let l = lo else { return false }
        return availableLanguages.contains(l)
    }
    
    init(theme: String = "xcode") {
        self.theme = theme
        highlightr = Highlightr()!
        highlightr.setTheme(to: theme)
        availableLanguages = highlightr.supportedLanguages()
        memoizedIsLanguageSupported = Memoize.memoize(isLanguageSupported)
        print("Initiating highlightr instance")
    }
    
    func setTheme(theme: String) {
        self.theme = theme
        highlightr.setTheme(to: theme)
    }

    func highlightCode(_ code: String, language: String?) -> Text {
        let highlightedCode = highlightr.highlight(code, as: memoizedIsLanguageSupported(language) ? language : nil)
        guard let hc = highlightedCode else { return Text(code) }
        return Text(AttributedString(hc))
    }
}
