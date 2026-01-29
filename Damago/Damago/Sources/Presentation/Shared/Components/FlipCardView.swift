//
//  FlipCardView.swift
//  Damago
//
//  Created by 박현수 on 1/27/26.
//

import Combine
import UIKit

final class FlipCardView: UIView {
    private(set) var isFlipped: Bool = false
    var isFlippable: Bool = true
    private(set) var isAnimating: Bool = false

    private let flippedSubject = PassthroughSubject<Bool, Never>()
    var flippedPublisher: AnyPublisher<Bool, Never> {
        flippedSubject.eraseToAnyPublisher()
    }

    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        return view
    }()

    private let frontImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .damagoSecondary
        imageView.layer.cornerRadius = .mediumButton
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.systemGray5.cgColor
        return imageView
    }()

    private let backView: UIView = {
        let view = UIView()
        view.backgroundColor = .damagoPrimary
        view.layer.cornerRadius = .mediumButton
        view.clipsToBounds = true

        let logoImageView = UIImageView()
        logoImageView.image = UIImage(resource: .paw)
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoImageView)

        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
            logoImageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5)
        ])

        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        setupGesture()
        updateState(animated: false)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
        setupGesture()
        updateState(animated: false)
    }

    func configure(image: UIImage?) {
        frontImageView.image = image
    }

    func flip() {
        guard !isAnimating else { return }
        isFlipped.toggle()
        updateState(animated: true)
    }

    func setFlipped(_ flipped: Bool, animated: Bool = false) {
        isAnimating = false
        containerView.layer.removeAllAnimations()

        isFlipped = flipped
        updateState(animated: animated)
    }

    private func updateState(animated: Bool) {
        guard animated else {
            frontImageView.isHidden = !isFlipped
            backView.isHidden = isFlipped
            return
        }

        isAnimating = true
        var transform = CATransform3DIdentity
        transform.m34 = -1.0 / 300
        containerView.layer.transform = transform
        let duration = 0.4

        UIView.animate(
            withDuration: duration / 2,
            delay: 0,
            options: .curveEaseIn,
            animations: { [weak self] in
                guard let self else { return }
                var rotateTransform = transform
                rotateTransform = CATransform3DRotate(rotateTransform, .pi / 2, 0, 1, 0)
                containerView.layer.transform = rotateTransform
            },
            completion: { [weak self] _ in
                guard let self else { return }

                frontImageView.isHidden = !isFlipped
                backView.isHidden = isFlipped

                var rotateTransform = transform
                rotateTransform = CATransform3DRotate(rotateTransform, -.pi / 2, 0, 1, 0)
                containerView.layer.transform = rotateTransform

                UIView.animate(
                    withDuration: duration / 2,
                    delay: 0,
                    options: .curveEaseOut,
                    animations: { self.containerView.layer.transform = transform },
                    completion: { _ in
                        self.isAnimating = false
                        self.flippedSubject.send(self.isFlipped)
                    }
                )
            }
        )
    }

    private func setupLayout() {
        addSubview(containerView)
        containerView.addSubview(backView)
        containerView.addSubview(frontImageView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            backView.topAnchor.constraint(equalTo: containerView.topAnchor),
            backView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            backView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            backView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            frontImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            frontImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            frontImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            frontImageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }

    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
    }

    @objc
    private func handleTap() {
        guard isFlippable, !isAnimating else { return }
        flip()
    }
}

class TempVC: UIViewController {
    let flipCardView: FlipCardView = {
        let view = FlipCardView()
        view.configure(image: UIImage(systemName: "photo"))
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(flipCardView)
        NSLayoutConstraint.activate([
            flipCardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            flipCardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            flipCardView.widthAnchor.constraint(equalToConstant: 100),
            flipCardView.heightAnchor.constraint(equalToConstant: 160)
        ])
    }
}

#Preview {
    TempVC()
}
