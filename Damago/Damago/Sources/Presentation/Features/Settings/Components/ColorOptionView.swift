//
//  ColorOptionView.swift
//  Damago
//
//  Created by loyH on 2/3/26.
//

import UIKit
import Combine

final class ColorOptionView: UIView {
    let option: DamagoBackgroundColorOption
    let button: UIButton
    let badge: CapsuleLabel

    init(option: DamagoBackgroundColorOption) {
        self.option = option
        self.button = UIButton(type: .system)
        self.badge = CapsuleLabel(
            padding: .init(top: .spacingXS, left: .spacingS, bottom: .spacingXS, right: .spacingS)
        )
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false

        button.backgroundColor = option.uiColor
        button.layer.cornerRadius = 26
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray4.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 52).isActive = true
        button.heightAnchor.constraint(equalToConstant: 52).isActive = true
        button.accessibilityLabel = option.displayName

        badge.text = "Selected"
        badge.font = .caption
        badge.textColor = .white
        badge.backgroundColor = .damagoPrimary
        badge.textAlignment = .center
        badge.isHidden = true
        badge.translatesAutoresizingMaskIntoConstraints = false

        addSubview(button)
        addSubview(badge)

        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            button.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 12),

            badge.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            badge.bottomAnchor.constraint(equalTo: button.topAnchor, constant: -.spacingXS),

            widthAnchor.constraint(equalToConstant: 60),
            heightAnchor.constraint(equalToConstant: 80)
        ])
    }
}
