//
//  ProgressView.swift
//  Damago
//
//  Created by loyH on 1/18/26.
//

import UIKit

final class ProgressView: UIView {
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let blurEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let view = UIVisualEffectView(effect: blurEffect)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let progressContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.15
        view.layer.shadowOffset = CGSize(width: 0, height: 8)
        view.layer.shadowRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let iconContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .damagoPrimary.withAlphaComponent(0.1)
        view.layer.cornerRadius = 30
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .damagoPrimary
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .body1
        label.textColor = .textPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
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
        addSubview(containerView)
        containerView.addSubview(progressContainer)
        progressContainer.addSubview(iconContainerView)
        iconContainerView.addSubview(activityIndicator)
        progressContainer.addSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            blurEffectView.topAnchor.constraint(equalTo: topAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            progressContainer.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            progressContainer.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            progressContainer.widthAnchor.constraint(equalToConstant: 200),
            progressContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 160),
            
            iconContainerView.centerXAnchor.constraint(equalTo: progressContainer.centerXAnchor),
            iconContainerView.topAnchor.constraint(equalTo: progressContainer.topAnchor, constant: 32),
            iconContainerView.widthAnchor.constraint(equalToConstant: 60),
            iconContainerView.heightAnchor.constraint(equalToConstant: 60),
            
            activityIndicator.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            
            messageLabel.topAnchor.constraint(equalTo: iconContainerView.bottomAnchor, constant: 24),
            messageLabel.centerXAnchor.constraint(equalTo: progressContainer.centerXAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: progressContainer.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: progressContainer.trailingAnchor, constant: -20),
            messageLabel.bottomAnchor.constraint(lessThanOrEqualTo: progressContainer.bottomAnchor, constant: -32)
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
        progressContainer.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        activityIndicator.startAnimating()
        
        // Fade In & Scale 애니메이션
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut
        ) {
            self.alpha = 1
            self.progressContainer.transform = .identity
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
            self.progressContainer.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        } completion: { _ in
            self.activityIndicator.stopAnimating()
            self.removeFromSuperview()
            self.progressContainer.transform = .identity
        }
    }
}
