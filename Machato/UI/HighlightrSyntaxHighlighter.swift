//
//  SplashSyntaxHighlighter.swift
//  Machato
//
//  Created by Théophile Cailliau on 28/03/2023.
//

import Foundation
import SwiftUI
import Highlightr
import MarkdownUI

class HighlightrSyntaxHighlighter: CodeSyntaxHighlighter {
    private var theme: String
    private var highlightr: Highlightr
    public private(set) var availableLanguages : [String];
    public private(set) var availableThemes : [String];
    private var memoizedIsLanguageSupported: (String?) -> Bool = { _ in return true };
    
    public static let shared : HighlightrSyntaxHighlighter = .init()
    public static let darkShared : HighlightrSyntaxHighlighter = .init()
    
    func isLanguageSupported(_ lo: String?) -> Bool {
        guard let l = lo else { return false }
        return availableLanguages.contains(l)
    }
    
    init(theme: String = "xcode") {
        self.theme = theme
        highlightr = Highlightr()!
        availableLanguages = highlightr.supportedLanguages()
        availableThemes = highlightr.availableThemes()
        memoizedIsLanguageSupported = Memoize.memoize(isLanguageSupported)
        print("Initiating highlightr instance")
        setTheme(theme: theme)
    }
    
    func setTheme(theme: String) {
        self.theme = theme
        highlightr.setTheme(to: theme)
        highlightr.theme.setCodeFont(RPFont.monospacedSystemFont(ofSize: PreferencesManager.shared.fontSize, weight: .regular))
    }

    func highlightCode(_ code: String, language: String?) -> Text {
        let highlightedCode = highlightr.highlight(code, as: memoizedIsLanguageSupported(language) ? language : nil)
        guard let hc = highlightedCode else { return Text(code) }
        var ashc = AttributedString(hc)
        return Text(ashc).font(.system(size: PreferencesManager.shared.fontSize, design: .monospaced))
    }
}
