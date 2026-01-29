//
//  CTAButton.swift
//  Damago
//
//  Created by 박현수 on 1/8/26.
//

import UIKit

final class CTAButton: UIButton {
    struct Configuration {
        let backgroundColor: UIColor
        let foregroundColor: UIColor
        let image: UIImage?
        let title: String
        let subtitle: String?
        let font: UIFont?

        init(
            backgroundColor: UIColor,
            foregroundColor: UIColor,
            image: UIImage? = nil,
            title: String,
            subtitle: String? = nil,
            font: UIFont? = nil
        ) {
            self.backgroundColor = backgroundColor
            self.foregroundColor = foregroundColor
            self.image = image
            self.title = title
            self.subtitle = subtitle
            self.font = font
        }
    }

    private var enabledConfig: Configuration?
    private var disabledConfig: Configuration?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupDefaultLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupDefaultLayout()
    }

    private func setupDefaultLayout() {
        var config = UIButton.Configuration.filled()
        config.imagePlacement = .leading
        config.imagePadding = .spacingS
        config.titleAlignment = .center
        config.background.cornerRadius = .mediumButton
        config.cornerStyle = .fixed
        self.configuration = config
        self.configurationUpdateHandler = { [weak self] button in
            guard let self = self, let ctaButton = button as? CTAButton else { return }
            ctaButton.updateButtonStyle()
        }
        self.translatesAutoresizingMaskIntoConstraints = false
        self.heightAnchor.constraint(equalToConstant: 56).isActive = true
    }

    func configure(enabled: Configuration, disabled: Configuration) {
        self.enabledConfig = enabled
        self.disabledConfig = disabled
        updateButtonStyle()
    }
    
    func setTitle(_ title: String) {
        if let enabled = enabledConfig {
            enabledConfig = Configuration(
                backgroundColor: enabled.backgroundColor,
                foregroundColor: enabled.foregroundColor,
                image: enabled.image,
                title: title,
                subtitle: enabled.subtitle,
                font: enabled.font
            )
        }
        
        if let disabled = disabledConfig {
            disabledConfig = Configuration(
                backgroundColor: disabled.backgroundColor,
                foregroundColor: disabled.foregroundColor,
                image: disabled.image,
                title: title,
                subtitle: disabled.subtitle,
                font: disabled.font
            )
        }
        
        updateButtonStyle()
    }

    override var isEnabled: Bool {
        didSet { updateButtonStyle() }
    }

    private func updateButtonStyle() {
        guard let style = isEnabled ? enabledConfig : disabledConfig else { return }

        var updatedConfig = self.configuration

        updatedConfig?.background.backgroundColor = style.backgroundColor
        updatedConfig?.baseForegroundColor = style.foregroundColor

        var titleContainer = AttributeContainer()
        titleContainer.font = style.font ?? .title3
        titleContainer.foregroundColor = style.foregroundColor
        updatedConfig?.attributedTitle = AttributedString(style.title, attributes: titleContainer)

        if let subtitleText = style.subtitle {
            var subtitleContainer = AttributeContainer()
            subtitleContainer.font = .body3
            subtitleContainer.foregroundColor = style.foregroundColor
            updatedConfig?.attributedSubtitle = AttributedString(subtitleText, attributes: subtitleContainer)
        } else {
            updatedConfig?.attributedSubtitle = nil
        }

        updatedConfig?.image = style.image

        self.configuration = updatedConfig
    }
}
