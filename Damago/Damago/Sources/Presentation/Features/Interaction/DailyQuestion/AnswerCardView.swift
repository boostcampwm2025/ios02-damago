//
//  AnswerCardView.swift
//  Damago
//
//  Created by 김재영 on 1/19/26.
//

import UIKit

final class AnswerCardView: UIView {
    private let cardView: CardView = {
        let view = CardView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .body1
        label.textColor = .textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = .body2
        label.textColor = .textSecondary
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let lockStackView: UIStackView = {
        let icon = UIImageView(image: UIImage(systemName: "lock.fill"))
        icon.tintColor = .textTertiary
        icon.contentMode = .scaleAspectFit
        
        let label = UILabel()
        label.text = "상대방이 아직 작성하지 않았어요"
        label.font = .caption
        label.textColor = .textTertiary
        
        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.axis = .horizontal
        stack.spacing = .spacingS
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    func configure(with model: AnswerCardUIModel) {
        titleLabel.text = model.title
        
        switch model.type {
        case .unlocked:
            contentLabel.text = model.content
            contentLabel.isHidden = false
            lockStackView.isHidden = true

        case .locked:
            contentLabel.isHidden = true
            lockStackView.isHidden = false

            if let message = model.placeholderText {
                if let label = lockStackView.arrangedSubviews.last as? UILabel {
                    label.text = message
                }
            }
        }
    }
    
    private func setupUI() {
        setupHierarchy()
        setupConstraints()
    }
    
    private func setupHierarchy() {
        addSubview(cardView)
        [titleLabel, contentLabel, lockStackView].forEach {
            cardView.addSubview($0)
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: topAnchor),
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: .spacingL),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: .spacingL),
            
            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: .spacingM),
            contentLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: .spacingL),
            contentLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -.spacingL),
            contentLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -.spacingL),
            
            lockStackView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            lockStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: .spacingXS + .spacingS),
            lockStackView.leadingAnchor.constraint(greaterThanOrEqualTo: cardView.leadingAnchor, constant: .spacingM),
            lockStackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -.spacingL)
        ])
    }
}
