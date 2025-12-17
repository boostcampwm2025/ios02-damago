//
//  DynamicIslandIconImage.swift
//  Damago
//
//  Created by 김재영 on 12/17/25.
//

import SwiftUI

struct DynamicIslandIconImage: View {
    let iconImageName: String
    let size: CGFloat

    init(for iconImageName: String, size: CGFloat) {
        self.iconImageName = iconImageName
        self.size = size
    }

    var body: some View {
        Image(iconImageName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}
