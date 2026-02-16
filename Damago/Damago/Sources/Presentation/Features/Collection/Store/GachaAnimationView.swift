//
//  GachaAnimationView.swift
//  Damago
//
//  Created by 김재영 on 1/29/26.
//

import UIKit
import os

final class GachaAnimationView: UIView {
    private static let signposter = OSSignposter(subsystem: "com.damago.app", category: "GachaAnimationUIKit")

    private enum Constants {
        enum Animation {
            static let shakeDuration: TimeInterval = 0.1
            static let shakeRepeatCount: Float = 20
            static let shakeOffset: CGFloat = 8
            
            static let ejectDuration: TimeInterval = 0.8
            static let ejectTranslationY: CGFloat = -150
            static let ejectScale: CGFloat = 3.0
            
            static let wobbleDuration: TimeInterval = 0.2
            static let wobbleRepeatCount: Float = 3
            static let wobbleAngle: Double = 15 * .pi / 180
            
            static let revealDuration: TimeInterval = 0.5
        }
        
        enum Keys {
            static let shakeX = "transform.translation.x"
            static let ejectY = "transform.translation.y"
            static let scale = "transform.scale"
            static let rotationZ = "transform.rotation.z"
            static let opacity = "opacity"
            
            static let shakeAnim = "shake"
            static let ejectAnim = "eject"
            static let wobbleAnim = "wobble"
            static let fadeInAnim = "fadeIn"
        }
    }

    private let machineImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "machine")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let capsuleImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "capsule")
        imageView.contentMode = .scaleAspectFit
        imageView.alpha = 0
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let flashView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.alpha = 0
        view.isUserInteractionEnabled = false
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var skipButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = ">> SKIP"
        config.baseForegroundColor = .damagoPrimary
        config.baseBackgroundColor = .black.withAlphaComponent(0.5)
        config.contentInsets = NSDirectionalEdgeInsets(
            top: .spacingS,
            leading: .spacingM,
            bottom: .spacingS,
            trailing: .spacingM
        )
        
        button.configuration = config
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleSkip), for: .touchUpInside)
        return button
    }()
    
    var onFinish: (() -> Void)?
    private var isFinished = false
    private var isSkipped = false
    private var _totalAnimationState: OSSignpostIntervalState?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        setupHierarchy()
        setupConstraints()
    }
    
    private func setupHierarchy() {
        [machineImageView, capsuleImageView, flashView, skipButton].forEach { addSubview($0) }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate(
            [
                machineImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
                machineImageView.centerYAnchor.constraint(
                    equalTo: centerYAnchor,
                    constant: -UIScreen.main.bounds.height * 0.15
                ),
                machineImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.7),
                machineImageView.heightAnchor.constraint(equalTo: machineImageView.widthAnchor, multiplier: 1.2),
                
                capsuleImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
                capsuleImageView.bottomAnchor.constraint(equalTo: machineImageView.bottomAnchor, constant: -20),
                capsuleImageView.widthAnchor.constraint(equalToConstant: 40),
                capsuleImageView.heightAnchor.constraint(equalToConstant: 40),
                
                flashView.topAnchor.constraint(equalTo: topAnchor),
                flashView.leadingAnchor.constraint(equalTo: leadingAnchor),
                flashView.trailingAnchor.constraint(equalTo: trailingAnchor),
                flashView.bottomAnchor.constraint(equalTo: bottomAnchor),
                
                skipButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
                skipButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -60)
            ]
        )
    }
    
    func startAnimation() {
        let state = Self.signposter.beginInterval("TotalAnimation")
        _totalAnimationState = state
        playShakeAnimation()
    }

    private func playShakeAnimation() {
        let state = Self.signposter.beginInterval("ShakeMachine")
        
        let animation = CAKeyframeAnimation(keyPath: Constants.Keys.shakeX)
        animation.values = [
            0,
            -Constants.Animation.shakeOffset,
            Constants.Animation.shakeOffset,
            -Constants.Animation.shakeOffset,
            Constants.Animation.shakeOffset,
            0
        ]
        animation.keyTimes = [0, 0.2, 0.4, 0.6, 0.8, 1]
        animation.duration = Constants.Animation.shakeDuration
        animation.repeatCount = Constants.Animation.shakeRepeatCount
        animation.isRemovedOnCompletion = true
        
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            Self.signposter.endInterval("ShakeMachine", state)
            guard let self, !self.isFinished else { return }
            self.playEjectAnimation()
        }
        machineImageView.layer.add(animation, forKey: Constants.Keys.shakeAnim)
        CATransaction.commit()
    }
    
    private func playEjectAnimation() {
        let state = Self.signposter.beginInterval("EjectCapsule")
        capsuleImageView.alpha = 1
        
        let springAnimation = CASpringAnimation(keyPath: Constants.Keys.ejectY)
        springAnimation.fromValue = 0
        springAnimation.toValue = Constants.Animation.ejectTranslationY
        springAnimation.damping = 7
        springAnimation.stiffness = 100
        springAnimation.mass = 1
        springAnimation.initialVelocity = 0
        springAnimation.duration = springAnimation.settlingDuration
        
        let scaleAnimation = CABasicAnimation(keyPath: Constants.Keys.scale)
        scaleAnimation.fromValue = 0.5
        scaleAnimation.toValue = Constants.Animation.ejectScale
        scaleAnimation.duration = Constants.Animation.ejectDuration
        
        let group = CAAnimationGroup()
        group.animations = [springAnimation, scaleAnimation]
        group.duration = Constants.Animation.ejectDuration
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false
        
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            Self.signposter.endInterval("EjectCapsule", state)
            guard let self, !self.isFinished else { return }
            self.playWobbleAnimation()
        }
        capsuleImageView.layer.add(group, forKey: Constants.Keys.ejectAnim)
        CATransaction.commit()
    }
    
    private func playWobbleAnimation() {
        let state = Self.signposter.beginInterval("WobbleCapsule")
        let animation = CAKeyframeAnimation(keyPath: Constants.Keys.rotationZ)
        animation.values = [0, -Constants.Animation.wobbleAngle, Constants.Animation.wobbleAngle, 0]
        animation.keyTimes = [0, 0.33, 0.66, 1]
        animation.duration = Constants.Animation.wobbleDuration
        animation.repeatCount = Constants.Animation.wobbleRepeatCount
        
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            Self.signposter.endInterval("WobbleCapsule", state)
            guard let self, !self.isFinished else { return }
            self.playRevealAnimation()
        }
        capsuleImageView.layer.add(animation, forKey: "wobbleAnim")
        CATransaction.commit()
    }
    
    private func playRevealAnimation() {
        guard !isSkipped else { return }
        let state = Self.signposter.beginInterval("RevealResult")

        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            Self.signposter.endInterval("RevealResult", state)
            self?.finish()
        }
        
        let fadeIn = CABasicAnimation(keyPath: Constants.Keys.opacity)
        fadeIn.fromValue = 0
        fadeIn.toValue = 1
        fadeIn.duration = Constants.Animation.revealDuration
        fadeIn.fillMode = .forwards
        fadeIn.isRemovedOnCompletion = false
        
        flashView.layer.add(fadeIn, forKey: Constants.Keys.fadeInAnim)
        CATransaction.commit()
    }
    
    @objc
    private func handleSkip() {
        isSkipped = true
        machineImageView.layer.removeAllAnimations()
        capsuleImageView.layer.removeAllAnimations()
        flashView.layer.removeAllAnimations()
        finish()
    }
    
    private func finish() {
        guard !isFinished else { return }
        isFinished = true
        if let state = _totalAnimationState {
            Self.signposter.endInterval("TotalAnimation", state)
            _totalAnimationState = nil
        }
        onFinish?()
    }
}
