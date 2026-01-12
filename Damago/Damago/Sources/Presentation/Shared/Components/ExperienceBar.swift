//
//  ExperienceBar.swift
//  Damago
//
//  Created by 박현수 on 1/8/26.
//

import UIKit

final class ExperienceBar: UIView {
    private let levelLabel: UILabel = {
        let label = UILabel()
        label.font = .body2
        label.textColor = .textPrimary
        return label
    }()

    private let expLabel: UILabel = {
        let label = UILabel()
        label.font = .caption
        label.textColor = .textSecondary
        label.textAlignment = .right
        return label
    }()

    private let progressView: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .bar)
        view.trackTintColor = .textTertiary
        view.progressTintColor = .damagoPrimary
        view.layer.cornerRadius = .smallElement
        view.clipsToBounds = true
        view.heightAnchor.constraint(equalToConstant: 8).isActive = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let textStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.alignment = .bottom
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        textStackView.addArrangedSubview(levelLabel)
        textStackView.addArrangedSubview(expLabel)

        addSubview(textStackView)
        addSubview(progressView)

        NSLayoutConstraint.activate([
            textStackView.topAnchor.constraint(equalTo: topAnchor),
            textStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textStackView.trailingAnchor.constraint(equalTo: trailingAnchor),

            progressView.topAnchor.constraint(equalTo: textStackView.bottomAnchor, constant: .spacingS),
            progressView.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

extension ExperienceBar {
    struct State: Equatable {
        let level: Int
        let currentExp: Int
        let maxExp: Int
    }

    func update(with state: State) {
        levelLabel.text = "Lv. \(state.level)"
        expLabel.text = "\(state.currentExp) / \(state.maxExp)"

        let ratio = state.maxExp > 0 ? Float(state.currentExp) / Float(state.maxExp) : 0
        progressView.setProgress(ratio, animated: true)
    }
}
