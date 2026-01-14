//
//  PokePopupView.swift
//  Damago
//
//  Created by loyH on 1/13/26.
//

import UIKit
import Combine

final class PokePopupView: UIView {
    weak var textFieldDelegate: UITextFieldDelegate?
    
    let shortcutSelectedSubject = PassthroughSubject<String, Never>()
    let shortcutSummaryChangedSubject = PassthroughSubject<(index: Int, summary: String), Never>()
    let shortcutMessageChangedSubject = PassthroughSubject<(index: Int, message: String), Never>()
    
    private var shortcutEditViews: [Int: (summaryField: UITextField, messageField: UITextField)] = [:]
    private var customTextFieldHeightConstraint: NSLayoutConstraint?
    private var exampleButtonsViewHeightConstraint: NSLayoutConstraint?
    private var isEditingMode = false
    
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
    
    let editButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "pencil")
        config.baseForegroundColor = .white
        
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let exampleButtonsView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = .spacingS
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    let customTextField: UITextField = {
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
        textField.setContentHuggingPriority(.required, for: .vertical)
        textField.setContentCompressionResistancePriority(.required, for: .vertical)
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
    
    let cancelButton: UIButton = {
        createActionButton(title: "취소")
    }()
    
    let sendButton: UIButton = {
        createActionButton(title: "전송")
    }()
    
    let saveButton: UIButton = {
        let button = createActionButton(title: "저장")
        button.isHidden = true
        return button
    }()
    
    private static func createActionButton(title: String) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .white
        config.baseForegroundColor = .damagoPrimary
        config.title = title
        config.cornerStyle = .fixed
        config.background.cornerRadius = .mediumButton
        
        var titleContainer = AttributeContainer()
        titleContainer.font = .title3
        config.attributedTitle = AttributedString(title, attributes: titleContainer)
        
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        setupHierarchy()
        setupConstraints()
        setupKeyboardDismiss()
    }
}

// MARK: - Setup & Layout
extension PokePopupView {
    private func setupHierarchy() {
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(editButton)
        containerView.addSubview(exampleButtonsView)
        containerView.addSubview(customTextField)
        containerView.addSubview(buttonStackView)
        
        buttonStackView.addArrangedSubview(cancelButton)
        buttonStackView.addArrangedSubview(sendButton)
        buttonStackView.addArrangedSubview(saveButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingS),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingS),
            
            // 타이틀 중앙 정렬 (editButton과 겹치지 않도록 제약 추가)
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: .spacingXL),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: .spacingM),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: editButton.leadingAnchor, constant: -.spacingS),
            
            // Edit 버튼은 타이틀과 같은 높이에 정렬
            editButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            editButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -.spacingM),
            editButton.widthAnchor.constraint(equalToConstant: 44),
            editButton.heightAnchor.constraint(equalToConstant: 44),
            
            exampleButtonsView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: .spacingXL),
            exampleButtonsView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: .spacingM),
            exampleButtonsView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -.spacingM),
            {
                let heightConstraint = exampleButtonsView.heightAnchor.constraint(equalToConstant: 220)
                exampleButtonsViewHeightConstraint = heightConstraint
                return heightConstraint
            }(),
            
            // 텍스트 필드 크기 고정
            customTextField.topAnchor.constraint(equalTo: exampleButtonsView.bottomAnchor, constant: .spacingM),
            customTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: .spacingM),
            customTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -.spacingM),
            {
                let heightConstraint = customTextField.heightAnchor.constraint(equalToConstant: 48)
                heightConstraint.priority = .required
                customTextFieldHeightConstraint = heightConstraint
                return heightConstraint
            }(),
            
            buttonStackView.topAnchor.constraint(equalTo: customTextField.bottomAnchor, constant: .spacingM),
            buttonStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: .spacingM),
            buttonStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -.spacingM),
            buttonStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -.spacingXL),
            
            cancelButton.heightAnchor.constraint(equalToConstant: 48),
            sendButton.heightAnchor.constraint(equalToConstant: 48),
            saveButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
}

// MARK: - View Update Methods
extension PokePopupView {
    func updateUI(with state: PokePopupViewModel.State) {
        // 텍스트 필드가 편집 중이 아닐 때만 업데이트 (입력 방해 방지)
        if !customTextField.isFirstResponder && customTextField.text != state.currentText {
            customTextField.text = state.currentText
        }
        
        // Edit 모드에 따라 UI 업데이트
        if state.isEditing {
            // Edit 모드로 전환할 때만 뷰 재설정
            if !isEditingMode {
                editButton.configuration?.image = UIImage(systemName: "xmark")
                sendButton.isHidden = true
                saveButton.isHidden = false
                customTextField.isHidden = true
                customTextFieldHeightConstraint?.constant = 0
                
                updateCancelButtonTitle("취소")
                
                setupEditViews(shortcuts: state.shortcuts)
                isEditingMode = true
            }
            
            exampleButtonsViewHeightConstraint?.constant = 350
            
            // Edit 모드의 텍스트 필드들 업데이트 (편집 중이 아닐 때만)
            updateEditFieldsText(with: state.shortcuts)
        } else {
            // 일반 모드로 전환할 때만 뷰 재설정
            if isEditingMode {
                editButton.configuration?.image = UIImage(systemName: "pencil")
                sendButton.isHidden = false
                saveButton.isHidden = true
                customTextField.isHidden = false
                customTextFieldHeightConstraint?.constant = 48
                
                // 일반 모드일 때 원래 높이로 복원
                exampleButtonsViewHeightConstraint?.constant = 220
                
                // 취소 버튼 텍스트 복원
                var cancelConfig = cancelButton.configuration
                var cancelTitleContainer = AttributeContainer()
                cancelTitleContainer.font = .title3
                cancelConfig?.attributedTitle = AttributedString("취소", attributes: cancelTitleContainer)
                cancelButton.configuration = cancelConfig
                
                if !state.shortcuts.isEmpty {
                    setupExampleButtons(shortcuts: state.shortcuts)
                }
                isEditingMode = false
            } else {
                // 처음 진입 시 또는 shortcuts가 업데이트되었을 때 버튼 설정
                if !state.shortcuts.isEmpty && exampleButtonsView.arrangedSubviews.isEmpty {
                    setupExampleButtons(shortcuts: state.shortcuts)
                }
            }
        }
    }
}

// MARK: - View Creation
extension PokePopupView {
    private func clearExampleButtonsView() {
        exampleButtonsView.arrangedSubviews.forEach {
            exampleButtonsView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }
    
    private func setupExampleButtons(shortcuts: [PokeShortcut]) {
        clearExampleButtonsView()
        
        shortcuts.forEach { shortcut in
            let button = createExampleButton(message: shortcut.message)
            exampleButtonsView.addArrangedSubview(button)
        }
    }
    
    private func setupEditViews(shortcuts: [PokeShortcut]) {
        clearExampleButtonsView()
        shortcutEditViews.removeAll()
        
        shortcuts.enumerated().forEach { index, shortcut in
            let editView = createEditView(for: shortcut, at: index)
            exampleButtonsView.addArrangedSubview(editView)
        }
    }
    
    private func updateEditFieldsText(with shortcuts: [PokeShortcut]) {
        shortcuts.enumerated().forEach { index, shortcut in
            guard let editViews = shortcutEditViews[index] else { return }
            
            // 편집 중이 아닐 때만 텍스트 업데이트
            if !editViews.summaryField.isFirstResponder && editViews.summaryField.text != shortcut.summary {
                editViews.summaryField.text = shortcut.summary
            }
            
            if !editViews.messageField.isFirstResponder && editViews.messageField.text != shortcut.message {
                editViews.messageField.text = shortcut.message
            }
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
            self?.shortcutSelectedSubject.send(message)
        }, for: .touchUpInside)
        
        return button
    }
    
    private func createEditView(for shortcut: PokeShortcut, at index: Int) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        containerView.layer.cornerRadius = .mediumButton
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let summaryField = createEditTextField(
            placeholder: "요약",
            text: shortcut.summary,
            font: .caption,
            textColor: .textSecondary
        )
        
        let messageField = createEditTextField(
            placeholder: "메시지",
            text: shortcut.message,
            font: .body1,
            textColor: .textPrimary
        )
        
        containerView.addSubview(summaryField)
        containerView.addSubview(messageField)
        
        NSLayoutConstraint.activate([
            summaryField.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            summaryField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            summaryField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            summaryField.heightAnchor.constraint(equalToConstant: 28),
            
            messageField.topAnchor.constraint(equalTo: summaryField.bottomAnchor, constant: 4),
            messageField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            messageField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            messageField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            messageField.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        // 텍스트 변경 감지
        summaryField.addTarget(self, action: #selector(summaryFieldDidChange(_:)), for: .editingChanged)
        messageField.addTarget(self, action: #selector(messageFieldDidChange(_:)), for: .editingChanged)
        
        summaryField.tag = index * 1000 + 0 // summary
        messageField.tag = index * 1000 + 1 // message
        
        shortcutEditViews[index] = (summaryField, messageField)
        
        return containerView
    }
    
    @objc
    private func summaryFieldDidChange(_ textField: UITextField) {
        let index = textField.tag / 1000
        shortcutSummaryChangedSubject.send((index: index, summary: textField.text ?? ""))
    }
    
    @objc
    private func messageFieldDidChange(_ textField: UITextField) {
        let index = textField.tag / 1000
        shortcutMessageChangedSubject.send((index: index, message: textField.text ?? ""))
    }
    
    private func createEditTextField(
        placeholder: String,
        text: String,
        font: UIFont,
        textColor: UIColor
    ) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.text = text
        textField.font = font
        textField.textColor = textColor
        textField.backgroundColor = .white
        textField.layer.cornerRadius = 4
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        textField.rightViewMode = .always
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }
    
    private func updateCancelButtonTitle(_ title: String) {
        var config = cancelButton.configuration
        var titleContainer = AttributeContainer()
        titleContainer.font = .title3
        config?.attributedTitle = AttributedString(title, attributes: titleContainer)
        cancelButton.configuration = config
    }
}

// MARK: - Keyboard Handling
extension PokePopupView {
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
        endEditing(true)
    }
}

extension PokePopupView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
