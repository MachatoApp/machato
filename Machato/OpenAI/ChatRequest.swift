//
//  ChatRequest.swift
//  Machato
//
//  Created by Théophile Cailliau on 26/03/2023.
//

import Foundation

class ChatAPIManager {
    
    func sendChatRequest(_ convo: Conversation, additionalMessages: [String] = [], onResponse: ((Conversation, ChatResponse) -> Void)? = nil) {
        guard let messages = convo.has_messages else { return }
        guard PreferencesManager.shared.api_key != "" else {
            print("Invalid API key !")
            return
        }
        let api_key = PreferencesManager.shared.api_key
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(api_key)", forHTTPHeaderField: "Authorization")
        
        let settings = PreferencesManager.getConversationSettings(convo)

        let body = [
            "model": settings.model.rawValue,
            "temperature": settings.temperature,
            "messages":  {
                var msgs = [["role": "system", "content": settings.prompt]]
                messages.sortedArray(using: [NSSortDescriptor(keyPath: \Message.date, ascending: true)]).forEach() {m in
                    guard let mcast = m as? Message else {
                        print("Message from convo messages was not castable do MessageEntity")
                        return
                    }
                    msgs.append(["role": mcast.is_response ? "assistant" : "user", "content": mcast.content ?? ""])
                }
                msgs.append(contentsOf: additionalMessages.map { ["role" : "user", "content": $0] } )
                return msgs
            }()
            as [[String:String]]
        ] as [String : Any]


        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            request.httpBody = jsonData
        } catch {
            print("Error serializing JSON: \(error.localizedDescription)")
        }

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error sending request: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                return
            }

            if (200...299).contains(httpResponse.statusCode) {
                // Success! Handle the response data here
                print("Received response: \(data?.description ?? "")")
                do {
                    let jsonData : ChatResponse = try JSONDecoder().decode(ChatResponse.self, from: data!)
                    if let or = onResponse {
                        DispatchQueue.main.async {
                            or(convo, jsonData)
                        }
                    }
                } catch {
                    print("Error serializing JSON: \(error.localizedDescription)")
                }
            } else {
                print("Bad response: \(httpResponse.statusCode)")
            }
        }

        task.resume()
    }
    
    func streamedChatRequest(_ convo : Conversation,
                             onEvent: @escaping ((_ event: ChatStreamEvent, _ delta: StreamedChatDelta?, _ i : UInt) -> Void)) {
        guard let messages = convo.has_messages else { return }
        guard PreferencesManager.shared.api_key != "" else {
            print("Invalid API key !")
            return
        }
        let api_key = PreferencesManager.shared.api_key
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(api_key)", forHTTPHeaderField: "Authorization")
        
        let settings = PreferencesManager.getConversationSettings(convo)

        let body = [
            "model": settings.model.rawValue,
            "temperature": settings.temperature,
            "stream": true,
            "messages":  {
                var msgs = [["role": "system", "content": settings.prompt]]
                messages.sortedArray(using: [NSSortDescriptor(keyPath: \Message.date, ascending: true)]).forEach() {m in
                    guard let mcast = m as? Message else {
                        print("Message from convo messages was not castable d\to MessageEntity")
                        return
                    }
                    msgs.append(["role": mcast.is_response ? "assistant" : "user", "content": mcast.content ?? ""])
                }
                return msgs
            }()
            as [[String:String]]
        ] as [String : Any]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            request.httpBody = jsonData
        } catch {
            print("Error serializing JSON: \(error.localizedDescription)")
        }
        
        let eventSource = EventSource(url: request)
        var i : UInt = 0;
        let onEventMainThread = { (event: ChatStreamEvent, delta: StreamedChatDelta?, count: UInt) in
            DispatchQueue.main.async {
                onEvent(event, delta, count)
            }
        }

        eventSource.onMessage { (id, event, data) in
            guard let d = data else { return }
            do {
                let jsonData : StreamedChatDelta = try JSONDecoder().decode(StreamedChatDelta.self, from: d.data(using: .utf8)!)
                onEventMainThread(.delta, jsonData, i)
                i+=1
            } catch {
                print("data could not be json-parsed: \(data ?? "no data")")
            }
        }
        eventSource.connect()
        eventSource.onComplete() { (code, shouldReconect, err) in
            guard let c = code else {
                print("Gone wrong! There was no completion code")
                return
            }
            if (200...299).contains(c) {
                onEventMainThread(.end, nil, i)
            }
        }
    }
    
    func getTitle(_ c: Conversation, onTitle: @escaping ((String) -> Void)) {
        sendChatRequest(c, additionalMessages: ["What would be a short and relevant title for this chat? Answer in the language of the message above. Be very succinct. You must strictly answer with only the title, **no other text is allowed**."]) { (convo, response) in
            guard let c = response.choices.first?.message.content else {return}
            DispatchQueue.main.async {
                onTitle(c.trimmingCharacters(in: ["\""]))
            }
        }
    }

    public enum ChatStreamEvent {
        case delta
        case end
    }
}
