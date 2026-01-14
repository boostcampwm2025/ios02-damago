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
    private let viewModel: PokePopupViewModel
    private var cancellables = Set<AnyCancellable>()
    
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let shortcutSelectedSubject = PassthroughSubject<String, Never>()
    private let textChangedSubject = PassthroughSubject<String, Never>()
    private let sendButtonTappedSubject = PassthroughSubject<Void, Never>()
    private let cancelButtonTappedSubject = PassthroughSubject<Void, Never>()
    
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
    
    init(viewModel: PokePopupViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupUI()
        setupActions()
        bindViewModel()
    }
    
    override init(frame: CGRect) {
        fatalError("Use init(viewModel:) instead")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        setupHierarchy()
        setupConstraints()
        setupKeyboardDismiss()
    }
    
    private func bindViewModel() {
        let output = viewModel.transform(
            PokePopupViewModel.Input(
                viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
                shortcutSelected: shortcutSelectedSubject.eraseToAnyPublisher(),
                textChanged: textChangedSubject.eraseToAnyPublisher(),
                sendButtonTapped: sendButtonTappedSubject.eraseToAnyPublisher(),
                cancelButtonTapped: cancelButtonTappedSubject.eraseToAnyPublisher()
            )
        )
        
        output
            .sink { [weak self] state in
                self?.updateUI(with: state)
            }
            .store(in: &cancellables)
        
        viewDidLoadSubject.send()
    }
    
    private func updateUI(with state: PokePopupViewModel.State) {
        customTextField.text = state.currentText
        
        // shortcuts가 변경되면 버튼 다시 생성
        if !state.shortcuts.isEmpty {
            setupExampleButtons(shortcuts: state.shortcuts)
        }
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
    
    private func setupExampleButtons(shortcuts: [PokeShortcut]) {
        // 기존 버튼 제거
        exampleButtonsView.arrangedSubviews.forEach {
            exampleButtonsView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        
        // 새 버튼 추가
        shortcuts.forEach { shortcut in
            let button = createExampleButton(message: shortcut.message)
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
            self?.shortcutSelectedSubject.send(message)
        }, for: .touchUpInside)
        
        return button
    }
    
    private func setupActions() {
        cancelButton.addAction(UIAction { [weak self] _ in
            self?.cancelButtonTappedSubject.send(())
        }, for: .touchUpInside)
        
        sendButton.addAction(UIAction { [weak self] _ in
            self?.sendButtonTappedSubject.send(())
        }, for: .touchUpInside)
        
        // 텍스트 필드 변경 감지
        customTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    @objc
    private func textFieldDidChange() {
        textChangedSubject.send(customTextField.text ?? "")
    }
}

extension PokePopupView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
