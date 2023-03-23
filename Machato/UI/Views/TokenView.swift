//
//  TokenView.swift
//  Machato
//
//  Created by Théophile Cailliau on 22/04/2023.
//

import Foundation
import SwiftUI
import Charts
import WrappingStack

struct TokenChart : View {
    private enum TokenUsageOrEmpty : Hashable {
        case empty(date: Date)
        case tokenUsage(tu: TokenUsage, date: Date)
    }
    private var pageOffset : Int = .zero;
    private var timespan : TokenCountTimespan;
    
    init(pageOffset: Int, timespan: TokenCountTimespan) {
        self.pageOffset = pageOffset
        self.timespan = timespan
    }
    
    private var tus : ([TokenUsageOrEmpty], Int32) {
        guard timespan != .all_time else { return (tokenUsageEntities.map { .tokenUsage(tu: $0, date: $0.day ?? Date.now)}, 0) }
        var result : [TokenUsageOrEmpty] = []
        var maxTokens : Int32 = .zero;
        for column in ((pageOffset-1)*7 + 1)..<(pageOffset*7 + 1) {
            let startDate = getColumnStartingDate(offset: column, timespan: timespan)!
            let endDate = getColumnEndingDate(offset: column, timespan: timespan)!
            var current = startDate
            var columnResult : [TokenUsageOrEmpty] = []
            var columnTotal : Int32 = 0;
            while current <= endDate {
                let tus = tokenUsageEntities.filter ({ $0.day == current })
                if !tus.isEmpty {
                    columnResult.append(contentsOf: tus.map { v in
                        columnTotal += v.count
                        return .tokenUsage(tu: v, date: startDate)
                    })
                }
                current = Calendar.current.date(byAdding: .day, value: 1, to: current)!
            }
            maxTokens = max(maxTokens, columnTotal)
            columnResult.sort { a, b in
                switch (a, b) {
                case (.tokenUsage(let tua, _), .tokenUsage(let tub, _)):
                    guard let ma = tua.model,
                          let mb = tub.model
                    else { return false }
                    return (ma < mb) || (ma == mb && tua.sent && !tub.sent)
                default:
                    return false
                }
            }
            if columnResult.count == 0 {
                columnResult.append(.empty(date: startDate))
            }
            result.append(contentsOf: columnResult)
        }
        return (result, maxTokens)
    };
        
    func getColumnEndingDate(offset: Int, timespan: TokenCountTimespan) -> Date? {
        guard let nextStartingDate = getColumnStartingDate(offset: offset+1, timespan: timespan)
        else { return nil }
        return Calendar.current.date(byAdding: .day,
                                     value: -1,
                                     to: nextStartingDate)
    }
    
    func getColumnStartingDate(offset: Int, timespan: TokenCountTimespan) -> Date? {
        let now = Date()
        let prefLanguage = Locale.preferredLanguages[0]
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = NSLocale(localeIdentifier: prefLanguage) as Locale
        let components = calendar.dateComponents([.year, .month, .day], from: now)
        let todayDate = calendar.date(from: components)!
        switch timespan {
        case .day:
            return calendar.date(byAdding: .day, value: offset, to: todayDate)
        case .week:
            let weekday = 1 + ((calendar.component(.weekday, from: todayDate) - (calendar.firstWeekday - 1) + 6) % 7)
            let startOfWeek = calendar.date(byAdding: .day, value: -weekday+1, to: todayDate)!
            return calendar.date(byAdding: .day, value: 7*offset, to: startOfWeek)
        case .month:
            let components = calendar.dateComponents([.year, .month], from: now)
            let thisMonth = calendar.date(from: components)!
            return calendar.date(byAdding: .month, value: offset, to: thisMonth)
        case .all_time:
            return nil
        }
    }
    
    @FetchRequest(sortDescriptors: [
        NSSortDescriptor(keyPath: \TokenUsage.day, ascending: true),
        NSSortDescriptor(keyPath: \TokenUsage.model, ascending: true),
        NSSortDescriptor(keyPath: \TokenUsage.sent, ascending: true),
    ]) private var tokenUsageEntities : FetchedResults<TokenUsage>;
    
    @State private var selectedDay : String? = nil;
    @State private var selectedModel : String? = nil;
    @State private var showToggle : Bool = false;
    
    var body: some View {
        if timespan == .all_time {
            let total = try! getTokenCount()
            VStack {
                HStack {
                    GeometryReader { proxy in
                        ZStack (alignment: .center) {
                            Circle().hover(selected: $selectedModel)
                                .foregroundColor(.black)
                                .opacity(1)
                            ForEach(total.0.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                ZStack(alignment: .center) {
                                    Arc(startAngle: .degrees(360 * Double(value.0) /  Double(total.3)),
                                        endAngle: .degrees(360 * Double(value.1) /  Double(total.3))
                                    ).hover(selected: $selectedModel,
                                            title: key).opacity(0)
                                    Arc(startAngle: .degrees(360 * Double(value.0) /  Double(total.3)),
                                        endAngle: .degrees(360 * Double(value.1) /  Double(total.3))
                                    )
                                    .foregroundColor(value.2)
                                    .opacity([key, nil].contains(selectedModel) ? 1 : 0.9)
                                    .scaleEffect(selectedModel == key ? 1.1 : 1, anchor: .center)
                                    
                                }
                            }
                        }
                    }.frame(width: 280, height: 280).padding([.trailing], 20)
                    Spacer()
                    VStack(alignment: .leading) {
                        
                        if let sm = selectedModel?.split(separator: "/").map({ String($0) }) {
                            let model = sm[0]
                            let type = sm[1]
                            Text("Model: ").bold() + Text(model).font(.body.monospaced())
                            Text("Type: ").bold() + Text(type).font(.body.monospaced())
                            Divider()
                            if let thisCount = total.0[selectedModel!], let thisCost = total.1[selectedModel!] {
                                HStack {
                                    Text("Tokens: ").bold() + Text((thisCount.1-thisCount.0).description + "  ").font(.body.monospaced())
                                    Spacer()
                                    Text(String(format: "(%.0f%%)", 100*Double(thisCount.1-thisCount.0)/Double(total.3))).foregroundColor(.gray)
                                }
                                HStack {
                                    Text("Cost: ").bold() + Text(String(format: "$%.4f  ", thisCost)).font(.body.monospaced())
                                    Spacer()
                                    Text(String(format: "(%.0f%%)", 100*thisCost/total.4)).foregroundColor(.gray)
                                }
                            }
                        } else {
                            Text("Total usage").bold()
                            Divider()
                            Text("Tokens: ").bold() + Text(total.3.description).font(.body.monospaced())
                            Text("Cost: ").bold() + Text(String(format: "$%.4f", total.4)).font(.body.monospaced())
                        }
                    }
                }
                WrappingHStack(id: \.key, alignment: .center, horizontalSpacing: 5) {
                    ForEach(total.0.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        HStack {
                            Circle().fill(value.2).frame(width: 10, height: 10)
                            Text(key).font(.footnote)
                        }.onHover { v in
                            if v {
                                //DispatchQueue.main.async {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        selectedModel = key
                                    }
                                //}
                            }
                        }
                    }
                }.padding([.top, .bottom], 20)
                    .onHover { v in
                        if !v {
                            DispatchQueue.main.async {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selectedModel = nil
                                }
                            }
                        }
                    }
                Spacer()
            }
        } else {
            Chart {
                ForEach(tus.0, id: \.self) { tuoe in
                    switch tuoe {
                    case .empty(let date):
                        BarMark(x: .value("Date", getDateAsString(date: date)), y: .value("Token count", 0))
                    case .tokenUsage(let tu, let date):
                        BarMark(x: .value("Date", getDateAsString(date: date)), y: .value("Token count", showToggle ? tu.count : 0))
                            .foregroundStyle(by: .value("Type", labelFromTu(tu: tu)))
                    }
                }
                if let selectedDay {
                    let tc = try! getTokenCount(selectedDay)
                    RectangleMark(x: .value("Date", selectedDay))
                        .foregroundStyle(.primary.opacity(0.2))
                        .annotation(
                            position: tc.2 > 3 ? .leading : .trailing,
                            alignment: .center, spacing: 0
                        ) {
                            VStack (alignment: .leading){
                                if tc.0.isEmpty {
                                    Text("No data")
                                } else {
                                    Text("Tokens").bold()
                                    ForEach(tc.0.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                        Text("\(key) : \(value.1-value.0)")
                                    }
                                    Divider()
                                    Text("Expenses").bold()
                                    ForEach(tc.1.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                        Text("\(key) : \(String(format: "$%.4f", value))")
                                    }
                                    Divider()
                                    Text("Total").bold()
                                    Text("Tokens: \(tc.3)")
                                    Text("Cost: \(String(format: "$%.4f", tc.4))")
                                }
                            }.padding(5).background(AppColors.chatBackgroundColor)
                        }
                }
            }.chartYScale(domain: 0 ... max(10_000, Int32(Double(tus.1) * 1.1)))
            .chartOverlay { (chartProxy: ChartProxy) in
                Color.clear
                    .onContinuousHover { hoverPhase in
                        switch hoverPhase {
                        case .active(let hoverLocation):
                            selectedDay = chartProxy.value(
                                atX: hoverLocation.x, as: String.self
                            )
                        case .ended:
                            selectedDay = nil
                        }
                    }
            }.frame(minHeight: 300)
                .onAppear {
                    withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)) {
                        showToggle = true
                    }
                }.onChange(of: pageOffset) { _ in
                    showToggle = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)) {
                            showToggle = true
                        }
                    }
                }.onChange(of: timespan) { _ in
                    showToggle = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)) {
                            showToggle = true
                        }
                    }
                }
        }
        
    }
    
    func getDateAsString(date: Date) -> String {
        let df = DateFormatter()
        switch timespan {
        case .day, .week:
            df.dateFormat = "dd/MM"
        case .month:
            df.dateFormat = "MMM"
        default:
            break
        }
        return df.string(from: date)
    }
    
    private func getDateAsString(from: TokenUsageOrEmpty) -> String {
        switch from {
        case .empty(let date):
            return getDateAsString(date: date)
        case .tokenUsage(_, let date):
            return getDateAsString(date: date)
        }
    }
    
    enum ChartError : Error {
        case emptyName
        case error(error : String)
    }
    
    func getTokenCount(_ selected: String = "") throws -> ([String : (Int32, Int32, Color)], [String : Double], Int, Int32, Double) {
        let colors : [Color] = {
            let c: [Color] = [.blue, .green, .orange, .purple, .red, .teal, .pink, .yellow, .indigo, .brown, .cyan, .mint]
            return c + c.map { $0.opacity(0.5) }
        }()
        guard OpenAIChatModel.allCases.count * 2 <= colors.count else {
            throw ChartError.error(error: "Not enough colors to display chart")
        }
        var count: [String: (Int32, Int32, Color)] = [:]
        var totalCount : Int32 = .zero
        var price: [String : Double] = [:];
        var totalCost : Double = .zero
        tus.0.filter { (timespan == .all_time) || getDateAsString(from: $0) == selected} .forEach { tuoe in
            switch tuoe {
            case .empty:
                break
            case .tokenUsage(let tu, _):
                let label = labelFromTu(tu: tu)
                count[label] = count[label] ?? (0, 0, colors[0])
                count[label]!.1 += tu.count
                totalCount += tu.count
                price[label] = price[label] ?? 0
                price[label]! += Double(tu.count) * tu.cost / 1000
                totalCost += Double(tu.count) * tu.cost / 1000
            }
        }
        let keys = count.map { $0.key }.sorted(by: <)
        for i in keys.indices.dropFirst() {
            let (_, c, _) = count[keys[i]] ?? (0,0, .clear);
            count[keys[i]]!.0 = count[keys[i-1]]!.1
            count[keys[i]]!.1 = count[keys[i]]!.0 + c
            count[keys[i]]!.2 = colors[i]
        }
        return (count, price, tus.0.firstIndex { getDateAsString(from: $0) == selected} ?? 0, totalCount, totalCost)
    }
    
    func labelFromTu(tu: TokenUsage) -> String {
        "\(tu.model ?? "?")/\(tu.sent ? "Sent" : "Received")"
    }
}
