//
//  CodeConnectionView.swift
//  Damago
//
//  Created by Eden Landelyse on 12/17/25.
//

import UIKit

final class CodeConnectionView: UIView {
    var onConnectTap: ((String) -> Void)?

    private let logoImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "AppLogo"))
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(.required, for: .vertical)
        imageView.setContentCompressionResistancePriority(.required, for: .vertical)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let myCodeTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "내코드"
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()

    private let myCodeValueLabel: UILabel = {
        let label = UILabel()
        label.text = "Code"
        label.font = .preferredFont(forTextStyle: .title2)
        label.textColor = .label
        label.numberOfLines = 1
        label.textAlignment = .center
        return label
    }()

    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "상대방 코드를 입력하세요."
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    let codeTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "Code"
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .done
        return textField
    }()

    private let connectButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "연결 요청하기"
        configuration.cornerStyle = .medium

        let button = UIButton(configuration: configuration)
        return button
    }()

    let errorMessageLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemRed
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViewHierarchy()
        configureConstraints()
        configureConnectButtonAction()
        configureAppearance()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureViewHierarchy()
        configureConstraints()
        configureConnectButtonAction()
        configureAppearance()
    }

    func setMyCode(_ code: String) {
        myCodeValueLabel.text = code
    }

    private func configureConnectButtonAction() {
        connectButton.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                let code = self.codeTextField.text ?? ""
                self.onConnectTap?(code)
            },
            for: .touchUpInside
        )
    }

    private func configureViewHierarchy() {
        addSubview(logoImageView)
        addSubview(contentStackView)

        contentStackView.addArrangedSubview(myCodeTitleLabel)
        contentStackView.addArrangedSubview(myCodeValueLabel)
        contentStackView.addArrangedSubview(instructionLabel)
        contentStackView.addArrangedSubview(codeTextField)
        contentStackView.addArrangedSubview(connectButton)
        contentStackView.addArrangedSubview(errorMessageLabel)

        myCodeTitleLabel.textAlignment = .center
        codeTextField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        connectButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
    }

    private func configureConstraints() {
        NSLayoutConstraint.activate([
            logoImageView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 32),
            logoImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            logoImageView.heightAnchor.constraint(equalToConstant: 200),
            logoImageView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.6),

            contentStackView.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 32),
            contentStackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 24),
            contentStackView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -24),
            contentStackView.bottomAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
    }

    private func configureAppearance() {
        backgroundColor = .systemBackground
    }
}
