//
//  BalanceGameChoiceView.swift
//  Damago
//
//  Created by Eden Landelyse on 1/25/26.
//

import UIKit

final class BalanceGameChoiceView: UIView {
    private(set) lazy var leftChoiceButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(
            top: .spacingM,
            leading: .spacingM,
            bottom: .spacingM,
            trailing: .spacingM + .spacingS
        )
        let button = UIButton(configuration: config)
        button.backgroundColor = UIColor(red: 0.4, green: 0.5, blue: 0.8, alpha: 1.0)
        button.layer.borderColor = UIColor.systemGreen.cgColor
        button.layer.borderWidth = 0
        button.layer.cornerCurve = .continuous
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private(set) lazy var rightChoiceButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(
            top: .spacingM,
            leading: .spacingM + .spacingS,
            bottom: .spacingM,
            trailing: .spacingM
        )
        let button = UIButton(configuration: config)
        button.backgroundColor = UIColor(red: 1.0, green: 0.6, blue: 0.6, alpha: 1.0)
        button.layer.borderColor = UIColor.systemGreen.cgColor
        button.layer.borderWidth = 0
        button.layer.cornerCurve = .continuous
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let vsLabel: UILabel = {
        let label = UILabel()
        label.text = "VS"
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = .black
        label.textAlignment = .center
        label.backgroundColor = .white
        label.layer.cornerRadius = .largeCard
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let leftTagLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .bold)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        label.textAlignment = .center
        label.layer.cornerRadius = 9
        label.clipsToBounds = true
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let rightTagLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .bold)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        label.textAlignment = .center
        label.layer.cornerRadius = 9
        label.clipsToBounds = true
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let activeBorderWidth: CGFloat = .spacingS

    // MARK: - 초기화

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = .largeCard
        clipsToBounds = true

        [leftChoiceButton, rightChoiceButton, vsLabel, leftTagLabel, rightTagLabel].forEach {
            addSubview($0)
        }

        setupConstraints()
        applyCornerMask()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            leftChoiceButton.topAnchor.constraint(equalTo: topAnchor),
            leftChoiceButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            leftChoiceButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            leftChoiceButton.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5),

            rightChoiceButton.topAnchor.constraint(equalTo: topAnchor),
            rightChoiceButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            rightChoiceButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            rightChoiceButton.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5),

            vsLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            vsLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            vsLabel.widthAnchor.constraint(equalToConstant: .spacingXL + .spacingXS),
            vsLabel.heightAnchor.constraint(equalToConstant: .spacingXL + .spacingXS),

            leftTagLabel.topAnchor.constraint(equalTo: leftChoiceButton.topAnchor, constant: .spacingM),
            leftTagLabel.centerXAnchor.constraint(equalTo: leftChoiceButton.centerXAnchor),
            leftTagLabel.widthAnchor.constraint(equalToConstant: 40),
            leftTagLabel.heightAnchor.constraint(equalToConstant: 18),

            rightTagLabel.topAnchor.constraint(equalTo: rightChoiceButton.topAnchor, constant: .spacingM),
            rightTagLabel.centerXAnchor.constraint(equalTo: rightChoiceButton.centerXAnchor),
            rightTagLabel.widthAnchor.constraint(equalToConstant: 40),
            rightTagLabel.heightAnchor.constraint(equalToConstant: 18)
        ])
    }

    private func applyCornerMask() {
        let radius = layer.cornerRadius
        leftChoiceButton.layer.cornerRadius = radius
        leftChoiceButton.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        leftChoiceButton.layer.masksToBounds = true
        rightChoiceButton.layer.cornerRadius = radius
        rightChoiceButton.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        rightChoiceButton.layer.masksToBounds = true
    }

    // MARK: - render 메서드

    func render(
        selected: BalanceGameChoice?,
        isResult: Bool,
        myChoice: BalanceGameChoice? = nil,
        opponentChoice: BalanceGameChoice? = nil
    ) {
        vsLabel.isHidden = isResult
        leftChoiceButton.isUserInteractionEnabled = !isResult
        rightChoiceButton.isUserInteractionEnabled = !isResult
        leftChoiceButton.alpha = 1.0
        rightChoiceButton.alpha = 1.0
        leftTagLabel.isHidden = true
        rightTagLabel.isHidden = true

        let myColor = UIColor.systemGreen
        let opponentColor = UIColor.systemPurple

        if isResult, let myChoice = myChoice, let opponentChoice = opponentChoice {
            renderResult(
                myChoice: myChoice,
                opponentChoice: opponentChoice,
                myColor: myColor,
                opponentColor: opponentColor
            )
        } else {
            renderChoosing(selected: selected, myColor: myColor)
        }
    }

    private func renderChoosing(selected: BalanceGameChoice?, myColor: UIColor) {
        leftChoiceButton.layer.borderColor = myColor.cgColor
        rightChoiceButton.layer.borderColor = myColor.cgColor
        animateBorder(button: leftChoiceButton, isActive: selected == .left)
        animateBorder(button: rightChoiceButton, isActive: selected == .right)
    }

    private func renderResult(
        myChoice: BalanceGameChoice,
        opponentChoice: BalanceGameChoice,
        myColor: UIColor,
        opponentColor: UIColor
    ) {
        if myChoice == opponentChoice {
            let isLeft = (myChoice == .left)
            let activeTag = isLeft ? leftTagLabel : rightTagLabel
            activeTag.text = "WE"
            activeTag.backgroundColor = myColor
            activeTag.isHidden = false

            leftChoiceButton.layer.borderColor = myColor.cgColor
            rightChoiceButton.layer.borderColor = myColor.cgColor
            animateBorder(button: isLeft ? leftChoiceButton : rightChoiceButton, isActive: true)
            animateBorder(button: isLeft ? rightChoiceButton : leftChoiceButton, isActive: false)

            (isLeft ? leftChoiceButton : rightChoiceButton).alpha = 1.0
            (isLeft ? rightChoiceButton : leftChoiceButton).alpha = 0.5
        } else {
            leftTagLabel.isHidden = false
            rightTagLabel.isHidden = false
            leftTagLabel.text = (myChoice == .left) ? "ME" : "YOU"
            leftTagLabel.backgroundColor = (myChoice == .left) ? myColor : opponentColor
            rightTagLabel.text = (myChoice == .right) ? "ME" : "YOU"
            rightTagLabel.backgroundColor = (myChoice == .right) ? myColor : opponentColor

            leftChoiceButton.layer.borderColor = (myChoice == .left) ? myColor.cgColor : opponentColor.cgColor
            rightChoiceButton.layer.borderColor = (myChoice == .right) ? myColor.cgColor : opponentColor.cgColor
            animateBorder(button: leftChoiceButton, isActive: true)
            animateBorder(button: rightChoiceButton, isActive: true)
        }
    }

    private func animateBorder(button: UIButton, isActive: Bool) {
        let animations = {
            button.layer.borderWidth = isActive ? self.activeBorderWidth : 0
            if !isActive {
                button.layer.borderColor = UIColor.clear.cgColor
            }
        }

        UIView.animate(
            withDuration: 0.15,
            delay: 0,
            options: [.curveEaseOut, .allowUserInteraction],
            animations: animations
        )
    }

    func setChoiceTitles(left: String, right: String) {
        let fontAttr = AttributeContainer([.font: UIFont.body1])
        if var leftConfig = leftChoiceButton.configuration {
            leftConfig.attributedTitle = AttributedString(left, attributes: fontAttr)
            leftChoiceButton.configuration = leftConfig
        }
        if var rightConfig = rightChoiceButton.configuration {
            rightConfig.attributedTitle = AttributedString(right, attributes: fontAttr)
            rightChoiceButton.configuration = rightConfig
        }
    }
}
