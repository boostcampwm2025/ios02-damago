//
//  MiniGameView.swift
//  Damago
//
//  Created by loyH on 1/26/26.
//

import UIKit

final class MiniGameView: UIView {
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
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "미니게임"
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = .textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let upcomingFeatureCardView: UpcomingFeatureCardView = {
        let view = UpcomingFeatureCardView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let cardGameCardView: UpcomingFeatureCardView = {
        let view = UpcomingFeatureCardView()
        view.configure(title: "카드 뒤집기 게임", subtitle: "같은 그림을 찾아 코인을 획득하세요!")
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
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
    
    private func setupUI() {
        backgroundColor = .background
        setupHierarchy()
        setupConstraints()
    }
    
    private func setupHierarchy() {
        addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(cardGameCardView)
        contentStackView.addArrangedSubview(upcomingFeatureCardView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            
            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }
}
