//
//  AboutView.swift
//  Machato
//
//  Created by Théophile Cailliau on 14/04/2023.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(nsImage: NSImage(named: "AppIcon")!)
            
            Text("\(Bundle.main.appName)")
                .font(.system(size: 20, weight: .bold))
                // Xcode 13.0 beta 2
                //.textSelection(.enabled)
            
            Link("\(AboutView.offSiteAdr.replacingOccurrences(of: "https://", with: ""))", destination: AboutView.offCiteUrl )
            
            Text("Ver: \(Bundle.main.appVersionLong) (\(Bundle.main.appBuild)) ")
                // Xcode 13.0 beta 2
                //.textSelection(.enabled)
            
            Text(Bundle.main.copyright)
                .font(.system(size: 10, weight: .thin))
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(minWidth: 350, minHeight: 300)
    }
}


extension AboutView {
    private static var offSiteAdr: String { "https://machato.app/faq" }
    private static var offEmail: String { "contact@machato.app" }
    
    public static var offCiteUrl: URL { URL(string: AboutView.offSiteAdr )! }
    public static var offEmailUrl: URL { URL(string: "mailto:\(AboutView.offEmail)")! }
}
extension Bundle {
    public var appName: String { getInfo("CFBundleName")  }
    //public var displayName: String {getInfo("CFBundleDisplayName")}
    //public var language: String {getInfo("CFBundleDevelopmentRegion")}
    //public var identifier: String {getInfo("CFBundleIdentifier")}
    public var copyright: String {getInfo("NSHumanReadableCopyright").replacingOccurrences(of: "\\\\n", with: "\n") }
    
    public var appBuild: String { getInfo("CFBundleVersion") }
    public var appVersionLong: String { getInfo("CFBundleShortVersionString") }
    //public var appVersionShort: String { getInfo("CFBundleShortVersion") }
    
    fileprivate func getInfo(_ str: String) -> String { infoDictionary?[str] as? String ?? "⚠️" }
}
