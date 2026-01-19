//
//  ProgressView.swift
//  Damago
//
//  Created by loyH on 1/18/26.
//

import UIKit

// 패딩을 가진 커스텀 레이블
private final class PaddedLabel: UILabel {
    private let padding = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }
    
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + padding.left + padding.right,
            height: size.height + padding.top + padding.bottom
        )
    }
    
    override var bounds: CGRect {
        didSet {
            preferredMaxLayoutWidth = bounds.width - (padding.left + padding.right)
        }
    }
}

final class ProgressView: UIView {
    private let blurEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let view = UIVisualEffectView(effect: blurEffect)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let messageLabel: PaddedLabel = {
        let label = PaddedLabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        
        // 텍스트 그림자로 가독성 확보
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOpacity = 0.5
        label.layer.shadowOffset = CGSize(width: 0, height: 2)
        label.layer.shadowRadius = 6
        
        // 레이블 자체에 약간의 배경
        label.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        
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
    
    private func setupUI() {
        addSubview(blurEffectView)
        addSubview(contentStack)
        
        contentStack.addArrangedSubview(activityIndicator)
        contentStack.addArrangedSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            blurEffectView.topAnchor.constraint(equalTo: topAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            contentStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 40),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -40)
        ])
        
    }
    
    func show(in view: UIView, message: String = "전송 중...") {
        messageLabel.text = message
        translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(self)
        
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor),
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 초기 상태 설정 (애니메이션을 위해)
        alpha = 0
        contentStack.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        
        activityIndicator.startAnimating()
        
        // Fade In & Scale 애니메이션
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut
        ) {
            self.alpha = 1
            self.contentStack.transform = .identity
        }
    }
    
    func hide() {
        // Fade Out 애니메이션
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: .curveEaseIn
        ) {
            self.alpha = 0
            self.contentStack.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        } completion: { _ in
            self.activityIndicator.stopAnimating()
            self.removeFromSuperview()
            self.contentStack.transform = .identity
        }
    }
}
