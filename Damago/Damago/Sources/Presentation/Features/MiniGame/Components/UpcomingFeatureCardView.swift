//
//  UpcomingFeatureCardView.swift
//  Damago
//
//  Created by loyH on 1/26/26.
//

import UIKit

/// "추후 업데이트 예정입니다." 안내용 카드 뷰
/// - 기존 `CardView`, 색상/타이포/spacing 시스템을 최대한 재사용합니다.
final class UpcomingFeatureCardView: UIView {
    // MARK: - Subviews

    private let cardView: CardView = {
        let view = CardView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "추후 업데이트 예정입니다."
        label.font = .body1
        label.textColor = .textPrimary
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        imageView.image = UIImage(systemName: "heart.fill", withConfiguration: config)
        imageView.tintColor = .damagoPrimary
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "더 좋은 서비스로 찾아뵙겠습니다."
        label.font = .body3
        label.textColor = .textSecondary
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var subtitleStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [iconImageView, subtitleLabel])
        stack.axis = .horizontal
        stack.spacing = .spacingM
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleStack])
        stack.axis = .vertical
        stack.spacing = .spacingM
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Public

    func configure(title: String, subtitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }

    // MARK: - Private

    private func setupUI() {
        backgroundColor = .clear
        setupHierarchy()
        setupConstraints()
    }

    private func setupHierarchy() {
        addSubview(cardView)
        cardView.addSubview(contentStack)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: topAnchor),
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: .spacingL),
            contentStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: .spacingL),
            contentStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -.spacingL),
            contentStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -.spacingL),

            iconImageView.widthAnchor.constraint(equalToConstant: 16),
            iconImageView.heightAnchor.constraint(equalToConstant: 16)
        ])
    }
}
