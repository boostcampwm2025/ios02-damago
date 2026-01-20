//
//  DailyQuestionCardView.swift
//  Damago
//
//  Created by 김재영 on 1/19/26.
//

import UIKit

final class DailyQuestionCardView: UIView {
    private let view: CardView = {
        let view = CardView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let headerView: CardHeaderView = {
        let view = CardHeaderView()
        view.configure(title: "오늘의 질문", foods: 3, coins: 30)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let questionLabel: UILabel = {
        let label = UILabel()
        label.text = "\"질문을 불러오는 중...\""
        label.font = .body1
        label.textColor = .textSecondary
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
        
        button.configure(active: config, disabled: config)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.05
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    func configure(question: String) {
        questionLabel.text = question
    }
    
    private func setupUI() {
        setupHierarchy()
        setupConstraints()
    }
    
    private func setupHierarchy() {
        addSubview(view)
        [headerView, questionLabel, submitButton].forEach {
            view.addSubview($0)
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor),
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            headerView.topAnchor.constraint(equalTo: topAnchor, constant: .spacingL),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingL),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingL),
            
            questionLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: .spacingXS + .spacingS),
            questionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingL),
            questionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingL),
            
            submitButton.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: .spacingL),
            submitButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingL),
            submitButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingL),
            submitButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -.spacingL)
        ])
    }
}
