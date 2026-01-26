//
//  HistoryCell.swift
//  Damago
//
//  Created by 박현수 on 1/26/26.
//

import UIKit

final class DailyQuestionHistoryCell: UICollectionViewCell {
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = .mediumButton
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.textTertiary.withAlphaComponent(0.3).cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .caption
        label.textColor = .textTertiary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let questionLabel: UILabel = {
        let label = UILabel()
        label.font = .body2
        label.textColor = .textPrimary
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.textTertiary.withAlphaComponent(0.1)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let myAnswerLabel: UILabel = {
        let label = UILabel()
        label.font = .body3
        label.textColor = .damagoPrimary
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let opponentAnswerLabel: UILabel = {
        let label = UILabel()
        label.font = .body3
        label.textColor = .textSecondary
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with item: DailyQuestionHistory) {
        dateLabel.text = item.date.toString()
        questionLabel.text = "Q. \(item.question)"
        myAnswerLabel.text = "나: \(item.myAnswer)"
        opponentAnswerLabel.text = "상대: \(item.opponentAnswer)"
    }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        [dateLabel, questionLabel, dividerView, myAnswerLabel, opponentAnswerLabel].forEach(containerView.addSubview)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            dateLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: .spacingM),
            dateLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: .spacingM),
            
            questionLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: .spacingXS),
            questionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: .spacingM),
            questionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -.spacingM),
            
            dividerView.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: .spacingM),
            dividerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: .spacingM),
            dividerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -.spacingM),
            dividerView.heightAnchor.constraint(equalToConstant: 1),
            
            myAnswerLabel.topAnchor.constraint(equalTo: dividerView.bottomAnchor, constant: .spacingM),
            myAnswerLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: .spacingM),
            myAnswerLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -.spacingM),
            
            opponentAnswerLabel.topAnchor.constraint(equalTo: myAnswerLabel.bottomAnchor, constant: .spacingS),
            opponentAnswerLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: .spacingM),
            opponentAnswerLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -.spacingM),
            opponentAnswerLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -.spacingM)
        ])
    }
}

final class BalanceGameHistoryCell: UICollectionViewCell {
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = .mediumButton
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.textTertiary.withAlphaComponent(0.3).cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let matchBadgeView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.textTertiary.withAlphaComponent(0.1)
        view.layer.cornerRadius = .smallElement
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let matchLabel: UILabel = {
        let label = UILabel()
        label.font = .caption
        label.textColor = .textSecondary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let questionLabel: UILabel = {
        let label = UILabel()
        label.font = .body2
        label.textColor = .textPrimary
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let choiceStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = .spacingS
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let leftChoiceView = ChoiceView()
    private let rightChoiceView = ChoiceView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with item: BalanceGameHistory) {
        questionLabel.text = item.question
        
        if item.isMatch {
            matchBadgeView.backgroundColor = .damagoPrimary.withAlphaComponent(0.1)
            matchLabel.text = "통했어요!"
            matchLabel.textColor = .damagoPrimary
        } else {
            matchBadgeView.backgroundColor = UIColor.textTertiary.withAlphaComponent(0.1)
            matchLabel.text = "아쉬워요.."
            matchLabel.textColor = .textTertiary
        }
        
        // 1: OptionA (Left), 2: OptionB (Right)
        let isLeftMyChoice = (item.myChoice == 1)
        let isLeftOpponentChoice = (item.opponentChoice == 1)
        
        let isRightMyChoice = (item.myChoice == 2)
        let isRightOpponentChoice = (item.opponentChoice == 2)
        
        leftChoiceView.configure(
            text: item.optionA,
            isMyChoice: isLeftMyChoice,
            isOpponentChoice: isLeftOpponentChoice
        )
        rightChoiceView.configure(
            text: item.optionB,
            isMyChoice: isRightMyChoice,
            isOpponentChoice: isRightOpponentChoice
        )
    }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        [matchBadgeView, questionLabel, choiceStackView].forEach(containerView.addSubview)
        matchBadgeView.addSubview(matchLabel)
        
        choiceStackView.addArrangedSubview(leftChoiceView)
        choiceStackView.addArrangedSubview(rightChoiceView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            matchBadgeView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: .spacingM),
            matchBadgeView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: .spacingM),
            matchBadgeView.heightAnchor.constraint(equalToConstant: 24),
            
            matchLabel.leadingAnchor.constraint(equalTo: matchBadgeView.leadingAnchor, constant: 8),
            matchLabel.trailingAnchor.constraint(equalTo: matchBadgeView.trailingAnchor, constant: -8),
            matchLabel.centerYAnchor.constraint(equalTo: matchBadgeView.centerYAnchor),
            
            questionLabel.topAnchor.constraint(equalTo: matchBadgeView.bottomAnchor, constant: .spacingS),
            questionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: .spacingM),
            questionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -.spacingM),
            
            choiceStackView.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: .spacingM),
            choiceStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: .spacingM),
            choiceStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -.spacingM),
            choiceStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -.spacingM),
            choiceStackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 64)
        ])
    }
}

private final class ChoiceView: UIView {
    private let containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = .smallElement
        view.layer.borderWidth = 1
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let textLabel: UILabel = {
        let label = UILabel()
        label.font = .body3
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let badgesStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.distribution = .fillProportionally
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(text: String, isMyChoice: Bool, isOpponentChoice: Bool) {
        textLabel.text = text
        
        badgesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if isMyChoice {
            badgesStackView.addArrangedSubview(createBadge(title: "Me", color: .damagoPrimary))
        }
        if isOpponentChoice {
            badgesStackView.addArrangedSubview(createBadge(title: "You", color: .damagoSecondary))
        }
        
        if isMyChoice && isOpponentChoice {
            containerView.backgroundColor = .damagoPrimary.withAlphaComponent(0.1)
            containerView.layer.borderColor = UIColor.damagoPrimary.cgColor
            textLabel.textColor = .textPrimary
        } else if isMyChoice {
            containerView.backgroundColor = .damagoPrimary.withAlphaComponent(0.05)
            containerView.layer.borderColor = UIColor.damagoPrimary.withAlphaComponent(0.5).cgColor
            textLabel.textColor = .textPrimary
        } else if isOpponentChoice {
            containerView.backgroundColor = .damagoSecondary.withAlphaComponent(0.05)
            containerView.layer.borderColor = UIColor.damagoSecondary.withAlphaComponent(0.5).cgColor
            textLabel.textColor = .textPrimary
        } else {
            containerView.backgroundColor = UIColor.textTertiary.withAlphaComponent(0.05)
            containerView.layer.borderColor = UIColor.clear.cgColor
            textLabel.textColor = .textTertiary
        }
    }
    
    private func createBadge(title: String, color: UIColor) -> UIView {
        let container = UIView()
        container.backgroundColor = color
        container.layer.cornerRadius = 4
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 10, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 2),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -2)
        ])
        
        return container
    }
    
    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(textLabel)
        containerView.addSubview(badgesStackView)
        
        NSLayoutConstraint.activate(
            [
                containerView.topAnchor.constraint(equalTo: topAnchor),
                containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
                containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
                containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
                
                textLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                textLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: -8),
                textLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: .spacingS),
                textLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -.spacingS),
                
                badgesStackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                badgesStackView.topAnchor.constraint(equalTo: textLabel.bottomAnchor, constant: .spacingXS),
                badgesStackView.bottomAnchor.constraint(
                    lessThanOrEqualTo: containerView.bottomAnchor,
                    constant: -.spacingXS
                )
            ]
        )
    }
}
