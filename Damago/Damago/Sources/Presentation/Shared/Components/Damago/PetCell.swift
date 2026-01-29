//
//  PetCell.swift
//  Damago
//
//  Created by 김재영 on 1/26/26.
//

import UIKit

final class PetCell: UICollectionViewCell {
    private let petView: PetView = {
        let view = PetView()
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

    func configure(with petType: DamagoType, isCurrentPet: Bool = false) {
        petView.configure(with: petType)
        usingBadgeLabel.isHidden = !isCurrentPet
        contentView.layer.borderColor = (isCurrentPet ? UIColor.damagoPrimary : .systemGray5).cgColor
        contentView.layer.borderWidth = isCurrentPet ? 2 : 1
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
        contentView.addSubview(petView)
        contentView.addSubview(usingBadgeLabel)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            petView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: .spacingM),
            petView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: .spacingM),
            petView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -.spacingM),
            petView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -.spacingM),

            usingBadgeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: .spacingS),
            usingBadgeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -.spacingS),
            usingBadgeLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
}
