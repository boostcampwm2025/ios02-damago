//
//  PokePopupView.swift
//  Damago
//
//  Created by loyH on 1/13/26.
//

import UIKit

final class PokePopupView: UIView {
    weak var textFieldDelegate: UITextFieldDelegate?
    private let exampleMessages = [
        "안녕!",
        "밥 먹었어?",
        "오늘 하루 어땠어?",
        "사랑해 💕"
    ]
    
    var onMessageSelected: ((String) -> Void)?
    var onCancel: (() -> Void)?
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .damagoPrimary
        view.layer.cornerRadius = .largeCard
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 5
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "콕 찌르기 메시지"
        label.font = .title1
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let exampleButtonsView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = .spacingS
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let customTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "직접 입력하기"
        textField.font = .body1
        textField.textColor = .textPrimary
        textField.backgroundColor = .white
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
    
    private let cancelButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .white
        config.baseForegroundColor = .damagoPrimary
        config.title = "취소"
        config.cornerStyle = .fixed
        config.background.cornerRadius = .mediumButton
        
        var titleContainer = AttributeContainer()
        titleContainer.font = .title3
        config.attributedTitle = AttributedString("취소", attributes: titleContainer)
        
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let sendButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .white
        config.baseForegroundColor = .damagoPrimary
        config.title = "전송"
        config.cornerStyle = .fixed
        config.background.cornerRadius = .mediumButton
        
        var titleContainer = AttributeContainer()
        titleContainer.font = .title3
        config.attributedTitle = AttributedString("전송", attributes: titleContainer)
        
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupActions()
    }
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        setupHierarchy()
        setupConstraints()
        setupExampleButtons()
        setupKeyboardDismiss()
    }
    
    private func setupKeyboardDismiss() {
        // 텍스트 필드 delegate 설정
        customTextField.delegate = self
        customTextField.returnKeyType = .done
        
        // 화면 탭 시 키보드 내리기
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        addGestureRecognizer(tapGesture)
    }
    
    @objc
    private func dismissKeyboard() {
        customTextField.resignFirstResponder()
    }
    
    private func setupHierarchy() {
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(exampleButtonsView)
        containerView.addSubview(customTextField)
        containerView.addSubview(buttonStackView)
        
        buttonStackView.addArrangedSubview(cancelButton)
        buttonStackView.addArrangedSubview(sendButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingM),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingM),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: .spacingXL),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: .spacingM),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -.spacingM),
            
            exampleButtonsView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: .spacingXL),
            exampleButtonsView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: .spacingM),
            exampleButtonsView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -.spacingM),
            exampleButtonsView.heightAnchor.constraint(equalToConstant: 180),
            
            customTextField.topAnchor.constraint(equalTo: exampleButtonsView.bottomAnchor, constant: .spacingL),
            customTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: .spacingM),
            customTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -.spacingM),
            customTextField.heightAnchor.constraint(equalToConstant: 48),
            
            buttonStackView.topAnchor.constraint(equalTo: customTextField.bottomAnchor, constant: .spacingL),
            buttonStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: .spacingM),
            buttonStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -.spacingM),
            buttonStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -.spacingXL),
            
            cancelButton.heightAnchor.constraint(equalToConstant: 48),
            sendButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    private func setupExampleButtons() {
        exampleMessages.forEach { message in
            let button = createExampleButton(message: message)
            exampleButtonsView.addArrangedSubview(button)
        }
    }
    
    private func createExampleButton(message: String) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = UIColor.white.withAlphaComponent(0.9)
        config.baseForegroundColor = .damagoPrimary
        config.title = message
        config.cornerStyle = .fixed
        config.background.cornerRadius = .mediumButton
        
        var titleContainer = AttributeContainer()
        titleContainer.font = .body1
        config.attributedTitle = AttributedString(message, attributes: titleContainer)
        
        let button = UIButton(configuration: config)
        button.addAction(UIAction { [weak self] _ in
            self?.customTextField.text = message
        }, for: .touchUpInside)
        
        return button
    }
    
    private func setupActions() {
        cancelButton.addAction(UIAction { [weak self] _ in
            self?.onCancel?()
        }, for: .touchUpInside)
        
        sendButton.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            let message = self.customTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !message.isEmpty {
                self.onMessageSelected?(message)
            }
        }, for: .touchUpInside)
    }
}

extension PokePopupView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
