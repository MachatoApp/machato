//
//  Colors.swift
//  Machato
//
//  Created by Théophile Cailliau on 27/03/2023.
//

import Foundation
import SwiftUI

struct AppColors {
    static public let chatBackgroundColor: Color = Color(light: .white, dark: Color(rgba: 0x1d1d1dff))
    static public let chatForegroundColor: Color = Color(light: .black, dark: .white)
    static public let chatButtonBackground: Color = Color(light: Color(rgba: 0xf0f0f0ff), dark: Color(rgba: 0x2a2a2aff))
    static public let chatButtonBackgroundHover: Color = Color(light: Color(rgba: 0xe0e0e0ff), dark: Color(rgba: 0x303030ff))
    static public let deleteButtonForeground: Color = .red
    static public let chatDeleteButtonBackground: Color = chatButtonBackground
    static public let chatDeleteButtonBackgroundHover: Color = chatButtonBackgroundHover
    static public let chipBackgroundColor : Color = Color(light: .white, dark: Color(rgba: 0x2a2a2aff))
    static public let sentMessageBackground : Color = Color(light: Color(rgba: 0xfafafaff), dark: Color(rgba: 0x181818ff))
    static public let receivedMessageBackground : Color = chatBackgroundColor
    
    static public let redButtonBackground : Color = Color(light: Color(rgba: 0xfa7171ff), dark: Color(rgba: 0xbd3737ff));
    static public let redButtonForeground: Color = .white;

    static public let darkCodeTheme = "obsidian"
    static public let lightCodeTheme = "xcode"

}
