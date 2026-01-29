//
//  UILabel+ScreenTitle.swift
//  Damago
//
//  Created by loyH on 1/27/26.
//

import UIKit

extension UILabel {
    /// InteractionView, MiniGameView 등 화면 상단 타이틀 스타일
    /// - font: 34pt bold, textColor: .textPrimary
    static func makeScreenTitle() -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = .textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    /// InteractionView 서브타이틀 스타일
    /// - font: .body3, textColor: .textTertiary, numberOfLines: 0
    static func makeScreenSubtitle() -> UILabel {
        let label = UILabel()
        label.font = .body3
        label.textColor = .textTertiary
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
}
