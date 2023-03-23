//
//  TokenUsagePriceTag.swift
//  Machato
//
//  Created by Théophile Cailliau on 10/05/2023.
//

import SwiftUI

struct TokenUsagePriceTag: View {
    @ObservedObject private var tokenManager : TokenUsageManager = TokenUsageManager.shared;
    @AppStorage(PreferencesManager.StoredPreferenceKey.defaultTokenCountTimespan) private var tokenTimespan : String = TokenCountTimespan.default_case.rawValue;

    var body: some View {
        HStack {
            switch TokenCountTimespan.fromString(tokenTimespan) {
            case .day:
                Text("Today's cost:")
            case .month:
                Text("This month's cost:")
            case .week:
                Text("This week's cost:")
            case .all_time:
                Text("All time cost:")
            }
            Chip(String(format: "$%.4f", tokenManager.cost))
        }
    }
}
