//
//  DailyQuestionView.swift
//  Damago
//
//  Created by 김재영 on 1/19/26.
//

import UIKit

final class DailyQuestionView: UIView {
    private let missionBadge: CapsuleLabel = {
        let label = CapsuleLabel(padding: .init(top: .spacingXS, left: .spacingS, bottom: .spacingXS, right: .spacingS))
        label.text = "일일 미션"
        label.font = .caption
        label.textColor = .systemBlue
        label.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let rewardBadge: CapsuleLabel = {
        let label = CapsuleLabel(padding: .init(top: .spacingXS, left: .spacingS, bottom: .spacingXS, right: .spacingS))
        label.font = .caption
        label.backgroundColor = .systemOrange.withAlphaComponent(0.1)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "오늘의 질문"
        label.font = .title2
        label.textColor = .textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
        setupCardStyle()
        setupHierarchy()
        setupConstraints()
        setupRewards()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(question: String) {
        questionLabel.text = "\"\(question)\""
    }
    
    private func setupCardStyle() {
        backgroundColor = .white
        layer.cornerRadius = .largeCard
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 10)
        layer.shadowRadius = 20
    }
    
    private func setupHierarchy() {
        [missionBadge, rewardBadge, titleLabel, questionLabel, submitButton].forEach {
            addSubview($0)
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            missionBadge.topAnchor.constraint(equalTo: topAnchor, constant: .spacingL),
            missionBadge.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingL),
            
            rewardBadge.centerYAnchor.constraint(equalTo: missionBadge.centerYAnchor),
            rewardBadge.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingL),
            
            titleLabel.topAnchor.constraint(equalTo: missionBadge.bottomAnchor, constant: .spacingM),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingL),
            
            questionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: .spacingXS + .spacingS),
            questionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingL),
            questionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingL),
            
            submitButton.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: .spacingL),
            submitButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingL),
            submitButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingL),
            submitButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -.spacingL)
        ])
    }
    
    private func setupRewards() {
        let combinedString = NSMutableAttributedString()
        
        combinedString.append(
            .iconWithText(
                systemName: "carrot.fill",
                text: "  +3",
                iconColor: .damagoPrimary,
                font: .caption
            )
        )
        
        combinedString.append(
            NSAttributedString(
                string: "   |   ",
                attributes: [
                    .font: UIFont.caption,
                    .foregroundColor: UIColor.lightGray.withAlphaComponent(0.5)
                ]
            )
        )
        
        combinedString.append(
            .iconWithText(
                systemName: "dollarsign.circle",
                text: "  +30",
                iconColor: .systemYellow,
                font: .caption
            )
        )
        
        rewardBadge.attributedText = combinedString
    }
}
