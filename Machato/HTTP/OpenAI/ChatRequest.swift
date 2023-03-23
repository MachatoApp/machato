//
//  ChatRequest.swift
//  Machato
//
//  Created by Théophile Cailliau on 26/03/2023.
//

import Foundation
import Combine

actor ChatAPIManager {
    
    static public let shared : ChatAPIManager = .init();
    
    private var eventSources : [Conversation: EventSource] = [:];
    
    func cancel(_ c: Conversation) {
        eventSources[c]?.disconnect()
        eventSources.removeValue(forKey: c)
    }
    
    func registerEventSource(_ c: Conversation, _ e: EventSource) {
        cancel(c)
        eventSources[c] = e
    }
    
    func fetchLocalAIModelNames(endpoint: String) async throws -> [String] {
        guard let url = URL(string: "\(endpoint)/models".replacingOccurrences(of: "//", with: "/")) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        let jsonData : ModelList = try JSONDecoder().decode(ModelList.self, from: data)
        return jsonData.data.map { $0.id }
    }
    
    func checkOpenAIAPIKey(_ key : String) async -> Bool {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")

        let body = ["model": "ferdinand"]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            request.httpBody = jsonData
        } catch {
            print("Error serializing JSON: \(error.localizedDescription)")
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let responseStr = String(decoding: data, as: UTF8.self)
            return responseStr.contains("ferdinand")
        } catch {
            print("Error making request: \(error.localizedDescription)")
            return false
        }
    }
    
    typealias TokenCount = Int32
    
    @MainActor
    func buildURLRequest(_ convo: Conversation, additionalMessages: [String] = [], stream: Bool) async -> (URLRequest, TokenCount)? {
        guard let messages = convo.has_messages else {
            print("no messages in convo")
            return nil
        }
        convo.settings.updateModel()
        let model = convo.settings.model
        var tokencount : TokenCount = .zero;
        let url : URL
        switch model {
        case .none:
            return nil
        case .openai(_,_,_,_):
            url = URL(string: "https://api.openai.com/v1/chat/completions")!
        case .azure(_,let modelEntity,_,_):
            url = URL(string: "\(modelEntity.azure_company_endpoint ?? "")\((modelEntity.azure_company_endpoint?.hasSuffix("/") ?? false) ? "" : "/")openai/deployments/\(modelEntity.azure_deployment_name ?? "")/chat/completions?api-version=2023-05-15")!
            print(url)
        case .anthropic(_,_,_,_):
            url = URL(string: "https://api.anthropic.com/v1/complete")!
        case .local(_,_,let endpoint):
            url = URL(string: "\(endpoint.replacingOccurrences(of: "localhost", with: "127.0.0.1"))/v1/chat/completions".replacingOccurrences(of: "//", with: "/"))!
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Auth
        switch model {
        case .none:
            return nil
        case .openai(_, let modelEntity, _, _):
            request.addValue("Bearer \(modelEntity.openai_api_key ?? "")", forHTTPHeaderField: "Authorization")
        case .azure(_, let modelEntity, _, _):
            request.addValue("\(modelEntity.azure_api_key ?? "")", forHTTPHeaderField: "api-key")
        case .anthropic(_, let modelEntity, _, _):
            request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            request.addValue(modelEntity.anthropic_api_key ?? "", forHTTPHeaderField: "x-api-key")
        default:
            break
        }
        
        let settings = PreferencesManager.getConversationSettings(convo)
        
        await convo.countTokens()
        tokencount = convo.tokens - convo.excluded_tokens
        
        var body = [
            "temperature": settings.temperature,
            "top_p" : settings.topP,
            "presence_penalty" : settings.presencePenalty,
            "frequency_penalty" : settings.frequencyPenalty,
            "stream": stream,
        ] as [String : Any]
        
        var msgs = [["role": "system", "content": settings.prompt]]
        messages.sortedArray(using: [NSSortDescriptor(keyPath: \Message.date, ascending: true)]).forEach() {m in
            guard let mcast = m as? Message else {
                print("Message from convo messages was not castable do MessageEntity")
                return
            }
            guard mcast.content?.isEmpty == false else { return }
            guard mcast.include_in_requests else { return }
            msgs.append( {
                var e = ["role": mcast.is_function ? "function" : mcast.is_response ? "assistant" : "user", "content": mcast.content ?? ""]
                if mcast.is_function {
                    e["name"] = mcast.function_name
                }
                return e
            }())
        }
        msgs.append(contentsOf: additionalMessages.map { am in
            return ["role" : "user", "content": am]
        })
        
        if case .openai(_,_,_,_) = model {
            body["messages"] = msgs
        }
        if case .azure(_,_,_,_) = model {
            body["messages"] = msgs
        }
        if case .local(_,_,_) = model {
            body["messages"] = msgs
        }
        if case .anthropic(_,_,let assoc,_) = model {
            body["prompt"] = msgs.reduce("", { acc, v in
                acc + "\n\n\(v["name"] == "assistant" ? "Assistant" : "Human"):\(v["content"] ?? "")"
            }) + "\n\nAssistant:"
            body["max_tokens_to_sample"] = assoc.contextLength
            body["model"] = assoc.rawValue
            body["stop_sequences"] = ["\n\nHuman:", "<<<<<"]
            body.removeValue(forKey: "presence_penalty")
            body.removeValue(forKey: "frequency_penalty")
            print(body["prompt"] ?? "no prompt")
        }
        
        if case .openai(_, _, let assoc, _) = model {
            body["model"] = assoc.rawValue
            if model.supportsFunctions,
               let functions = try? settings.enabledFunctions.map({ try FunctionsManager.shared.function(from: $0) }),
               !functions.isEmpty {
                body["functions"] =
                functions.reduce([] as [[String : Any]], { acc, fun in
                    let new = [[
                        "name": fun.name,
                        "description": fun.description,
                        "parameters": fun.parameters
                    ]] as [[String : Any]]
                    return acc + new
                    })
                body["function_call"] = "auto"
            }
            print(assoc.rawValue)
        }
        if case .local(_, let modelName, _) = model {
            body["model"] = modelName
        }
        
        if !settings.manageMax {
            body["max_tokens"] = settings.maxTokens
        }
        
//        print(body)

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            request.httpBody = jsonData
        } catch {
            print("Error serializing JSON: \(error.localizedDescription)")
        }
        return (request, tokencount)
    }
    
    func sendChatRequest(_ convo: Conversation, additionalMessages: [String] = [], onResponse: @escaping (Conversation, ChatResponse?, ChatResponseError?, String?) -> Void) async {
        let settings = PreferencesManager.getConversationSettings(convo)
        let onResponseMainThread = { (a,b,c,d) in
            PreferencesManager.shared.persistentContainer.viewContext.perform {
                onResponse(a,b,c,d)
            }
        }
        guard await LicenseManager.shared.checkLicense() else {
            print("License was incorrect !")
            onResponse(convo, nil, .license_invalid, PreferencesManager.shared.license_key.count > 0 ? ChatResponseError.license_invalid_message : ChatResponseError.license_key_empty)
            return
        }
        await settings.updateModel()
        if case .none = settings.model {
            print("Model was none!")
            onResponse(convo, nil, .model_invalid, ChatResponseError.model_was_none)
            return
        }
        guard settings.model.api_key != "" || settings.model.type == .local else {
            print("API key empty!")
            onResponse(convo, nil, .api_invalid, ChatResponseError.api_key_empty)
            return
        }
        guard let (request, tokencount) = await buildURLRequest(convo, additionalMessages: additionalMessages, stream: false) else {
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
                let m = jsonData.choices.first?.message.content
                TokenUsageManager.shared.registerTokens(count: tokencount,
                                                        model: settings.model,
                                                        sent: true)
                TokenUsageManager.shared.registerTokens(count: TokenCounter.shared.countTokens(m),
                                                        model: settings.model,
                                                        sent: false)
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
                             onEvent: @escaping (ChatStreamEvent) -> Void) async {
        let settings = PreferencesManager.getConversationSettings(convo)
        guard await LicenseManager.shared.checkLicense() else {
            print("License was incorrect !")
            onEvent(.error(error: .license_invalid, desc: ChatResponseError.license_invalid_message))
            return
        }
        if case .none = settings.model {
            print("Model was none!")
            onEvent(.error(error: .model_invalid, desc: ChatResponseError.model_was_none))
            return
        }
        guard settings.model.api_key != "" || settings.model.type == .local else {
            onEvent(.error(error: .api_invalid, desc: ChatResponseError.api_key_empty))
            return
        }
        guard let (request, tokencount) = await buildURLRequest(convo, stream: true) else {
            onEvent(.error(error: .network_error, desc:"Could not build the URL request necessary to engage in event listening."))
            return //TODO: handle this
        }
        var completionString : String = ""
        let eventSource = EventSource(url: request)
        registerEventSource(convo, eventSource)
        let onEventMainThread = { (event: ChatStreamEvent) in
            DispatchQueue.main.async {
                onEvent(event)
            }
        }
        
        let publisher = PassthroughSubject<String, Never>()
        let tokenPublisher = PassthroughSubject<(), Never>()
        
        let cancellable = publisher
            .throttle(for: .milliseconds(100), scheduler: DispatchQueue.main, latest: true) // TODO: get rid of this when lag is fixed
            .sink { value in
                onEventMainThread(.update(completion: value))
            }
        
        let tokenCancellable = tokenPublisher
            .throttle(for: .milliseconds(1000), scheduler: DispatchQueue.main, latest: true)
            .sink {
                convo.countTokens()
            }
        
        var functionCall : (name: String, arguments: String) = (name: "", arguments: "")
        
        // Anthropic event
        eventSource.addEventListener("completion") { id, event, data in
            guard let d = data else { return }
            do {
                let anthropicChatDelta : AnthropicChatDelta = try JSONDecoder().decode(AnthropicChatDelta.self, from: d.data(using: .utf8)!)
                let d = anthropicChatDelta.completion
                TokenUsageManager.shared.registerTokens(count: TokenCounter.shared.countTokens(d),
                                                        model: settings.model,
                                                        sent: false)
                completionString += d
                //onEventMainThread(.delta(delta: jsonData))
                //onEventMainThread(.update(completion: completionString))
                tokenPublisher.send(())
                publisher.send(completionString)
            } catch {
                if let error = try? JSONDecoder().decode(APIError.self, from: d.data(using: .utf8)!) {
                    print("API Error returned: \(d)")
                    onEventMainThread(.error(error: .api_error, desc: [error.error.message, error.error.code ?? "", error.error.type, "Unknown"].first { $0.isEmpty == false }))
                } else {
                    print("data could not be json-parsed: \(data ?? "no data")")
                }
            }
        }
        
        // Anthropic error
        eventSource.addEventListener("error") { id, event, data in
            onEventMainThread(.error(error: .api_error, desc: data ?? "N/A"))
        }
        
        eventSource.onMessage { (id, event, data) in
            guard let d = data else { return }
            do {
                    let jsonData : StreamedChatDelta = try JSONDecoder().decode(StreamedChatDelta.self, from: d.data(using: .utf8)!)
                    if let fc = jsonData.choices.first?.delta.function_call {
                        if let name = fc.name {
                            TokenUsageManager.shared.registerTokens(count: TokenCounter.shared.countTokens(name),
                                                                    model: settings.model,
                                                                    sent: false)
                            functionCall.name += name
                        }
                        if let arg = fc.arguments {
                            TokenUsageManager.shared.registerTokens(count: TokenCounter.shared.countTokens(arg),
                                                                    model: settings.model,
                                                                    sent: false)
                            
                            functionCall.arguments += arg
                        }
                        tokenPublisher.send()
                        onEventMainThread(.updateFunction(name: functionCall.name, arguments: functionCall.arguments))
                        //                    print(functionCall)
                    } else {
                        let d = jsonData.choices.first?.delta.content ?? ""
                        TokenUsageManager.shared.registerTokens(count: TokenCounter.shared.countTokens(d),
                                                                model: settings.model,
                                                                sent: false)
                        completionString += d
                        //onEventMainThread(.delta(delta: jsonData))
                        //onEventMainThread(.update(completion: completionString))
                        tokenPublisher.send(())
                        publisher.send(completionString)
                    }
            } catch {
                if String(data: d.data(using: .utf8)!, encoding: .utf8)?.contains("chat.completion.chunk") ?? false {
                    print("Some completion chunk could not be parsed. This could be an ending delta.")
                } else if String(data: d.data(using: .utf8)!, encoding: .utf8)?.contains("[DONE]") ?? false {
                    // nothing to do
                } else if let error = try? JSONDecoder().decode(APIError.self, from: d.data(using: .utf8)!) {
                    print("API Error returned: \(d)")
                    onEventMainThread(.error(error: .api_error, desc: [error.error.message, error.error.code ?? "", error.error.type, "Unknown"].first { $0.isEmpty == false }))
                } else {
                    print("data could not be json-parsed: \(data ?? "no data")")
                }
            }
        }
        eventSource.connect()
        eventSource.onComplete() { (code, shouldReconect, err, buffer) in
            guard let c = code else {
                print("Gone wrong! There was no completion code")
                onEventMainThread(.error(error: .network_error, desc: "The final delta yielded no http response code. Error: \(err?.description ?? "")"))
                return
            }
            if (200...299).contains(c) {
                TokenUsageManager.shared.registerTokens(count: tokencount,
                                                        model: settings.model,
                                                        sent: true)
                cancellable.cancel()
                tokenCancellable.cancel()
                onEventMainThread(.end(completion: completionString))
                eventSource.disconnect()
                if !functionCall.name.isEmpty {
                    onEventMainThread(.function(name: functionCall.name, arguments: functionCall.arguments))
                    print(functionCall)
                }
                return
            }
            do {
                let jsonError : APIError = try JSONDecoder().decode(APIError.self, from: (buffer ?? "").data(using: .utf8)!)
                onEventMainThread(.error(error: .api_error, desc: [jsonError.error.message, jsonError.error.code ?? "", jsonError.error.type, "Unknown"].first { $0.isEmpty == false }))
            } catch {
                print("Failed to serialize into APIError")
                print(buffer ?? "empty buffer")
                onEventMainThread(.error(error: .unknown, desc: "The response could not be serialized into an API response or an API error. The HTTP return code was \(c). Response was: \n\n \(buffer ?? "")"))
            }
        }
    }
    
    func getTitle(_ c: Conversation, onTitle: @escaping (@MainActor (String) -> Void)) {
        Task {
            await sendChatRequest(c, additionalMessages: ["What would be a short and relevant title for this chat? Answer in the language of the message above. Be very succinct. You must strictly answer with only the title, **no other text is allowed**."]) { (convo, response, error, errorMessage) in
                guard error == nil else {
                    print("There was an error: \(error!.description)")
                    if let em = errorMessage {
                        print(em)
                    }
                    return
                }
                guard var c = response?.choices.first?.message.content else {return}
                c = c.replacing(#/^Title:? ?/#, maxReplacements: 1, with: { _ in return "" })
                c = c.trimmingCharacters(in: ["\"", "."])
                DispatchQueue.main.async { [c] in
                    onTitle(c)
                }
            }
        }
    }

    public enum ChatStreamEvent {
        case delta(delta: StreamedChatDelta)
        case update(completion: String)
        case updateFunction(name: String, arguments: String)
        case end(completion: String)
        case error(error: ChatResponseError, desc: String? = nil)
        case function(name: String, arguments: String)
    }
}
