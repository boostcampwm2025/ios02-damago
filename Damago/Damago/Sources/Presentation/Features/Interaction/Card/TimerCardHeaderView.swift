//
//  TimerCardHeaderView.swift
//  Damago
//
//  Created by Eden Landelyse on 1/25/26.
//

import UIKit
import SwiftUI

final class TimerCardHeaderView: UIView {
    private let missionBadge: CapsuleLabel = {
        let label = CapsuleLabel(padding: .init(top: .spacingXS, left: .spacingS, bottom: .spacingXS, right: .spacingS))
        label.text = "일일 미션"
        label.font = .caption
        label.textColor = .systemBlue
        label.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let rewardBadge: CapsuleLabel = {
        let label = CapsuleLabel(padding: .init(top: .spacingXS, left: .spacingS, bottom: .spacingXS, right: .spacingS))
        label.font = .caption
        label.backgroundColor = .systemOrange.withAlphaComponent(0.1)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .title2
        label.textColor = .textPrimary
        label.numberOfLines = 1
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let timerContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let hostingController: UIHostingController<CoolDownTimerView> = {
        let controller = UIHostingController(rootView: CoolDownTimerView(message: "", targetDate: nil))
        controller.view.backgroundColor = .clear
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        return controller
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    func configure(
        title: String,
        rightTitle: String = "",
        targetDate: Date? = nil,
        foods: Int? = nil,
        coins: Int? = nil,
        badge: String = "일일 미션"
    ) {
        missionBadge.text = badge
        titleLabel.text = title
        setupRewards(foods: foods, coins: coins)
        hostingController.rootView = CoolDownTimerView(message: rightTitle, targetDate: targetDate)
    }

    private func setupUI() {
        setupHierarchy()
        setupConstraints()
    }

    private func setupHierarchy() {
        [missionBadge, rewardBadge, titleLabel, timerContainerView].forEach {
            addSubview($0)
        }
        timerContainerView.addSubview(hostingController.view)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            missionBadge.topAnchor.constraint(equalTo: topAnchor),
            missionBadge.leadingAnchor.constraint(equalTo: leadingAnchor),

            rewardBadge.centerYAnchor.constraint(equalTo: missionBadge.centerYAnchor),
            rewardBadge.trailingAnchor.constraint(equalTo: trailingAnchor),

            titleLabel.topAnchor.constraint(equalTo: missionBadge.bottomAnchor, constant: .spacingM),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            timerContainerView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            timerContainerView.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: .spacingS),
            timerContainerView.trailingAnchor.constraint(equalTo: rewardBadge.trailingAnchor, constant: -.spacingXS),

            hostingController.view.topAnchor.constraint(equalTo: timerContainerView.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: timerContainerView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: timerContainerView.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: timerContainerView.bottomAnchor)
        ])
    }

    private func setupRewards(foods: Int?, coins: Int?) {
        let combinedString = NSMutableAttributedString()

        if let foods {
            combinedString.append(
                .iconWithText(
                    systemName: "carrot.fill",
                    text: "  +\(foods)",
                    iconColor: .damagoPrimary,
                    font: .caption
                )
            )
        }

        if foods != nil && coins != nil {
            combinedString.append(
                NSAttributedString(
                    string: "   |   ",
                    attributes: [
                        .font: UIFont.caption,
                        .foregroundColor: UIColor.lightGray.withAlphaComponent(0.5)
                    ]
                )
            )
        }

        if let coins {
            combinedString.append(
                .iconWithText(
                    systemName: "dollarsign.circle",
                    text: "  +\(coins)",
                    iconColor: .systemYellow,
                    font: .caption
                )
            )
        }

        rewardBadge.attributedText = combinedString
        rewardBadge.isHidden = (foods == nil && coins == nil)
    }
}
