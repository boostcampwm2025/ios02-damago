//
//  DailyQuestionInputView.swift
//  Damago
//
//  Created by 김재영 on 1/19/26.
//

import UIKit

final class DailyQuestionInputView: UIView {
    let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .onDrag
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = .spacingL
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: .spacingL, left: .spacingM, bottom: .spacingL, right: .spacingM)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // MARK: - 상단 질문 카드
    private let questionCardView: CardView = {
        let view = CardView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let headerView: CardHeaderView = {
        let view = CardHeaderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let helperTextLabel: UILabel = {
        let label = UILabel()
        let attributedString = NSMutableAttributedString()
            
        attributedString.append(
            .iconWithText(
                systemName: "heart.fill",
                text: " 솔직한 마음을 전해보세요",
                iconColor: .systemPink,
                textColor: .textTertiary,
                font: .caption
            )
        )
        
        label.attributedText = attributedString
        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - 하단 답변 카드
    let inputCardView: CardView = {
        let view = CardView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let textView: UITextView = {
        let textView = UITextView()
        textView.font = .body1
        textView.textColor = .textPrimary
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        textView.maxLength = 200
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "여기에 답변을 입력하세요."
        label.font = .body1
        label.textColor = .textTertiary
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let submitButton: CTAButton = {
        let button = CTAButton()
        let config = CTAButton.Configuration(
            backgroundColor: .damagoPrimary,
            foregroundColor: .white,
            image: nil,
            title: "답변 제출",
            subtitle: nil
        )
        
        let disabledConfig = CTAButton.Configuration(
            backgroundColor: .disabled,
            foregroundColor: .white,
            image: nil,
            title: "답변 내용을 입력해주세요",
            subtitle: nil
        )
        
        button.configure(enabled: config, disabled: disabledConfig)
        button.isEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    struct ButtonState: Equatable {
        let isEnabled: Bool
        let isLoading: Bool
    }
    
    func updateSubmitButton(state: ButtonState) {
        if state.isLoading {
            submitButton.setTitle("전송 중...")
        } else {
            submitButton.setTitle(state.isEnabled ? "답변 제출" : "답변 내용을 입력해주세요")
        }
        
        submitButton.isEnabled = state.isEnabled
    }
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        let attributedString = NSMutableAttributedString()
        attributedString.append(
            .iconWithText(
                systemName: "lock.fill",
                text: " 답변을 제출하면 상대방의 답변도 볼 수 있어요!",
                iconColor: .textTertiary,
                textColor: .clear,
                font: .caption
            )
        )
        label.attributedText = attributedString
        label.font = .caption
        label.textColor = .textTertiary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - 답변 결과 카드
    let myAnswerResultCardView: AnswerCardView = {
        let view = AnswerCardView()
        return view
    }()
    
    let opponentAnswerResultCardView: AnswerCardView = {
        let view = AnswerCardView()
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    func configure(title: String) {
        headerView.configure(title: title, foods: 3, coins: 30)
    }
    
    func updateView(isAnswered: Bool) {
        inputCardView.isHidden = isAnswered
        submitButton.isHidden = isAnswered
        infoLabel.isHidden = isAnswered
        
        myAnswerResultCardView.isHidden = !isAnswered
        opponentAnswerResultCardView.isHidden = !isAnswered
    }
    
    private func setupUI() {
        backgroundColor = .background
        setupHierarchy()
        setupConstraints()
    }
    
    private func setupHierarchy() {
        addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        
        [headerView, helperTextLabel].forEach {
            questionCardView.addSubview($0)
        }
        
        [textView, placeholderLabel].forEach {
            inputCardView.addSubview($0)
        }
        
        [
            questionCardView,
            inputCardView,
            submitButton,
            infoLabel,
            myAnswerResultCardView,
            opponentAnswerResultCardView
        ].forEach {
            contentStackView.addArrangedSubview($0)
        }
        
        contentStackView.setCustomSpacing(.spacingM, after: submitButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            headerView.topAnchor.constraint(equalTo: questionCardView.topAnchor, constant: .spacingL),
            headerView.leadingAnchor.constraint(equalTo: questionCardView.leadingAnchor, constant: .spacingL),
            headerView.trailingAnchor.constraint(equalTo: questionCardView.trailingAnchor, constant: -.spacingL),
            
            helperTextLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: .spacingM),
            helperTextLabel.leadingAnchor.constraint(equalTo: questionCardView.leadingAnchor, constant: .spacingL),
            helperTextLabel.bottomAnchor.constraint(equalTo: questionCardView.bottomAnchor, constant: -.spacingL),

            textView.topAnchor.constraint(equalTo: inputCardView.topAnchor, constant: .spacingL),
            textView.leadingAnchor.constraint(equalTo: inputCardView.leadingAnchor, constant: .spacingL),
            textView.trailingAnchor.constraint(equalTo: inputCardView.trailingAnchor, constant: -.spacingL),
            textView.heightAnchor.constraint(equalToConstant: 120),
            
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: .spacingS),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 5),
            
            inputCardView.bottomAnchor.constraint(greaterThanOrEqualTo: textView.bottomAnchor, constant: .spacingL)
        ])
    }
}

extension DailyQuestionInputView {
    enum LayoutMode {
            case input
            case result
        }
        
    func updateLayoutMode(_ mode: LayoutMode) {
        switch mode {
        case .input:
            inputCardView.isHidden = false
            submitButton.isHidden = false
            infoLabel.isHidden = false
            
            myAnswerResultCardView.isHidden = true
            opponentAnswerResultCardView.isHidden = true
            
        case .result:
            inputCardView.isHidden = true
            submitButton.isHidden = true
            infoLabel.isHidden = true
            
            myAnswerResultCardView.isHidden = false
            opponentAnswerResultCardView.isHidden = false
        }
    }
}
