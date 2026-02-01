//
//  DamagoCell.swift
//  Damago
//
//  Created by 김재영 on 1/26/26.
//

import UIKit

final class DamagoCell: UICollectionViewCell {
    private let damagoView: DamagoView = {
        let view = DamagoView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let usingBadgeLabel: CapsuleLabel = {
        let label = CapsuleLabel(padding: .init(top: .spacingXS, left: .spacingS, bottom: .spacingXS, right: .spacingS))
        label.text = "Selected"
        label.font = .caption
        label.textColor = .white
        label.backgroundColor = .damagoPrimary
        label.textAlignment = .center
        label.isHidden = true
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

    func configure(with damagoType: DamagoType, isCurrentDamago: Bool = false) {
        damagoView.configure(with: damagoType)
        usingBadgeLabel.isHidden = !isCurrentDamago
        contentView.layer.borderColor = (isCurrentDamago ? UIColor.damagoPrimary : .systemGray5).cgColor
        contentView.layer.borderWidth = isCurrentDamago ? 2 : 1
    }

    private func setupUI() {
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = .mediumButton
        contentView.clipsToBounds = true
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.systemGray5.cgColor

        setupHierarchy()
        setupConstraints()
    }

    private func setupHierarchy() {
        contentView.addSubview(damagoView)
        contentView.addSubview(usingBadgeLabel)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            damagoView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: .spacingM),
            damagoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: .spacingM),
            damagoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -.spacingM),
            damagoView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -.spacingM),

            usingBadgeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: .spacingS),
            usingBadgeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -.spacingS),
            usingBadgeLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
}
