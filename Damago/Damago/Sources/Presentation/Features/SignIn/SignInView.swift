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
        setupHierarchy()
        setupConstraints()
    }

    private func setupHierarchy() {
        [logoBanner, signInButton]
            .forEach { addSubview($0) }
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            logoBanner.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingXL),
            logoBanner.centerYAnchor.constraint(equalTo: centerYAnchor),

            signInButton.heightAnchor.constraint(equalToConstant: 56),
            signInButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingM),
            signInButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingM),
            signInButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -.spacingL)
        ])
    }
}
