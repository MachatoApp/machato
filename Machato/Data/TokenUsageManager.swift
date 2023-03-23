//
//  TokenUsageManager.swift
//  Machato
//
//  Created by Théophile Cailliau on 14/04/2023.
//

import Foundation
import CoreData
import Combine


class TokenUsageManager : ObservableObject {
    static let shared : TokenUsageManager = .init()
    
    let publisher = PassthroughSubject<(), Never>()
    var cancellable : Cancellable? = nil;
    
    init() {
        cancellable = publisher.throttle(for: .milliseconds(500), scheduler: DispatchQueue.main, latest: true)
            .sink {
                self.objectWillChange.send()
            }
    }
    
    private let persistentContainer = PreferencesManager.shared.persistentContainer
    private let backgroundContext = PreferencesManager.shared.backgroundContext
    private var todaysTokens : [TokenUsage] = [];
    private(set) var lastDay : Date? = nil;
    private(set) var cost : Double = .zero;
    
    private var today: Date {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: now)
        let todayDate = calendar.date(from: components)!
        return todayDate
    }
    
     var lastMonth : Date {
        let currentDate = today
        let calendar = Calendar.current

        return calendar.date(byAdding: .month, value: -1, to: currentDate)!
    }
    
    var lastWeek : Date {
        let currentDate = today
        let calendar = Calendar.current

        return calendar.date(byAdding: .day, value: -7, to: currentDate)!
    }
    
    private func getTokensPeriod(for tsp: TokenCountTimespan) -> [TokenUsage]? {
        let fr = TokenUsage.fetchRequest()
        switch tsp {
        case .day:
            fr.predicate = NSPredicate(format: "%K == %@", #keyPath(TokenUsage.day), today as CVarArg)
        case .week:
            fr.predicate = NSPredicate(format: "%K >= %@", #keyPath(TokenUsage.day), lastWeek as CVarArg)
        case .month:
            fr.predicate = NSPredicate(format: "%K >= %@", #keyPath(TokenUsage.day), lastMonth as CVarArg)
        case .all_time:
            break
        }
        var results : [TokenUsage]? = nil;
        backgroundContext.performAndWait {
            results = try? backgroundContext.fetch(fr)
        }
        return results
    }
    
    private func getTodaysTokens() {
        let fr = TokenUsage.fetchRequest()
        fr.predicate = NSPredicate(format: "%K == %@", #keyPath(TokenUsage.day), today as CVarArg)
        do {
            todaysTokens = try backgroundContext.fetch(fr)
        } catch {
            print("Could not fetch core data token usage")
            print(error)
        }
        lastDay = today
    }
    
    private func getTokenUsage(model: ModelDescriptor, sent: Bool) -> TokenUsage {
        var name : String? = nil
        var pricing : ModelCost? = nil
        switch model {
        case .openai(let n, _, _, let p), .azure(let n, _, _, let p), .anthropic(let n, _, _, let p):
            name = n
            pricing = p
        case .local(let n, _, _):
            name = n
            pricing = ModelCost(sent: 0, received: 0)
        case .none:
            break
        }
        if lastDay != today {
            getTodaysTokens()
        }
        if let match = todaysTokens.filter({ $0.sent == sent && $0.model == name }).first {
            return match
        }
        let tu = TokenUsage(context: backgroundContext)
        tu.model = name
        tu.sent = sent
        let cm = pricing ?? ModelCost()
        tu.cost = sent ? cm.sent : cm.received
        tu.count = 0
        tu.day = today
        todaysTokens.append(tu)
        return tu
    }
    

    
    func registerTokens(count: Int32, model: ModelDescriptor, sent: Bool) {
//        #if DEBUG
//        print("Registering \(count.description) tokens")
//        #endif
        backgroundContext.perform {
            let tu = self.getTokenUsage(model: model, sent: sent)
            tu.count += count;
            self.cost += Double(count) * tu.cost / 1000
//            #if DEBUG
//            print("New cost: \(self.todaysCost.description)")
//            #endif
            self.publisher.send()
        }
    }
    
    func clearTokenHistory() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "TokenUsage")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try persistentContainer.persistentStoreCoordinator.execute(deleteRequest, with: backgroundContext)
        } catch let error as NSError {
            print(error)
        }
        getTodaysTokens()
        updateCost()
    }
    
    func updateCost() {
        guard let tokens = getTokensPeriod(for: PreferencesManager.shared.defaultTokenCountTimespan) else { return }
        backgroundContext.perform {
            var s : Double = .zero;
            tokens.forEach { tu in
                s += Double(tu.count) * tu.cost / 1000
            }
            self.persistentContainer.viewContext.perform {
                self.cost = s
                self.publisher.send()
            }
            try? self.backgroundContext.save()
        }
    }
}
