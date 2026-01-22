//
//  BalanceGameView.swift
//  Damago
//
//  Created by Eden Landelyse on 1/19/26.
//

import UIKit

final class BalanceGameCardView: UIView {

    // 컴포넌트
    private let view: CardView = {
        let view = CardView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let headerView: CardHeaderView = {
        let view = CardHeaderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let questionLabel: UILabel = {
        let label = UILabel()
        label.text = nil
        label.font = .body3
        label.textColor = .black
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let choiceContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = .largeCard
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

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
        button.titleLabel?.font = .body1
        button.layer.cornerCurve = .continuous
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.titleLabel?.textAlignment = .center
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
        button.titleLabel?.font = .body1
        button.layer.cornerCurve = .continuous
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.titleLabel?.textAlignment = .center
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let vsLabel: UILabel = {
        let label = UILabel()
        label.text = "VS"
        label.font = .systemFont(ofSize: 12, weight: .bold) // weight가 bold여야 자연스러워 별도로 지정했습니다.
        label.textColor = .black
        label.textAlignment = .center
        label.backgroundColor = .white
        label.layer.cornerRadius = .largeCard
        label.clipsToBounds = true
        label.isUserInteractionEnabled = false
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyChoiceCornerMask()
    }

    // helper method
    private func setupUI() {
        backgroundColor = .clear

        addSubview(view)
        [headerView, questionLabel, choiceContainerView].forEach {
            view.addSubview($0)
        }

        choiceContainerView.addSubview(leftChoiceButton)
        choiceContainerView.addSubview(rightChoiceButton)
        choiceContainerView.addSubview(vsLabel)

        applyChoiceCornerMask()
        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor),
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor),

            headerView.topAnchor.constraint(equalTo: topAnchor, constant: .spacingL),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingL),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingL),

            questionLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: .spacingXS + .spacingS),
            questionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingL),
            questionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingL),

            choiceContainerView.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: .spacingL),
            choiceContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingL),
            choiceContainerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingL),
            choiceContainerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -.spacingL),
            choiceContainerView.heightAnchor.constraint(equalToConstant: 180),

            leftChoiceButton.topAnchor.constraint(equalTo: choiceContainerView.topAnchor),
            leftChoiceButton.leadingAnchor.constraint(equalTo: choiceContainerView.leadingAnchor),
            leftChoiceButton.bottomAnchor.constraint(equalTo: choiceContainerView.bottomAnchor),
            leftChoiceButton.widthAnchor.constraint(equalTo: choiceContainerView.widthAnchor, multiplier: 0.5),

            rightChoiceButton.topAnchor.constraint(equalTo: choiceContainerView.topAnchor),
            rightChoiceButton.trailingAnchor.constraint(equalTo: choiceContainerView.trailingAnchor),
            rightChoiceButton.bottomAnchor.constraint(equalTo: choiceContainerView.bottomAnchor),
            rightChoiceButton.widthAnchor.constraint(equalTo: choiceContainerView.widthAnchor, multiplier: 0.5),

            vsLabel.centerXAnchor.constraint(equalTo: choiceContainerView.centerXAnchor),
            vsLabel.centerYAnchor.constraint(equalTo: choiceContainerView.centerYAnchor),
            vsLabel.widthAnchor.constraint(equalToConstant: .spacingXL + .spacingXS),
            vsLabel.heightAnchor.constraint(equalToConstant: .spacingXL + .spacingXS)
        ])
    }

    private func applyChoiceCornerMask() {
        let radius = choiceContainerView.layer.cornerRadius

        leftChoiceButton.layer.cornerRadius = radius
        leftChoiceButton.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        leftChoiceButton.layer.masksToBounds = true

        rightChoiceButton.layer.cornerRadius = radius
        rightChoiceButton.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        rightChoiceButton.layer.masksToBounds = true
    }

    func render(selectedChoice: BalanceGameChoice?) {
        switch selectedChoice {
        case .left:
            animateSelection(leftChoiceButton)
            animateDeselection(rightChoiceButton)
        case .right:
            animateSelection(rightChoiceButton)
            animateDeselection(leftChoiceButton)
        case .none:
            animateDeselection(leftChoiceButton)
            animateDeselection(rightChoiceButton)
        }
    }

    // 선택·선택취소에 대한 애니메이션
    private func animateSelection(_ view: UIView) {
        let animations = {
            view.layer.borderWidth = .spacingS
            view.layer.borderColor = UIColor.systemGreen.cgColor
        }

        UIView.animate(
            withDuration: 0.15,
            delay: 0,
            options: [.curveEaseOut, .allowUserInteraction],
            animations: animations
        )
    }

    private func animateDeselection(_ view: UIView) {
        let animations = {
            view.layer.borderWidth = 0
            view.layer.borderColor = UIColor.clear.cgColor
        }

        UIView.animate(
            withDuration: 0.15,
            delay: 0,
            options: [.curveEaseOut, .allowUserInteraction],
            animations: animations
        )
    }

    // 내용 구성용 공개 메서드
    func configure(
        category: String,
        question: String,
        leftChoice: String,
        rightChoice: String,
        foods: Int? = nil,
        coins: Int? = nil
    ) {
        headerView.configure(
            title: "밸런스 게임",
            foods: foods,
            coins: coins,
            badge: category
        )

        questionLabel.text = question
        if var leftConfig = leftChoiceButton.configuration {
            leftConfig.attributedTitle = AttributedString(
                leftChoice,
                attributes: AttributeContainer([
                    .font: UIFont.body1
                ])
            )
            leftChoiceButton.configuration = leftConfig
        }

        if var rightConfig = rightChoiceButton.configuration {
            rightConfig.attributedTitle = AttributedString(
                rightChoice,
                attributes: AttributeContainer([
                    .font: UIFont.body1
                ])
            )
            rightChoiceButton.configuration = rightConfig
        }

        // Reset selection state
        render(selectedChoice: nil)
    }
}
