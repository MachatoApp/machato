//
//  Webpage.swift
//  Machato
//
//  Created by Théophile Cailliau on 19/06/2023.
//

import Foundation
import SwiftSoup

class Webpage : NSObject, URLSessionDataDelegate, OpenAIFunction {
    static var required: [String] = ["url"]
    
    static let argumentDescription: [String : Any] = [
        "url": [
            "type": "string",
            "description": "The url from which to fetch the text",
        ] as [String : String]
    ] as [String : Any];
    
    static var description: String = "Fetch the text content of a webpage"
    
    static let name: String = "fetch_webpage"
    
    struct Arguments : Codable {
        let url : String
    }
    
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping @Sendable (URLSession.ResponseDisposition) -> Void
    ) {
        if let mimeType = response.mimeType {
            if mimeType.hasPrefix("text") {
                completionHandler(.allow)
            } else {
                print("Mimetype is not text/*")
                completionHandler(.cancel)
            }
        } else {
            print("Mimetype is not available. Stopping data task.")
            completionHandler(.cancel)
        }
    }
    
    func execute(arguments: Arguments) async throws -> String {
        guard let url = URL(string: arguments.url) else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession(configuration: .default, delegate: self, delegateQueue: nil).data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print(data, response)
            throw URLError(.badServerResponse)
        }
        if let stringResponse = String(data: data, encoding: .utf8) {
            do {
                let doc = try SwiftSoup.parse(stringResponse)
                return try doc.body()!.text()
            } catch {
                print(error)
                throw FunctionError.executionFailed(message: "Text extraction failed")
            }
        } else {
            print(data)
            throw FunctionError.executionFailed(message: "Invalid response")
        }
    }
}
