//
//  DeviceLocation.swift
//  Machato
//
//  Created by Théophile Cailliau on 17/06/2023.
//

import Foundation



struct DeviceLocation : OpenAIFunction {
    static let name: String = "current_location"
    static let description: String = "Get the user's current coordinates"
    static let argumentDescription: [String : Any] = [:];
    static let required : [String] = []
    
    struct Arguments : Codable {
        
    }
    
    func displayDescription(args _: String) throws -> String {
        "Requesting this device's location"
    }
    
    @MainActor
    func execute(arguments _: Arguments) async throws -> String {
        do {
            let locationManager = LocationManager()
//            try locationManager.requestAuthorization()
            let (location, placemark) = try await locationManager.getCurrentLocation()
            var result = "Approximate location\nlat: \(location.latitude.rounded(toPlaces: 3)), long: \(location.longitude.rounded(toPlaces: 3))"
            if let city = placemark?.locality, let countryCode = placemark?.isoCountryCode {
                result += "\n\(city), \(countryCode)"
            }
            return result
        } catch LocationError.unauthorized {
            throw FunctionError.executionFailed(message: "Permission denied")
        } catch LocationError.unavailable {
            throw FunctionError.executionFailed(message: "Location services unavailable")
        } catch LocationError.clError(let clerr) {
            print(clerr as Any)
            throw FunctionError.executionFailed(message: "CoreLocation error")
        } catch {
            print("generic error caught: \(error)")
            throw FunctionError.executionFailed(message: "An unknown error occurred")
        }
    }
}

extension Double {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
