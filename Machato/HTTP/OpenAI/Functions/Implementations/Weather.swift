//
//  Weather.swift
//  Machato
//
//  Created by Théophile Cailliau on 16/06/2023.
//

import Foundation
import CoreLocation

class OpenWeatherMap {
    let current_weather : (Double, Double) -> String;
    let geo_url : (String) -> String;
    let openweathermap_api_key : String

    init(openweathermap_api_key: String) {
        self.openweathermap_api_key = openweathermap_api_key
        self.geo_url = { "https://api.openweathermap.org/geo/1.0/direct?q=\($0)&limit=1&appid=\(openweathermap_api_key)" }
        self.current_weather = { lon, lat in "https://api.openweathermap.org/data/2.5/weather?lat=\(lat)&lon=\(lon)&appid=\(openweathermap_api_key)" }
    }
    
    func kelvinToUnit(value: Double, unit: UnitTemperature) -> Int {
        Int(Measurement(value: value, unit: UnitTemperature.kelvin).converted(to: unit).value)
    }
    
    func kelvinToTempString(value: Double) -> String {
        "\(kelvinToUnit(value: value, unit: .celsius))°C (\(kelvinToUnit(value: value, unit: .fahrenheit))°F)"
    }
    
    func fetchCurrentWeather(lon: Double, lat: Double) async throws -> WeatherResponse {
        guard let apiUrl = URL(string:
                                current_weather(lon, lat)
        ) else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: apiUrl)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print(data, response)
            throw URLError(.badServerResponse)
        }
        let geoResponse = try JSONDecoder().decode(WeatherResponse.self, from: data)
        return geoResponse
    }
    
    struct WeatherResponse : Codable {
        let weather : [Situation]
        
        struct Situation : Codable {
            let main : String
            let description : String
        }
        
        let main : Self.Data
        
        struct Data : Codable {
            let temp : Double // K
            let feels_like : Double // K
            let temp_min : Double // K
            let temp_max : Double // K
            let pressure : Double // hPa
            let humidity: Double // percentage
        }
        
        let wind: WindData
        
        struct WindData : Codable {
            let speed : Double // m/s
            let deg : Double // deg
        }
        
        let clouds : CloudData
        
        struct CloudData : Codable {
            let all : Double // percentage
        }
    }
    
    func fetchGeoData(query: String) async throws -> GeoResponse {
        let coords = try await CLGeocoder().geocodeAddressString(query, in: nil, preferredLocale: Locale(identifier: "en"))
        if let first = coords.first {
            return GeoResponse(country: first.isoCountryCode ?? "", lat: first.location?.coordinate.latitude ?? 0, lon: first.location?.coordinate.longitude ?? 0, name: first.locality ?? "Unknown", state: first.administrativeArea ?? "")
        } else {
            throw FunctionError.executionFailed(message: "Geolocation failed")
        }
    }
    
    struct GeoResponse: Codable {
        let country : String
        let lat : Double
        let lon : Double
        let name : String
        let state : String
    }
}

class OpenWeatherMapCity : OpenWeatherMap, OpenAIFunction {    
    static let name: String = "openweathermap_current_city"
    static let description: String = "Retrieve the current weather in a given city from OpenWeatherMap."
    static let argumentDescription: [String : Any] = [
        "location": [
            "type": "string",
            "description": "A city and country code, for example \"London, UK\".",
        ] as [String : String]
    ] as [String : Any];
    static let required = ["location"]
    
    struct Arguments : Codable {
        var location : String;
    }
    
    func displayDescription(args: String) throws -> String {
        "Requesting weather for: \(try parseArguments(str: args).location)"
    }
    
    func execute(arguments args: Arguments) async throws -> String {
        let geo = try await fetchGeoData(query: args.location)
        var response = "Current weather in: \(geo.name), \(geo.state), \(geo.country)\n"
        let weather = try await fetchCurrentWeather(lon: geo.lon, lat: geo.lat)
        weather.weather.prefix(1).forEach { situation in
            response += "Situation: \(situation.main), \(situation.description)\n"
        }
        response += "Current temperature: \(kelvinToTempString(value: weather.main.temp))\n"
        response += "Wind: \(weather.wind.speed) m/s, Humidity: \(Int(weather.main.humidity))%\n"
        response += "Pressure: \(Int(weather.main.pressure)) hPa, Cloudiness: \(Int(weather.clouds.all))%"
        return response
    }
}


class OpenWeatherMapCoordinates : OpenWeatherMap, OpenAIFunction {
    static let name: String = "openweathermap_current_coordinates"
    static let description: String = "Retrieve the current weather at given coordinates from OpenWeatherMap."
    static let argumentDescription: [String : Any] = [
        "lat": [
            "type": "number",
            "description": "A latitude",
        ] as [String : String],
        "long": [
            "type": "number",
            "description": "A longitude",
        ] as [String : String],
    ] as [String : Any];
    static let required = ["lat", "long"]
    
    struct Arguments : Codable {
        var lat : Double;
        var long : Double
    }
    
    func displayDescription(args: String) throws -> String {
        let parsed = try parseArguments(str: args)
        return "Requesting weather at: `lat: \(parsed.lat.rounded(toPlaces: 3)), long: \(parsed.long.rounded(toPlaces: 3))`"
    }
    
    func execute(arguments args: Arguments) async throws -> String {
        let placemark : CLPlacemark? = await withCheckedContinuation { continuation in
            CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: args.lat, longitude: args.long)) { placemarks, error in
                if error == nil {
                    continuation.resume(returning: placemarks?[0])
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
        var response = ""
        if let city = placemark?.locality, let country = placemark?.isoCountryCode {
            response = "Current weather in: \(city), \(country)\n"
        }
        let weather = try await fetchCurrentWeather(lon: args.long, lat: args.lat)
        weather.weather.prefix(1).forEach { situation in
            response += "Situation: \(situation.main), \(situation.description)\n"
        }
        response += "Current temperature: \(kelvinToTempString(value: weather.main.temp))\n"
        response += "Wind: \(weather.wind.speed) m/s, Humidity: \(Int(weather.main.humidity))%\n"
        response += "Pressure: \(Int(weather.main.pressure)) hPa, Cloudiness: \(Int(weather.clouds.all))%"
        return response
    }

}
