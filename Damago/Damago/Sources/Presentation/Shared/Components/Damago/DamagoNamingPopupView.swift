//
//  DamagoNamingPopupView.swift
//  Damago
//
//  Created by 김재영 on 1/26/26.
//

import UIKit

final class DamagoNamingPopupView: UIView {
    let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .damagoSecondary
        view.layer.cornerRadius = .largeCard
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let damagoBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = .mediumButton
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.systemGray5.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let damagoView: DamagoView = {
        let view = DamagoView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .body1
        label.textColor = .textPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let nameTextField: DamagoTextField = {
        let textField = DamagoTextField()
        textField.font = .body1
        textField.textColor = .textPrimary
        textField.backgroundColor = .background
        textField.maxLength = 10
        textField.layer.cornerRadius = .mediumButton
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = .spacingM
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    let cancelButton: CTAButton = {
        let button = CTAButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let confirmButton: CTAButton = {
        let button = CTAButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var containerViewCenterYConstraint: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureInitialState(
        title: String,
        placeholder: String,
        confirmTitle: String,
        confirmDisabledTitle: String,
        isEditMode: Bool
    ) {
        titleLabel.text = title
        nameTextField.placeholder = placeholder
        
        let confirmConfig = CTAButton.Configuration(
            backgroundColor: .damagoPrimary,
            foregroundColor: .white,
            title: confirmTitle,
            font: .body2
        )
        let disabledConfig = CTAButton.Configuration(
            backgroundColor: .disabled,
            foregroundColor: .white,
            title: confirmDisabledTitle,
            font: .body2
        )
        confirmButton.configure(enabled: confirmConfig, disabled: disabledConfig)
        
        if isEditMode {
            let cancelConfig = CTAButton.Configuration(
                backgroundColor: .textTertiary,
                foregroundColor: .white,
                title: "취소",
                font: .body2
            )
            cancelButton.configure(enabled: cancelConfig, disabled: cancelConfig)
        } else {
             let cancelConfig = CTAButton.Configuration(
                 backgroundColor: .disabled,
                 foregroundColor: .white,
                 title: "취소",
                 font: .body2
             )
             cancelButton.configure(enabled: cancelConfig, disabled: cancelConfig)
        }
    }
    
    func configure(with damagoType: DamagoType?) {
        guard let damagoType = damagoType else { return }
        damagoView.configure(with: damagoType)
    }
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        setupHierarchy()
        setupConstraints()
        
        nameTextField.delegate = self
        setupKeyboard()
    }
    
    private func setupHierarchy() {
        addSubview(containerView)
        [damagoBackgroundView, titleLabel, nameTextField, buttonStackView].forEach {
            containerView.addSubview($0)
        }
        damagoBackgroundView.addSubview(damagoView)
        buttonStackView.addArrangedSubview(cancelButton)
        buttonStackView.addArrangedSubview(confirmButton)
    }
    
    private func setupConstraints() {
        let centerY = containerView.centerYAnchor.constraint(equalTo: centerYAnchor)
        containerViewCenterYConstraint = centerY
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerY,
            containerView.widthAnchor.constraint(equalToConstant: 300),
            
            damagoBackgroundView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: .spacingL),
            damagoBackgroundView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            damagoBackgroundView.widthAnchor.constraint(equalToConstant: 150),
            damagoBackgroundView.heightAnchor.constraint(equalTo: damagoBackgroundView.widthAnchor),
            
            damagoView.topAnchor.constraint(equalTo: damagoBackgroundView.topAnchor, constant: .spacingS),
            damagoView.leadingAnchor.constraint(equalTo: damagoBackgroundView.leadingAnchor, constant: .spacingS),
            damagoView.trailingAnchor.constraint(equalTo: damagoBackgroundView.trailingAnchor, constant: -.spacingS),
            damagoView.bottomAnchor.constraint(equalTo: damagoBackgroundView.bottomAnchor, constant: -.spacingS),
            
            titleLabel.topAnchor.constraint(equalTo: damagoBackgroundView.bottomAnchor, constant: .spacingM),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: .spacingM),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -.spacingM),
            
            nameTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: .spacingM),
            nameTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: .spacingM),
            nameTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -.spacingM),
            nameTextField.heightAnchor.constraint(equalToConstant: 40),
            
            buttonStackView.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: .spacingL),
            buttonStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: .spacingM),
            buttonStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -.spacingM),
            buttonStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -.spacingM),
            buttonStackView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupKeyboard() {
        setupKeyboardDismissOnTap { [weak self] location in
            guard let self else { return }
            if !self.containerView.frame.contains(location) {
                self.cancelButton.sendActions(for: .touchUpInside)
            }
        }
        
        if let centerYConstraint = containerViewCenterYConstraint {
            adjustViewForKeyboard(
                constraint: centerYConstraint,
                textFieldsGetter: { [weak self] in
                    [self?.nameTextField].compactMap { $0 }
                }
            )
        }
    }
}

extension DamagoNamingPopupView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if confirmButton.isEnabled {
            confirmButton.sendActions(for: .touchUpInside)
        }
        return true
    }
}
