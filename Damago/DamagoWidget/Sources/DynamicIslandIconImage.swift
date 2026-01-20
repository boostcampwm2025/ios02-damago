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
        let firstFrame = UIImage(named: iconImageName)?
            .crop(rect: CGRect(origin: .zero, size: CGSize(width: 32, height: 32)))
        Image(uiImage: firstFrame!)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}
