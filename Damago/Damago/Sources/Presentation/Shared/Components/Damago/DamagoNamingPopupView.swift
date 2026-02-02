//
//  DamagoNamingPopupView.swift
//  Damago
//
//  Created by 김재영 on 1/26/26.
//

import UIKit
import Combine

final class DamagoNamingPopupView: UIView {
    enum Mode {
        case onboarding
        case edit
    }
    
    let confirmButtonTappedSubject = PassthroughSubject<String, Never>()
    let cancelButtonTappedSubject = PassthroughSubject<Void, Never>()
    let requestCancelConfirmationSubject = PassthroughSubject<Void, Never>()
    
    private let containerView: UIView = {
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
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .body1
        label.textColor = .textPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let nameTextField: UITextField = {
        let textField = UITextField()
        textField.font = .body1
        textField.textColor = .textPrimary
        textField.backgroundColor = .background
        textField.layer.cornerRadius = .mediumButton
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: .spacingM, height: 0))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: .spacingM, height: 0))
        textField.rightViewMode = .always
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
    
    private var mode: Mode = .onboarding
    private var initialName: String?
    private var cancellables = Set<AnyCancellable>()
    private var containerViewCenterYConstraint: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        bind()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(mode: Mode, damagoType: DamagoType?, initialName: String?) {
        self.mode = mode
        if let damagoType = damagoType {
            damagoView.configure(with: damagoType)
        }
        
        let trimmed = initialName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.initialName = trimmed
        nameTextField.text = trimmed
        nameTextField.placeholder = mode == .onboarding ? "이름 입력" : "새 이름 입력"
        titleLabel.text = mode == .onboarding ? "마음을 담아 이름을 선물해주세요." : "이름을 바꿔볼까요?"
        
        setupButtonStyles()
        updateConfirmButtonState(trimmed)
    }
    
    func updateInitialName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        initialName = trimmed
        if nameTextField.text?.isEmpty ?? true {
            nameTextField.text = trimmed
            updateConfirmButtonState(trimmed)
        }
    }
    
    private func setupButtonStyles() {
        let confirmTitle = mode == .onboarding ? "만나서 반가워!" : "변경하기"
        let confirmConfig = CTAButton.Configuration(
            backgroundColor: .damagoPrimary,
            foregroundColor: .white,
            title: confirmTitle,
            font: .body2
        )
        let disabledConfig = CTAButton.Configuration(
            backgroundColor: .disabled,
            foregroundColor: .white,
            title: "이름을 알려줘!",
            font: .body2
        )
        confirmButton.configure(enabled: confirmConfig, disabled: disabledConfig)
        
        let cancelBgColor: UIColor = mode == .onboarding ? .disabled : .textTertiary
        let cancelConfig = CTAButton.Configuration(
            backgroundColor: cancelBgColor,
            foregroundColor: .white,
            title: "취소",
            font: .body2
        )
        cancelButton.configure(enabled: cancelConfig, disabled: cancelConfig)
    }
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        setupHierarchy()
        setupConstraints()
        
        nameTextField.delegate = self
        setupKeyboard()
    }
    
    private func bind() {
        confirmButton.tapPublisher
            .sink { [weak self] in
                guard let self = self, let name = self.nameTextField.text, !name.isEmpty else { return }
                self.confirmButtonTappedSubject.send(name)
            }
            .store(in: &cancellables)
            
        cancelButton.tapPublisher
            .sink { [weak self] in
                self?.handleCancel()
            }
            .store(in: &cancellables)
            
        nameTextField.textPublisher
            .sink { [weak self] text in
                self?.updateConfirmButtonState(text)
            }
            .store(in: &cancellables)
    }
    
    private func updateConfirmButtonState(_ text: String) {
        confirmButton.isEnabled = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func handleCancel() {
        let current = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let original = initialName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        if current.isEmpty || current == original {
            cancelButtonTappedSubject.send(())
        } else {
            requestCancelConfirmationSubject.send(())
        }
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
                self.handleCancel()
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
