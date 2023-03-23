//
//  Chip.swift
//  Machato
//
//  Created by Théophile Cailliau on 30/03/2023.
//

import SwiftUI

struct Chip: View {
    private var content : String = ""
    
    init(_ s: String) {
        content = s
    }
    var body: some View {
        Text(content)
            .padding(5)
            .background(AppColors.chipBackgroundColor)
            .cornerRadius(5)
            .bold(true)
            .foregroundColor(.gray)
            .font(.body.monospaced())
    }
}

struct Chip_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            Divider()
            Chip("GPT-4")
            Divider()
            Spacer()
        }
    }
}
