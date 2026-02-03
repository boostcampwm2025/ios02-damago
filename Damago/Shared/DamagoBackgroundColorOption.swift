//
//  DamagoBackgroundColorOption.swift
//  Damago
//
//  Created by loyH on 2/3/26.
//

import Foundation
import UIKit
import SwiftUI

enum DamagoBackgroundColorOption: String, CaseIterable, Hashable {
    case damagoPrimary
    case damagoSecondary
    case black
    case white

    static var defaultOption: DamagoBackgroundColorOption { .damagoPrimary }

    var displayName: String {
        switch self {
        case .damagoPrimary: return "다마고 프라이머리"
        case .damagoSecondary: return "다마고 세컨더리"
        case .black: return "블랙"
        case .white: return "화이트"
        }
    }

    var colorAssetName: String { rawValue }

    var uiColor: UIColor {
        switch self {
        case .damagoPrimary, .damagoSecondary:
            return UIColor(named: colorAssetName) ?? .clear
        case .black:
            return .black
        case .white:
            return .white
        }
    }

    var swiftUIColor: Color {
        switch self {
        case .damagoPrimary, .damagoSecondary:
            return Color(colorAssetName)
        case .black:
            return Color.black
        case .white:
            return Color.white
        }
    }
}
