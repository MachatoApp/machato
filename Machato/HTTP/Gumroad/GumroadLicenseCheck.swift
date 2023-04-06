//
//  GumroadLicenseCheck.swift
//  Machato
//
//  Created by Théophile Cailliau on 05/04/2023.
//

import Foundation

class GumroadLicenseManager {
    static public var shared = GumroadLicenseManager();
    public var checked : Bool = false;
    
    public func checkLicense(incrementDeviceCount : Bool = false) async -> Bool {
        guard checked == false else { return true }
        print("Requesting license check!")
        #if DEBUG
        checked = true
        #endif
        let productId = "T4p_fSdETKCfTj1eczV54A=="
        let licenseKey = PreferencesManager.shared.license_key
        
        let url = URL(string: "https://api.gumroad.com/v2/licenses/verify")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let requestBodyString = "product_id=\(productId)&license_key=\(licenseKey)&increment_uses_count=\(incrementDeviceCount)"
        
        if let requestData = requestBodyString.data(using: .utf8) {
            request.httpBody = requestData
        }
        
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Unable to process HTTP response")
                return false
            }
            
            let statusCode = httpResponse.statusCode
            
            if statusCode == 200 {
                print("License key was verified!") //TODO: more thorough check
                checked = true
            } else if statusCode == 404 {
                print("License key was not verified")
            } else {
                print("Status Code: \(statusCode) - Other")
            }
        } catch {
            print("Error: \(error.localizedDescription)")
        }
        return checked
    }
}
