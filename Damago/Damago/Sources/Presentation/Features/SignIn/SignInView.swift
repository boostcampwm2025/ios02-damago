//
//  SignInView.swift
//  Damago
//
//  Created by 박현수 on 1/13/26.
//

import AuthenticationServices
import UIKit

final class SignInView: UIView {
    private let logoBanner: UIImageView = {
        let imageView = UIImageView(image: UIImage(resource: .appLogo))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    let signInButton: ASAuthorizationAppleIDButton = {
        let button = ASAuthorizationAppleIDButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    init() {
        super.init(frame: .zero)
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
        [logoBanner, signInButton]
            .forEach { addSubview($0) }
    }

    private func setupConstraints() {
        guard let image = logoBanner.image else { return }
        let aspectRatio = image.size.height / image.size.width
        NSLayoutConstraint.activate([
            logoBanner.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2 * .spacingXL),
            logoBanner.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2 * .spacingXL),
            logoBanner.centerYAnchor.constraint(equalTo: centerYAnchor),
            logoBanner.heightAnchor.constraint(equalTo: logoBanner.widthAnchor, multiplier: aspectRatio),

            signInButton.heightAnchor.constraint(equalToConstant: 56),
            signInButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingM),
            signInButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingM),
            signInButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -.spacingL)
        ])
    }
}

#Preview {
    SignInView()
}
