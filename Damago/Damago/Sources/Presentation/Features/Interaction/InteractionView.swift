//
//  InteractionView.swift
//  Damago
//
//  Created by 김재영 on 1/15/26.
//

import UIKit

final class InteractionView: UIView {
    let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = .spacingM
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: .spacingM, bottom: .spacingXL, right: .spacingM)
        return stackView
    }()
    
    private let titleLabel: UILabel = .makeScreenTitle()

    private let subtitleLabel: UILabel = .makeScreenSubtitle()

    lazy var questionCardView = DailyQuestionCardView()
    lazy var balanceGameCardView: UIView = makeCardView()
    
    let historyButton: UIButton = {
        let button = CTAButton()
        let config = CTAButton.Configuration(
            backgroundColor: .white,
            foregroundColor: .damagoPrimary,
            image: UIImage(systemName: "clock.arrow.circlepath"),
            title: "지난 활동 확인하기",
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
    
    func configure(title: String, subtitle: String) {
        self.titleLabel.text = title
        self.subtitleLabel.text = subtitle
    }
    
    func setSubtitleAlpha(_ alpha: CGFloat) {
        subtitleLabel.alpha = alpha
    }
    
    private func setupUI() {
        backgroundColor = .background
        setupHierarchy()
        setupConstraints()
    }
    
    private func setupHierarchy() {
        addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(subtitleLabel)
        contentStackView.setCustomSpacing(.spacingXS, after: titleLabel)
        contentStackView.setCustomSpacing(.spacingXL, after: subtitleLabel)
        
        contentStackView.addArrangedSubview(questionCardView)
        contentStackView.addArrangedSubview(balanceGameCardView)
        contentStackView.addArrangedSubview(historyButton)
        contentStackView.setCustomSpacing(.spacingXL, after: balanceGameCardView)
    }
    
    private func setupConstraints() {
        // ScrollView Layout
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            
            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            questionCardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200),
            balanceGameCardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 280),
            historyButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func makeCardView() -> UIView {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = .largeCard
        view.layer.cornerCurve = .continuous
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 10)
        view.layer.shadowRadius = 20
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
}
