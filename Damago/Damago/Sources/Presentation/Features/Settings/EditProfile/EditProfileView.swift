//
//  EditProfileView.swift
//  Damago
//
//  Created by 박현수 on 1/21/26.
//

import UIKit

final class EditProfileView: UIView {
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = .spacingXL
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let nicknameContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let nicknameTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "닉네임"
        label.textColor = .textSecondary
        label.font = .body2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let nicknameInputBackground: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = .mediumButton
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let nicknameTextField: UITextField = {
        let textField = UITextField()
        textField.font = .body1
        textField.textColor = .textPrimary
        textField.placeholder = "닉네임을 입력해 주세요"
        textField.returnKeyType = .done
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    let anniversaryContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let anniversaryTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "우리가 만난 날"
        label.textColor = .textSecondary
        label.font = .body2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let anniversaryInputBackground: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = .mediumButton
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let anniversaryLabel: UILabel = {
        let label = UILabel()
        label.text = "날짜 선택"
        label.font = .body1
        label.textColor = .textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.locale = Locale(identifier: "ko_KR")
        picker.tintColor = .damagoPrimary
        picker.maximumDate = Date()
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    let saveButton: CTAButton = {
        let button = CTAButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let progressView = ProgressView()
    
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
        addSubview(scrollView)
        addSubview(saveButton)
        scrollView.addSubview(contentStackView)
        
        contentStackView.addArrangedSubview(nicknameContainer)
        contentStackView.addArrangedSubview(anniversaryContainer)
        
        nicknameContainer.addSubview(nicknameTitleLabel)
        nicknameContainer.addSubview(nicknameInputBackground)
        nicknameInputBackground.addSubview(nicknameTextField)
        
        anniversaryContainer.addSubview(anniversaryTitleLabel)
        anniversaryContainer.addSubview(anniversaryInputBackground)
        anniversaryInputBackground.addSubview(anniversaryLabel)
        anniversaryInputBackground.addSubview(datePicker)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate(
            [
                // ScrollView & Main Button
                scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
                scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
                scrollView.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -.spacingM),
                
                saveButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingM),
                saveButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingM),
                saveButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -.spacingXL),
                
                // Content StackView
                contentStackView.topAnchor.constraint(
                    equalTo: scrollView.contentLayoutGuide.topAnchor,
                    constant: .spacingL
                ),
                contentStackView.leadingAnchor.constraint(
                    equalTo: scrollView.contentLayoutGuide.leadingAnchor,
                    constant: .spacingM
                ),
                contentStackView.trailingAnchor.constraint(
                    equalTo: scrollView.contentLayoutGuide.trailingAnchor,
                    constant: -.spacingM
                ),
                contentStackView.bottomAnchor.constraint(
                    equalTo: scrollView.contentLayoutGuide.bottomAnchor,
                    constant: -.spacingL
                ),
                contentStackView.widthAnchor.constraint(
                    equalTo: scrollView.frameLayoutGuide.widthAnchor,
                    constant: -.spacingM * 2
                ),
                
                // Nickname Section
                nicknameTitleLabel.topAnchor.constraint(
                    equalTo: nicknameContainer.topAnchor
                ),
                nicknameTitleLabel.leadingAnchor.constraint(
                    equalTo: nicknameContainer.leadingAnchor,
                    constant: .spacingS
                ),
                
                nicknameInputBackground.topAnchor
                    .constraint(
                        equalTo: nicknameTitleLabel.bottomAnchor,
                        constant: .spacingS
                    ),
                nicknameInputBackground.leadingAnchor
                    .constraint(
                        equalTo: nicknameContainer.leadingAnchor
                    ),
                nicknameInputBackground.trailingAnchor
                    .constraint(
                        equalTo: nicknameContainer.trailingAnchor
                    ),
                nicknameInputBackground.heightAnchor
                    .constraint(
                        equalToConstant: 56
                    ),
                nicknameInputBackground.bottomAnchor
                    .constraint(
                        equalTo: nicknameContainer.bottomAnchor
                    ),
                
                nicknameTextField.leadingAnchor
                    .constraint(
                        equalTo: nicknameInputBackground.leadingAnchor,
                        constant: .spacingM
                    ),
                nicknameTextField.trailingAnchor
                    .constraint(
                        equalTo: nicknameInputBackground.trailingAnchor,
                        constant: -.spacingM
                    ),
                nicknameTextField.centerYAnchor
                    .constraint(
                        equalTo: nicknameInputBackground.centerYAnchor
                    ),
                
                // Anniversary Section
                anniversaryTitleLabel.topAnchor
                    .constraint(
                        equalTo: anniversaryContainer.topAnchor
                    ),
                anniversaryTitleLabel.leadingAnchor
                    .constraint(
                        equalTo: anniversaryContainer.leadingAnchor,
                        constant: .spacingS
                    ),
                
                anniversaryInputBackground.topAnchor
                    .constraint(
                        equalTo: anniversaryTitleLabel.bottomAnchor,
                        constant: .spacingS
                    ),
                anniversaryInputBackground.leadingAnchor
                    .constraint(
                        equalTo: anniversaryContainer.leadingAnchor
                    ),
                anniversaryInputBackground.trailingAnchor
                    .constraint(
                        equalTo: anniversaryContainer.trailingAnchor
                    ),
                anniversaryInputBackground.heightAnchor
                    .constraint(
                        equalToConstant: 56
                    ),
                anniversaryInputBackground.bottomAnchor
                    .constraint(
                        equalTo: anniversaryContainer.bottomAnchor
                    ),
                
                anniversaryLabel.leadingAnchor
                    .constraint(
                        equalTo: anniversaryInputBackground.leadingAnchor,
                        constant: .spacingM
                    ),
                anniversaryLabel.centerYAnchor
                    .constraint(
                        equalTo: anniversaryInputBackground.centerYAnchor
                    ),
                
                datePicker.trailingAnchor
                    .constraint(
                        equalTo: anniversaryInputBackground.trailingAnchor,
                        constant: -.spacingM
                    ),
                datePicker.centerYAnchor
                    .constraint(
                        equalTo: anniversaryInputBackground.centerYAnchor
                    )
            ]
        )
    }
}

extension EditProfileView {
    func updateSaveButton(isEnabled: Bool) {
        let activeConfig = CTAButton.Configuration(
            backgroundColor: .damagoPrimary,
            foregroundColor: .white,
            image: nil,
            title: "저장하기",
            subtitle: nil
        )
        
        let disabledConfig = CTAButton.Configuration(
            backgroundColor: .textTertiary,
            foregroundColor: .white,
            image: nil,
            title: "저장하기",
            subtitle: nil
        )
        
        saveButton.configure(active: activeConfig, disabled: disabledConfig)
        saveButton.isEnabled = isEnabled
    }

    func setIsUpdating(_ isUpdating: Bool) {
        if isUpdating {
            progressView.show(in: self, message: "수정 중...")
        } else {
            progressView.hide()
        }
        nicknameTextField.isEnabled = !isUpdating
        datePicker.isEnabled = !isUpdating
    }
}
