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
    }

    private var activeConfig: Configuration?
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
        self.translatesAutoresizingMaskIntoConstraints = false

        self.heightAnchor.constraint(equalToConstant: 56).isActive = true
    }

    func configure(active: Configuration, disabled: Configuration) {
        self.activeConfig = active
        self.disabledConfig = disabled
        updateButtonStyle()
    }
    
    func setTitle(_ title: String) {
        if let active = activeConfig {
            activeConfig = Configuration(
                backgroundColor: active.backgroundColor,
                foregroundColor: active.foregroundColor,
                image: active.image,
                title: title,
                subtitle: active.subtitle
            )
        }
        
        if let disabled = disabledConfig {
            disabledConfig = Configuration(
                backgroundColor: disabled.backgroundColor,
                foregroundColor: disabled.foregroundColor,
                image: disabled.image,
                title: title,
                subtitle: disabled.subtitle
            )
        }
        
        updateButtonStyle()
    }

    override var isEnabled: Bool {
        didSet { updateButtonStyle() }
    }

    private func updateButtonStyle() {
        guard let style = isEnabled ? activeConfig : disabledConfig else { return }

        var updatedConfig = self.configuration

        updatedConfig?.baseBackgroundColor = style.backgroundColor
        updatedConfig?.baseForegroundColor = style.foregroundColor

        var titleContainer = AttributeContainer()
        titleContainer.font = .title3
        titleContainer.foregroundColor = style.foregroundColor
        updatedConfig?.attributedTitle = AttributedString(style.title, attributes: titleContainer)

        if let subtitleText = style.subtitle {
            var subtitleContainer = AttributeContainer()
            subtitleContainer.font = .body3
            subtitleContainer.foregroundColor = style.foregroundColor.withAlphaComponent(0.6)
            updatedConfig?.attributedSubtitle = AttributedString(subtitleText, attributes: subtitleContainer)
        }

        updatedConfig?.image = style.image

        self.configuration = updatedConfig
    }
}
