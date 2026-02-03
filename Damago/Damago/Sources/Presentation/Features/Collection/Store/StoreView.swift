//
//  StoreView.swift
//  Damago
//
//  Created by 김재영 on 1/28/26.
//

import UIKit

final class StoreView: UIView {
    lazy var coinLabel: CapsuleLabel = {
        let label = CapsuleLabel(padding: .init(top: .spacingS, left: .spacingS, bottom: .spacingS, right: .spacingS))
        label.font = .body3
        label.textColor = .textPrimary
        label.backgroundColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let exitButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = .damagoPrimary
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    let machineImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "machine")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let drawButton: CTAButton = {
        let button = CTAButton()
        let config = CTAButton.Configuration(
            backgroundColor: .damagoPrimary,
            foregroundColor: .white,
            image: UIImage(systemName: "dollarsign.circle.fill"),
            title: "100 코인"
        )
        let disabledConfig = CTAButton.Configuration(
            backgroundColor: .textTertiary,
            foregroundColor: .white,
            image: UIImage(systemName: "dollarsign.circle")?.withTintColor(.white, renderingMode: .alwaysOriginal),
            title: "100 코인"
        )
        
        button.configure(enabled: config, disabled: disabledConfig)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 4
        return button
    }()
    
    let resultView: StoreResultView = {
        let view = StoreResultView()
        view.alpha = 0
        view.translatesAutoresizingMaskIntoConstraints = false
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
    
    func configure(coins: Int) {
        let completeText = NSMutableAttributedString()
        completeText.append(
            .iconWithText(
                systemName: "dollarsign.circle.fill",
                text: " \(coins)",
                iconColor: .systemYellow,
                font: .body3
            )
        )
        self.coinLabel.attributedText = completeText
    }

    private func setupUI() {
        backgroundColor = .background
        setupHierarchy()
        setupConstraints()
    }
    
    private func setupHierarchy() {
        addSubview(machineImageView)
        addSubview(coinLabel)
        addSubview(exitButton)
        addSubview(drawButton)
        addSubview(resultView)
    }
    
    private func setupConstraints() {
        let machineCenterYConstraint = NSLayoutConstraint(
            item: machineImageView,
            attribute: .centerY,
            relatedBy: .equal,
            toItem: self,
            attribute: .bottom,
            multiplier: 0.35,
            constant: 0
        )
        
        NSLayoutConstraint.activate([
            coinLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            coinLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingM),
            
            exitButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            exitButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingM),
            exitButton.widthAnchor.constraint(equalToConstant: 44),
            exitButton.heightAnchor.constraint(equalToConstant: 44),
            
            machineImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            machineCenterYConstraint,
            machineImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.7),
            machineImageView.heightAnchor.constraint(equalTo: machineImageView.widthAnchor, multiplier: 1.2),
            
            drawButton.topAnchor.constraint(equalTo: machineImageView.bottomAnchor, constant: .spacingXL),
            drawButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            drawButton.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.7),
            
            resultView.topAnchor.constraint(equalTo: topAnchor),
            resultView.leadingAnchor.constraint(equalTo: leadingAnchor),
            resultView.trailingAnchor.constraint(equalTo: trailingAnchor),
            resultView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
