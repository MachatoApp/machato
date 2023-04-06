//
//  ChatResponseError.swift
//  Machato
//
//  Created by Théophile Cailliau on 30/03/2023.
//

import Foundation

enum ChatResponseError: CaseIterable, Identifiable {
    case api_invalid, network_error, api_error, license_invalid, unknown
    var id : Self { self }
    var description: String {
        switch self {
        case .api_invalid:
            return "The provided API key was invalid."
        case .api_error:
            return "The API sent an error back."
        case .network_error:
            return "There was a network error."
        case .unknown:
            return "An unknown error occured."
        case .license_invalid:
            return "Your license key could not be validated"
        }
    }
    static let api_key_empty = "API key is empty. Make sure to set your API key in Machato's settings."
    static let license_invalid_message = "Your license key was invalid."
}
