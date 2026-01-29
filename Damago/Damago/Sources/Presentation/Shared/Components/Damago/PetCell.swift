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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with petType: DamagoType) {
        petView.configure(with: petType)
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
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            petView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: .spacingM),
            petView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: .spacingM),
            petView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -.spacingM),
            petView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -.spacingM)
        ])
    }
}
