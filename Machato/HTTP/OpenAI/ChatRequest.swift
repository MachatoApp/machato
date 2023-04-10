//
//  ChatRequest.swift
//  Machato
//
//  Created by Théophile Cailliau on 26/03/2023.
//

import Foundation

class ChatAPIManager {
    
    func buildURLRequest(_ convo: Conversation, additionalMessages: [String] = [], stream: Bool) -> URLRequest? {
        guard let messages = convo.has_messages else { return nil }
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
            "stream": stream,
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
        return request
    }
    
    func sendChatRequest(_ convo: Conversation, additionalMessages: [String] = [], onResponse: @escaping (Conversation, ChatResponse?, ChatResponseError?, String?) -> Void) async {
        let onResponseMainThread = { (a,b,c,d) in
            DispatchQueue.main.async {
                onResponse(a,b,c,d)
            }
        }
        guard await GumroadLicenseManager.shared.checkLicense() else {
            print("License was incorrect !")
            onResponse(convo, nil, .license_invalid, PreferencesManager.shared.license_key.count > 0 ? ChatResponseError.license_invalid_message : ChatResponseError.license_key_empty)
            return
        }
        guard PreferencesManager.shared.api_key != "" else {
            print("API key empty!")
            onResponse(convo, nil, .api_invalid, ChatResponseError.api_key_empty)
            return
        }
        guard let request = buildURLRequest(convo, additionalMessages: additionalMessages, stream: false) else {
            return //TODO: handle this
        }
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error sending request: \(error.localizedDescription)")
                onResponseMainThread(convo, nil, .network_error, error.localizedDescription)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                onResponseMainThread(convo, nil, .network_error, "The HTTP response was invalid.")
                return
            }
            
            guard let d = data else {
                print("No data on response !")
                onResponseMainThread(convo, nil, .network_error, "There was no response data when making a request.")
                return
            }
            
            print("Received response: \(d)")
            do {
                let jsonData : ChatResponse = try JSONDecoder().decode(ChatResponse.self, from: d)
                onResponse(convo, jsonData, nil, nil)
            } catch {
                print("Error serializing JSON: \(error.localizedDescription)")
                do {
                    let jsonData: APIError = try JSONDecoder().decode(APIError.self, from: d)
                    onResponseMainThread(convo, nil, .api_error, jsonData.error.message)
                } catch {
                    print("Could not serialize into an APIError")
                    onResponseMainThread(convo, nil, .unknown, "The response could not be serialized into an API response or an API error. The HTTP return code was \(httpResponse.statusCode). Response was: \n\n \(String(decoding: d, as: UTF8.self))")
                }
            }
        }
        
        
        task.resume()
    }
    
    func streamedChatRequest(_ convo : Conversation,
                             onEvent: @escaping (ChatStreamEvent, StreamedChatDelta?, UInt, ChatResponseError?, String?) -> Void) async {
        guard await GumroadLicenseManager.shared.checkLicense() else {
            print("License was incorrect !")
            onEvent(.error, nil, 0, .license_invalid, ChatResponseError.license_invalid_message)
            return
        }
        guard PreferencesManager.shared.api_key != "" else {
            onEvent(.error, nil, 0, .api_invalid, ChatResponseError.api_key_empty)
            return
        }
        guard let request = buildURLRequest(convo, stream: true) else {
            onEvent(.error, nil, 0, .network_error, "Could not build the URL request necessary to engage in event listening.")
            return //TODO: handle this
        }
        let eventSource = EventSource(url: request)
        var i : UInt = 0;
        let onEventMainThread = { (event: ChatStreamEvent, delta: StreamedChatDelta?, count: UInt, error: ChatResponseError?, errorMessage: String?) in
            DispatchQueue.main.async {
                onEvent(event, delta, count, error, errorMessage)
            }
        }

        eventSource.onMessage { (id, event, data) in
            guard let d = data else { return }
            do {
                let jsonData : StreamedChatDelta = try JSONDecoder().decode(StreamedChatDelta.self, from: d.data(using: .utf8)!)
                onEventMainThread(.delta, jsonData, i, nil, nil)
                i+=1
            } catch {
                if String(data: d.data(using: .utf8)!, encoding: .utf8)?.contains("chat.completion.chunk") ?? false {
                    print("Some completion chunk could not be parsed. This could be an ending delta.")
                } else {
                    print("data could not be json-parsed: \(data ?? "no data")")
                }
            }
        }
        eventSource.connect()
        eventSource.onComplete() { (code, shouldReconect, err, buffer) in
            guard let c = code else {
                print("Gone wrong! There was no completion code")
                onEventMainThread(.error, nil, i, .network_error, "The final delta yielded no http response code. Error: \(err?.description ?? "")")
                return
            }
            if (200...299).contains(c) {
                onEventMainThread(.end, nil, i, nil, nil)
                return
            }
            do {
                let jsonError : APIError = try JSONDecoder().decode(APIError.self, from: (buffer ?? "").data(using: .utf8)!)
                onEventMainThread(.error, nil, i, .api_error, jsonError.error.message)
            } catch {
                print("Failed to serialize into APIError")
                onEventMainThread(.error, nil, i, .unknown, "The response could not be serialized into an API response or an API error. The HTTP return code was \(c). Response was: \n\n \(buffer ?? "")")
            }
        }
    }
    
    func getTitle(_ c: Conversation, onTitle: @escaping ((String) -> Void)) {
        Task {
            await sendChatRequest(c, additionalMessages: ["What would be a short and relevant title for this chat? Answer in the language of the message above. Be very succinct. You must strictly answer with only the title, **no other text is allowed**."]) { (convo, response, error, errorMessage) in
                guard error == nil else {
                    print("There was an error: \(error!.description)")
                    if let em = errorMessage {
                        print(em)
                    }
                    return
                }
                guard let c = response?.choices.first?.message.content else {return}
                onTitle(c.trimmingCharacters(in: ["\""]))
            }
        }
    }

    public enum ChatStreamEvent {
        case delta
        case end
        case error
    }
}
