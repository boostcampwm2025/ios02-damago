//
//  ConnectionView.swift
//  Damago
//
//  Created by 박현수 on 1/15/26.
//

import UIKit

final class ConnectionView: UIView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "다마고"
        label.textColor = .damagoPrimary
        label.font = .title1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "연인을 초대해 보세요!"
        label.textColor = .textPrimary
        label.font = .title3
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let cardContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = .largeCard
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.textTertiary.withAlphaComponent(0.5).cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let cardHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "커플 코드"
        label.textColor = .damagoPrimary
        label.font = .body1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let cardDivider: UIView = {
        let view = UIView()
        view.backgroundColor = .damagoPrimary
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let myCodeTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "나의 코드"
        label.font = .body2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let myCodeContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5
        view.layer.cornerRadius = .mediumButton
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let myCodeLabel: UILabel = {
        let label = UILabel()
        label.font = .title2
        label.textColor = .textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let copyButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(font: .title3)

        let image = UIImage(
            systemName: "document.on.document",
            withConfiguration: config
        )
        button.setImage(image, for: .normal)
        button.setImage(image, for: .selected)
        button.tintColor = .damagoPrimary
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let centerDividerView: DashedLineView = {
        let view = DashedLineView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let heartImageView: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(font: .title3)
        imageView.image = UIImage(systemName: "heart", withConfiguration: config)
        imageView.tintColor = .lightGray
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let opponentCodeTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "연인의 코드를 알고 있다면?"
        label.textColor = .textPrimary
        label.font = .body2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let opponentCodeContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5
        view.layer.cornerRadius = .mediumButton
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let opponentCodeTextField: UITextField = {
        let textField = UITextField()
        textField.font = .title2
        textField.textColor = .textPrimary
        textField.placeholder = "상대방 코드 입력"
        textField.returnKeyType = .go
        textField.enablesReturnKeyAutomatically = true
        textField.keyboardType = .asciiCapable
        textField.autocapitalizationType = .allCharacters
        textField.autocorrectionType = .no
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    let connectButton: CTAButton = {
        let button = CTAButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(frame: .zero)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .background
        setupHierarchy()
        setupConstraints()
    }

    private func setupHierarchy() {
        [
            cardHeaderLabel, cardDivider, myCodeTitleLabel,
            myCodeContainer, centerDividerView, heartImageView,
            opponentCodeTitleLabel, opponentCodeContainer
        ]
            .forEach(cardContainer.addSubview)

        [myCodeLabel, copyButton]
            .forEach(myCodeContainer.addSubview)

        [opponentCodeTextField]
            .forEach(opponentCodeContainer.addSubview)

        [titleLabel, subtitleLabel, cardContainer, connectButton]
            .forEach(addSubview)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate(
            [
                titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
                titleLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: .spacingM),

                subtitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
                subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: .spacingL),

                cardContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: .spacingL),
                cardContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingM),
                cardContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingM),
                
                cardHeaderLabel.topAnchor.constraint(equalTo: cardContainer.topAnchor, constant: .spacingM),
                cardHeaderLabel.centerXAnchor.constraint(equalTo: cardContainer.centerXAnchor),
                
                cardDivider.topAnchor.constraint(equalTo: cardHeaderLabel.bottomAnchor, constant: .spacingM),
                cardDivider.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor),
                cardDivider.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor),
                cardDivider.heightAnchor.constraint(equalToConstant: 3),
                
                myCodeTitleLabel.topAnchor.constraint(equalTo: cardDivider.bottomAnchor, constant: .spacingM),
                myCodeTitleLabel.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor, constant: .spacingL),
                
                myCodeContainer.topAnchor.constraint(equalTo: myCodeTitleLabel.bottomAnchor, constant: .spacingS),
                myCodeContainer.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor, constant: .spacingM),
                myCodeContainer.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor, constant: -.spacingM),
                myCodeContainer.heightAnchor.constraint(equalToConstant: 55),

                myCodeLabel.leadingAnchor.constraint(equalTo: myCodeContainer.leadingAnchor, constant: .spacingM),
                myCodeLabel.centerYAnchor.constraint(equalTo: myCodeContainer.centerYAnchor),
                
                copyButton.trailingAnchor.constraint(equalTo: myCodeContainer.trailingAnchor, constant: -.spacingM),
                copyButton.centerYAnchor.constraint(equalTo: myCodeContainer.centerYAnchor),
                
                centerDividerView.topAnchor.constraint(equalTo: myCodeContainer.bottomAnchor, constant: .spacingL),
                centerDividerView.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor, constant: .spacingM),
                centerDividerView.trailingAnchor.constraint(
                    equalTo: cardContainer.trailingAnchor,
                    constant: -.spacingM
                ),
                centerDividerView.heightAnchor.constraint(equalToConstant: 2),
                
                heartImageView.centerXAnchor.constraint(equalTo: centerDividerView.centerXAnchor),
                heartImageView.centerYAnchor.constraint(equalTo: centerDividerView.centerYAnchor),
                
                opponentCodeTitleLabel.topAnchor.constraint(
                    equalTo: centerDividerView.bottomAnchor,
                    constant: .spacingL
                ),
                opponentCodeTitleLabel.leadingAnchor.constraint(
                    equalTo: cardContainer.leadingAnchor,
                    constant: .spacingL
                ),
                
                opponentCodeContainer.topAnchor.constraint(
                    equalTo: opponentCodeTitleLabel.bottomAnchor,
                    constant: .spacingS
                ),
                opponentCodeContainer.leadingAnchor.constraint(
                    equalTo: cardContainer.leadingAnchor,
                    constant: .spacingM
                ),
                opponentCodeContainer.trailingAnchor.constraint(
                    equalTo: cardContainer.trailingAnchor,
                    constant: -.spacingM
                ),
                opponentCodeContainer.heightAnchor.constraint(equalToConstant: 55),
                opponentCodeContainer.bottomAnchor.constraint(
                    equalTo: cardContainer.bottomAnchor,
                    constant: -.spacingL
                ),
                
                opponentCodeTextField.leadingAnchor.constraint(
                    equalTo: opponentCodeContainer.leadingAnchor,
                    constant: .spacingM
                ),
                opponentCodeTextField.trailingAnchor.constraint(
                    equalTo: opponentCodeContainer.trailingAnchor,
                    constant: -.spacingM
                ),
                opponentCodeTextField.centerYAnchor.constraint(equalTo: opponentCodeContainer.centerYAnchor),

                connectButton.topAnchor.constraint(greaterThanOrEqualTo: cardContainer.bottomAnchor, constant: .spacingL),
                connectButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingM),
                connectButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingM),
                connectButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -.spacingL)
            ]
        )
    }
}

extension ConnectionView {
    func updateConnectButton(isEnabled: Bool) {
        let activeConfig = CTAButton.Configuration(
            backgroundColor: .damagoPrimary,
            foregroundColor: .white,
            image: nil,
            title: "연결하기",
            subtitle: nil
        )

        let disabledConfig = CTAButton.Configuration(
            backgroundColor: .textTertiary,
            foregroundColor: .white,
            image: nil,
            title: "연결하기",
            subtitle: nil
        )

        connectButton.configure(active: activeConfig, disabled: disabledConfig)
        connectButton.isEnabled = isEnabled
    }
}