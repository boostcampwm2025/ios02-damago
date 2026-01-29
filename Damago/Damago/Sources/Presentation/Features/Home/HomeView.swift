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

    let editNameButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "pencil")
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(font: .body3)
        config.baseForegroundColor = .damagoPrimary
        config.contentInsets = .init(top: .spacingS, leading: .spacingS, bottom: .spacingS, trailing: .spacingS)
        
        config.background.backgroundColor = UIColor.damagoPrimary.withAlphaComponent(0.12)
        config.background.strokeColor = UIColor.damagoPrimary.withAlphaComponent(0.25)
        config.background.strokeWidth = 1
        config.background.cornerRadius = .mediumButton

        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = "이름 변경"

        return button
    }()

    private lazy var nameStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [nameLabel, editNameButton])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = .spacingXS
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
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

    let characterView: SpriteAnimationView = {
        let view = SpriteAnimationView(spriteSheetName: "")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let expBar: ExperienceBar = {
        let expBar = ExperienceBar()
        expBar.translatesAutoresizingMaskIntoConstraints = false
        return expBar
    }()

    let feedButton: CTAButton = {
        let button = CTAButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    let pokeButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "hand.rays.fill")
        config.imagePlacement = .top
        config.imagePadding = .spacingS
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(font: .title3)

        var titleContainer = AttributeContainer()
        titleContainer.font = .caption
        titleContainer.foregroundColor = .textSecondary
        config.attributedTitle = AttributedString("콕 찌르기", attributes: titleContainer)

        config.baseForegroundColor = .damagoPrimary

        let button = UIButton(configuration: config)
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
        [capsuleLabel, dDayLabel, nameStackView, cardShadowContainer, feedButton, pokeButton, expBar]
            .forEach { addSubview($0) }
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            capsuleLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            capsuleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingM),

            pokeButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            pokeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingM),

            dDayLabel.topAnchor.constraint(equalTo: capsuleLabel.bottomAnchor, constant: .spacingXL),
            dDayLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            nameStackView.topAnchor.constraint(equalTo: dDayLabel.bottomAnchor, constant: .spacingS),
            nameStackView.centerXAnchor.constraint(equalTo: centerXAnchor),

            cardShadowContainer.topAnchor.constraint(equalTo: nameStackView.bottomAnchor, constant: .spacingXL),
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

            expBar.topAnchor.constraint(equalTo: characterView.bottomAnchor, constant: .spacingL),
            expBar.leadingAnchor.constraint(equalTo: cardContentContainer.leadingAnchor, constant: .spacingM),
            expBar.trailingAnchor.constraint(equalTo: cardContentContainer.trailingAnchor, constant: -.spacingM),

            feedButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingM),
            feedButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingM),
            feedButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -.spacingXL)
        ])
    }
}

extension HomeView {
    struct FeedButtonState: Equatable {
        let foodAmount: Int
        let isEnabled: Bool
    }

    func updateCoin(amount: Int) {
        let completeText = NSMutableAttributedString()
        completeText.append(coinAttachmentString)

        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.body3,
            .foregroundColor: UIColor.textPrimary
        ]
        let labelText = NSAttributedString(string: " \(amount)", attributes: textAttributes)

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

    func updateFeedButton(state: FeedButtonState) {
        let activeConfig = CTAButton.Configuration(
            backgroundColor: .damagoPrimary,
            foregroundColor: .white,
            image: UIImage(systemName: "carrot.fill"),
            title: "먹이 주기",
            subtitle: "\(state.foodAmount)개 남음"
        )

        let disabledTitle = state.foodAmount == 0 ? "남은 먹이가 없어요" : "먹이 주는 중"
        let disabledSubtitle = state.foodAmount == 0 ? "서로에 대해 알아가며 먹이를 얻어 보세요" : nil

        let disabledConfig = CTAButton.Configuration(
            backgroundColor: .disabled,
            foregroundColor: .white,
            image: UIImage(systemName: "carrot"),
            title: disabledTitle,
            subtitle: disabledSubtitle
        )

        feedButton.configure(enabled: activeConfig, disabled: disabledConfig)
        feedButton.isEnabled = state.isEnabled
    }
    
    func updateCharacter(petType: String, isHungry: Bool) {
        let imageName = isHungry ? "\(petType)Hungry" : "\(petType)Base"
        characterView.animate(spriteSheetName: imageName)
    }
}
