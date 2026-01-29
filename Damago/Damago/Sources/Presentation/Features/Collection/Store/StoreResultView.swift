//
//  StoreResultView.swift
//  Damago
//
//  Created by 김재영 on 1/28/26.
//

import UIKit

final class StoreResultView: UIView {
    let petView: PetView = {
        let view = PetView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .title2
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let infoLabel: UILabel = {
        let label = UILabel()
        label.text = "화면을 터치해서 닫기"
        label.font = .body3
        label.textColor = .white.withAlphaComponent(0.7)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    func configure(with result: StoreViewModel.DrawResult) {
        petView.configure(with: result.petType)
        nameLabel.text = result.itemName
        startBlinkingInfoLabel()
    }
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.7)
        setupHierarchy()
        setupConstraints()
    }
    
    private func setupHierarchy() {
        addSubview(petView)
        addSubview(nameLabel)
        addSubview(infoLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            petView.centerXAnchor.constraint(equalTo: centerXAnchor),
            petView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -60),
            petView.widthAnchor.constraint(equalToConstant: 200),
            petView.heightAnchor.constraint(equalToConstant: 200),
            
            nameLabel.topAnchor.constraint(equalTo: petView.bottomAnchor, constant: .spacingL),
            nameLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            infoLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: .spacingL),
            infoLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }
    
    private func startBlinkingInfoLabel() {
        infoLabel.alpha = 1.0
        UIView.animate(
            withDuration: 1.0,
            delay: 0.0,
            options: [.autoreverse, .repeat, .allowUserInteraction],
            animations: {
                self.infoLabel.alpha = 0.3
            },
            completion: nil)
    }
}
