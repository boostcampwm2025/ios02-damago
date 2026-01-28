//
//  PetNamingPopupView.swift
//  Damago
//
//  Created by 김재영 on 1/26/26.
//

import UIKit
import Combine

final class PetNamingPopupView: UIView {
    let confirmButtonTappedSubject = PassthroughSubject<String, Never>()
    let cancelButtonTappedSubject = PassthroughSubject<Void, Never>()
    let requestCancelConfirmationSubject = PassthroughSubject<Void, Never>()
    
    private var containerViewCenterYConstraint: NSLayoutConstraint?
    private var initialName: String?
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .damagoSecondary
        view.layer.cornerRadius = .largeCard
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let petBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = .mediumButton
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.systemGray5.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let petView: PetView = {
        let view = PetView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "마음을 담아 이름을 선물해주세요."
        label.font = .body1
        label.textColor = .textPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "이름 입력"
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
        let config = CTAButton.Configuration(
            backgroundColor: .textTertiary,
            foregroundColor: .white,
            title: "취소",
            font: .body2
        )
        
        button.configure(active: config, disabled: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let confirmButton: CTAButton = {
        let button = CTAButton()
        let config = CTAButton.Configuration(
            backgroundColor: .damagoPrimary,
            foregroundColor: .white,
            title: "만나서 반가워!",
            font: .body2
        )
        let disabledConfig = CTAButton.Configuration(
            backgroundColor: .textTertiary,
            foregroundColor: .white,
            title: "이름을 알려줘!",
            font: .body2
        )
        
        button.configure(active: config, disabled: disabledConfig)
        button.isEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var cancellables = Set<AnyCancellable>()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        bind()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with petType: DamagoType, initialName: String?) {
        petView.configure(with: petType)
        let trimmed = initialName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.initialName = trimmed
        nameTextField.text = trimmed
        confirmButton.isEnabled = !trimmed.isEmpty
    }

    /// 비동기 prefill 등으로 나중에 초기 이름을 설정할 때 사용
    func updateInitialName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        initialName = trimmed
        nameTextField.text = trimmed
        confirmButton.isEnabled = !trimmed.isEmpty
    }
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        setupHierarchy()
        setupConstraints()
        
        nameTextField.delegate = self
        setupKeyboard()
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
            .map { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .sink { [weak self] isEnabled in
                self?.confirmButton.isEnabled = isEnabled
            }
            .store(in: &cancellables)
    }
    
    private func handleCancel() {
        let current = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let original = initialName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        // 변경 내용이 없거나 비어 있으면 바로 닫기
        if current.isEmpty || current == original {
            cancelButtonTappedSubject.send(())
        } else {
            requestCancelConfirmationSubject.send(())
        }
    }
    
    private func setupHierarchy() {
        addSubview(containerView)
        [petBackgroundView, titleLabel, nameTextField, buttonStackView].forEach {
            containerView.addSubview($0)
        }
        petBackgroundView.addSubview(petView)
        
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
            
            petBackgroundView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: .spacingL),
            petBackgroundView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            petBackgroundView.widthAnchor.constraint(equalToConstant: 150),
            petBackgroundView.heightAnchor.constraint(equalTo: petBackgroundView.widthAnchor),
            
            petView.topAnchor.constraint(equalTo: petBackgroundView.topAnchor, constant: .spacingS),
            petView.leadingAnchor.constraint(equalTo: petBackgroundView.leadingAnchor, constant: .spacingS),
            petView.trailingAnchor.constraint(equalTo: petBackgroundView.trailingAnchor, constant: -.spacingS),
            petView.bottomAnchor.constraint(equalTo: petBackgroundView.bottomAnchor, constant: -.spacingS),
            
            titleLabel.topAnchor.constraint(equalTo: petBackgroundView.bottomAnchor, constant: .spacingM),
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
}

extension PetNamingPopupView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if confirmButton.isEnabled {
            confirmButton.sendActions(for: .touchUpInside)
        }
        return true
    }
}

#Preview {
    PetNamingPopupView()
}
