//
//  LocationManager.swift
//  Machato
//
//  Created by Théophile Cailliau on 17/06/2023.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    var locationManager = CLLocationManager()
    
    override required init() {
        super.init()
        locationManager.delegate = self
//        locationManager.allowsBackgroundLocationUpdates = false
//        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.activityType = .other
//        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }
    
    var continuation : CheckedContinuation<(CLLocationCoordinate2D, CLPlacemark?), Error>? = nil;
    
    func getCurrentLocation() async throws -> (CLLocationCoordinate2D, CLPlacemark?) {
        locationManager.requestWhenInUseAuthorization()
//        locationManager.stopUpdatingLocation()
        return try await withCheckedThrowingContinuation({ continuation in
            self.continuation = continuation
            locationManager.requestWhenInUseAuthorization()
        })
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        // Look up the location and pass it to the completion handler
        CLGeocoder().reverseGeocodeLocation(locations.last!,
                                        completionHandler: { (placemarks, error) in
            if error == nil {
                self.continuation?.resume(returning: (locations.last!.coordinate, placemarks?[0]))
            } else {
                self.continuation?.resume(returning: (locations.last!.coordinate, nil))
            }
            self.continuation = nil
        })
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        guard let error = error as? CLError, error.code != .locationUnknown else {
            print("error was locationUnknown, ignoring")
            return
        }
        continuation?.resume(throwing: LocationError.clError(error: error))
        continuation = nil
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorized:
            locationManager.requestLocation()
            break
            
        case .restricted, .denied:
            continuation?.resume(throwing: LocationError.unauthorized)
            continuation = nil
            break
            
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            break
            
        default:
            break
        }
    }
}

enum LocationError : Error {
    case unavailable
    case unauthorized
    case clError(error: Error?)
}
