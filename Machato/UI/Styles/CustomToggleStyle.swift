//
//  CustomToggleStyle.swift
//  Machato
//
//  Created by Théophile Cailliau on 21/04/2023.
//

import Foundation
import SwiftUI

struct CustomToggleStyle : ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack (alignment: .top, spacing: 0){
            configuration.label.onTapGesture {
                configuration.$isOn.wrappedValue.toggle()
            }
            Spacer()
            Toggle(isOn: configuration.$isOn, label: { EmptyView() }).labelsHidden()
                .toggleStyle(.checkbox)
        }
    }
}

extension ToggleStyle where Self == CustomToggleStyle {
    static var checkboxRight : Self { .init() };
}
