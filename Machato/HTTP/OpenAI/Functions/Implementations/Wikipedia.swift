//
//  File.swift
//  Machato
//
//  Created by Théophile Cailliau on 18/06/2023.
//

import Foundation

struct Wikipedia : OpenAIFunction {
    static var required: [String] = ["query", "countrycode"]
    
    static let argumentDescription: [String : Any] = [
        "query": [
            "type": "string",
            "description": "The query",
        ] as [String : String],
        "countrycode": [
            "type": "string",
            "description": "A two-letter contrycode that will be used to determine Wikipedia's language",
        ] as [String : String]
    ] as [String : Any];

    static var description: String = "Search wikipedia article names"
    
    static let name: String = "wikipedia_search"
    
    struct Arguments : Codable {
        let query: String
        let countrycode : String?
    }
    
    struct WikipediaEntry: Codable {
        var name: String
        var subtitle: String
        var wikiURL: String
        
        enum CodingKeys: String, CodingKey {
            case name
            case subtitle
            case wikiURL
        }
    }
    
    struct WikipediaResults: Codable {
        var query: String
        var results: [WikipediaEntry]
        
        init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            
            query = try container.decode(String.self)
            
            let names = try container.decode([String].self)
            let subtitles = try container.decode([String].self)
            let wikiURLs = try container.decode([String].self)
            
            results = zip(names, zip(subtitles, wikiURLs)).map { (name, subtitleURL) -> WikipediaEntry in
                WikipediaEntry(name: name, subtitle: subtitleURL.0, wikiURL: subtitleURL.1)
            }
        }
    }
    
    func execute(arguments: Arguments) async throws -> String {
        // Later: https://fr.wikipedia.org/w/index.php?search=matrix&profile=advanced&fulltext=1&ns0=1 which also searches inside articles
        guard let apiUrl = URL(string: "https://\(arguments.countrycode?.lowercased() ?? "en").wikipedia.org/w/api.php?action=opensearch&search=\(arguments.query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? arguments.query.replacing(#/[^\w]/#, with: ""))&namespace=0&format=json") else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: apiUrl)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print(data, response)
            throw URLError(.badServerResponse)
        }
        let results = try JSONDecoder().decode(WikipediaResults.self, from: data).results
        if results.isEmpty  {
            return "No article matched your query."
        }
        return results.map { $0.wikiURL }.joined(separator: "\n")
    }
}

