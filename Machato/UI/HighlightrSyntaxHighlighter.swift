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
import AppKit

class HighlightrSyntaxHighlighter: CodeSyntaxHighlighter {
    public private(set) var availableLanguages : [String];
    public private(set) var availableThemes : [String];
    private var memoizedIsLanguageSupported: (String?) -> Bool = { _ in return true };
    
    public static let shared : HighlightrSyntaxHighlighter = .init()

    func isLanguageSupported(_ lo: String?) -> Bool {
        guard let l = lo else { return false }
        return availableLanguages.contains(l)
    }
    
    private var darkHighlightr: Highlightr
    private var lightHighlightr: Highlightr
    
    init(light: String = "xcode", dark: String = "obsidian") {
        darkHighlightr = Highlightr()!
        lightHighlightr = Highlightr()!
        availableLanguages = lightHighlightr.supportedLanguages()
        availableThemes = lightHighlightr.availableThemes().sorted()
        memoizedIsLanguageSupported = Memoize.memoize(isLanguageSupported)
        setTheme(theme: light, colorScheme: .light)
        setTheme(theme: dark, colorScheme: .dark)
    }
    
    private func highlighterForColorScheme(_ theme : ColorScheme) -> Highlightr {
        (theme == .dark ? darkHighlightr : lightHighlightr)
    }
    
    func setTheme(theme: String, colorScheme: ColorScheme) {
        let highlightr = highlighterForColorScheme(colorScheme)
        highlightr.setTheme(to: theme)
        highlightr.theme.setCodeFont(RPFont.monospacedSystemFont(ofSize: PreferencesManager.shared.fontSize, weight: .regular))
    }

    enum ColorScheme {
        case dark, light
    }
    
    private func highlightCode(_ code: String, language: String?, theme: ColorScheme) -> NSAttributedString? {
        let highlightedCode = highlighterForColorScheme(theme).highlight(code, as: language)
        return highlightedCode
    }
    
    private func highlight(_ code: String, language: String?) -> NSMutableAttributedString {
        let resultLight = NSMutableAttributedString(attributedString: highlightCode(code, language: language, theme:.light) ?? NSAttributedString(string: code, attributes: [.font : NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)]))
        let resultDark = NSMutableAttributedString(attributedString: highlightCode(code, language: language, theme: .dark) ?? NSAttributedString(string: code, attributes: [.font : NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)]))
        resultLight.enumerateAttributes(in: NSRange(location: 0, length: resultLight.length)) { attrs, range, _ in
            let foregroundColor = (attrs[.foregroundColor] as? NSColor) ?? NSColor.white
            resultLight.addAttribute(.foregroundColor, value: NSColor.dynamicColor(light: foregroundColor, dark:
                                                                                    resultDark.attribute(.foregroundColor, at: range.location, effectiveRange: nil) as? NSColor ?? NSColor.white), range: range)
        }
        return resultLight
    }
    
    func highlightCode(_ code: String, language: String?) -> AnyView {
        let hc = highlight(code, language: memoizedIsLanguageSupported(language) ? language : nil)
        let ashc = AttributedString(hc)
        return AnyView(CodeContentView(code: ashc, rawCode: code))
    }
}

extension NSColor {
    
    public class func dynamicColor(light: NSColor, dark: NSColor) -> NSColor {
        if #available(OSX 10.15, *) {
            return NSColor(name: nil) {
                switch $0.name {
                case .darkAqua, .vibrantDark, .accessibilityHighContrastDarkAqua, .accessibilityHighContrastVibrantDark:
                    return dark
                default:
                    return light
                }
            }
        } else {
            return light
        }
    }
}

