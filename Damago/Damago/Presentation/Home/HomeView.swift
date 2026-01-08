//
//  HomeView.swift
//  Damago
//
//  Created by 박현수 on 1/7/26.
//

import UIKit

final class HomeView: UIView {
    private lazy var coinAttachmentString: NSAttributedString = {
        let symbolConfig = UIImage.SymbolConfiguration(font: .body3)
        let image = UIImage(systemName: "dollarsign.circle", withConfiguration: symbolConfig)?
            .withTintColor(.systemYellow, renderingMode: .alwaysOriginal)
        let attachment = NSTextAttachment()
        attachment.image = image
        return NSAttributedString(attachment: attachment)
    }()

    private lazy var dDayAttachmentString: NSAttributedString = {
        let symbolConfig = UIImage.SymbolConfiguration(font: .body1)
        let image = UIImage(systemName: "heart.fill", withConfiguration: symbolConfig)?
            .withTintColor(.red, renderingMode: .alwaysOriginal)
        let attachment = NSTextAttachment()
        attachment.image = image
        return NSAttributedString(attachment: attachment)
    }()

    lazy var capsuleLabel: CapsuleLabel = {
        let label = CapsuleLabel(padding: .init(top: .spacingS, left: .spacingS, bottom: .spacingS, right: .spacingS))
        label.font = .body3
        label.textColor = .textPrimary
        label.backgroundColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var dDayLabel: UILabel = {
        let label = UILabel()
        label.font = .body1
        label.textColor = .damagoPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .title1
        label.textColor = .textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let cardShadowContainer: UIView = {
        let view = UIView()
        view.layer.shadowColor = UIColor.damagoPrimary.cgColor
        view.layer.shadowOpacity = 0.25
        view.layer.shadowOffset = CGSize(width: 0, height: 20)
        view.layer.shadowRadius = 40
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let cardContentContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 239 / 255, green: 236 / 255, blue: 224 / 255, alpha: 1)
        view.layer.cornerRadius = .largeCard
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 5
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let characterView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "dog")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    let feedButton: UIButton = {
        var config = UIButton.Configuration.plain()
        let symbolConfig = UIImage.SymbolConfiguration(font: .title3)
        config.image = UIImage(systemName: "carrot.fill", withConfiguration: symbolConfig)

        config.baseForegroundColor = .damagoPrimary
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    let foodBadge: CircleTextBadge = {
        let badge = CircleTextBadge(padding: 6)
        badge.font = .caption
        badge.textColor = .textPrimary
        badge.backgroundColor = .white
        badge.translatesAutoresizingMaskIntoConstraints = false
        return badge
    }()

    let pokeButton: DamagoCTAButton = {
        let button = DamagoCTAButton()
        let activeConfig = DamagoCTAButton.Configuration(
            backgroundColor: .damagoPrimary,
            foregroundColor: .white,
            image: UIImage(systemName: "hand.rays.fill"),
            title: "콕 찌르기"
        )
        let disabledConfig = DamagoCTAButton.Configuration(
            backgroundColor: .textTertiary,
            foregroundColor: .white,
            image: nil,
            title: "아직 찌를 수 없습니다"
        )
        button.configure(
            active: activeConfig,
            disabled: disabledConfig
        )
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .background
        setupHierarchy()
        setupConstraints()
    }

    private func setupHierarchy() {
        cardContentContainer.addSubview(characterView)
        cardShadowContainer.addSubview(cardContentContainer)
        [capsuleLabel, dDayLabel, nameLabel, cardShadowContainer, feedButton, foodBadge, pokeButton]
            .forEach { addSubview($0) }
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            capsuleLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            capsuleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingM),

            feedButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            feedButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingM),

            foodBadge.leadingAnchor.constraint(equalTo: feedButton.trailingAnchor, constant: -.spacingM),
            foodBadge.bottomAnchor.constraint(equalTo: feedButton.topAnchor, constant: .spacingM),

            dDayLabel.topAnchor.constraint(equalTo: capsuleLabel.bottomAnchor, constant: .spacingXL),
            dDayLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            nameLabel.topAnchor.constraint(equalTo: dDayLabel.bottomAnchor, constant: .spacingS),
            nameLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            cardShadowContainer.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: .spacingXL),
            cardShadowContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            cardShadowContainer.widthAnchor.constraint(equalToConstant: 256),
            cardShadowContainer.heightAnchor.constraint(equalToConstant: 256),

            cardContentContainer.topAnchor.constraint(equalTo: cardShadowContainer.topAnchor),
            cardContentContainer.leadingAnchor.constraint(equalTo: cardShadowContainer.leadingAnchor),
            cardContentContainer.trailingAnchor.constraint(equalTo: cardShadowContainer.trailingAnchor),
            cardContentContainer.bottomAnchor.constraint(equalTo: cardShadowContainer.bottomAnchor),

            characterView.topAnchor.constraint(equalTo: cardContentContainer.topAnchor, constant: .spacingM),
            characterView.leadingAnchor.constraint(equalTo: cardContentContainer.leadingAnchor, constant: .spacingM),
            characterView.trailingAnchor.constraint(equalTo: cardContentContainer.trailingAnchor, constant: -.spacingM),
            characterView.bottomAnchor.constraint(equalTo: cardContentContainer.bottomAnchor, constant: -.spacingM),

            pokeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingM),
            pokeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingM),
            pokeButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -.spacingXL)
        ])
    }

}

extension HomeView {
    func updateCoin(amount: Int) {
        let completeText = NSMutableAttributedString()
        completeText.append(coinAttachmentString)

        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.body3,
            .foregroundColor: UIColor.textPrimary
        ]
        let labelText = NSAttributedString(string: " 코인: \(amount)", attributes: textAttributes)

        completeText.append(labelText)

        self.capsuleLabel.attributedText = completeText
    }

    func updateDDay(days: Int) {
        let completeText = NSMutableAttributedString()
        completeText.append(dDayAttachmentString)

        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.body1,
            .foregroundColor: UIColor.damagoPrimary
        ]
        let labelText = NSAttributedString(string: " D+\(days)", attributes: textAttributes)

        completeText.append(labelText)

        self.dDayLabel.attributedText = completeText
    }
}
