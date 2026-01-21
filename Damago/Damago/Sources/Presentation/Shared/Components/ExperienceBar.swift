//
//  ExperienceBar.swift
//  Damago
//
//  Created by 박현수 on 1/8/26.
//

import Combine
import UIKit

final class ExperienceBar: UIView {
    private let levelUpSubject = PassthroughSubject<Int, Never>()
    var levelUpPublisher: AnyPublisher<Int, Never> {
        levelUpSubject.eraseToAnyPublisher()
    }

    private var currentState: State?

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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // 완전한 캡슐 형태를 위해 높이의 절반으로 cornerRadius 설정
        let radius = progressView.bounds.height / 2
        progressView.layer.cornerRadius = radius
        
        // UIProgressView의 내부 subview들도 동일한 cornerRadius 적용
        progressView.subviews.forEach { subview in
            subview.layer.cornerRadius = radius
            subview.clipsToBounds = true
        }
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
        
        var progress: Float {
            maxExp > 0 ? Float(currentExp) / Float(maxExp) : 0
        }
    }

    func update(with newState: State) {
        let oldLevel = currentState?.level ?? 0
        currentState = newState

        if oldLevel > 0 && oldLevel < newState.level {
            levelUpSubject.send(newState.level)
        }

        updateUI()
    }

    private func updateUI() {
        guard let state = currentState else { return }
        levelLabel.text = "Lv. \(state.level)"
        expLabel.text = "\(state.currentExp) / \(state.maxExp)"
        progressView.setProgress(state.progress, animated: true)
    }
}
