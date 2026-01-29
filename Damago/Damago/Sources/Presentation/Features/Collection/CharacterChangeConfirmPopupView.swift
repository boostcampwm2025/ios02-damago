//
//  CharacterChangeConfirmPopupView.swift
//  Damago
//
//  Created by loyH on 1/28/26.
//

import UIKit
import Combine

final class CharacterChangeConfirmPopupView: UIView {
    let confirmButtonTappedSubject = PassthroughSubject<Void, Never>()
    let cancelButtonTappedSubject = PassthroughSubject<Void, Never>()

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .damagoSecondary
        view.layer.cornerRadius = .largeCard
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let petBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = .mediumButton
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.systemGray5.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let petView: PetView = {
        let view = PetView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "이 캐릭터로 변경할까요?"
        label.font = .body1
        label.textColor = .textPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = .spacingM
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let cancelButton: CTAButton = {
        let button = CTAButton()
        let config = CTAButton.Configuration(
            backgroundColor: .textTertiary,
            foregroundColor: .white,
            title: "취소",
            font: .body2
        )
        button.configure(enabled: config, disabled: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let confirmButton: CTAButton = {
        let button = CTAButton()
        let config = CTAButton.Configuration(
            backgroundColor: .damagoPrimary,
            foregroundColor: .white,
            title: "변경하기",
            font: .body2
        )
        button.configure(enabled: config, disabled: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var cancellables = Set<AnyCancellable>()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        bind()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with petType: DamagoType) {
        petView.configure(with: petType)
    }

    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        setupHierarchy()
        setupConstraints()
        setupBackgroundTapGesture()
    }
    
    private func setupBackgroundTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap(_:)))
        tapGesture.delegate = self
        addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleBackgroundTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        // containerView 밖을 터치했을 때만 팝업 닫기
        if !containerView.frame.contains(location) {
            cancelButtonTappedSubject.send(())
        }
    }

    private func bind() {
        confirmButton.tapPublisher
            .sink { [weak self] in
                self?.confirmButtonTappedSubject.send(())
            }
            .store(in: &cancellables)

        cancelButton.tapPublisher
            .sink { [weak self] in
                self?.cancelButtonTappedSubject.send(())
            }
            .store(in: &cancellables)
    }

    private func setupHierarchy() {
        addSubview(containerView)
        [petBackgroundView, titleLabel, buttonStackView].forEach {
            containerView.addSubview($0)
        }
        petBackgroundView.addSubview(petView)

        buttonStackView.addArrangedSubview(cancelButton)
        buttonStackView.addArrangedSubview(confirmButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 300),

            petBackgroundView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: .spacingL),
            petBackgroundView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            petBackgroundView.widthAnchor.constraint(equalToConstant: 150),
            petBackgroundView.heightAnchor.constraint(equalTo: petBackgroundView.widthAnchor),

            petView.topAnchor.constraint(equalTo: petBackgroundView.topAnchor, constant: .spacingS),
            petView.leadingAnchor.constraint(equalTo: petBackgroundView.leadingAnchor, constant: .spacingS),
            petView.trailingAnchor.constraint(equalTo: petBackgroundView.trailingAnchor, constant: -.spacingS),
            petView.bottomAnchor.constraint(equalTo: petBackgroundView.bottomAnchor, constant: -.spacingS),

            titleLabel.topAnchor.constraint(equalTo: petBackgroundView.bottomAnchor, constant: .spacingM),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: .spacingM),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -.spacingM),

            buttonStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: .spacingL),
            buttonStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: .spacingM),
            buttonStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -.spacingM),
            buttonStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -.spacingM),
            buttonStackView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
}

extension CharacterChangeConfirmPopupView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // containerView 내부를 터치했을 때는 제스처를 무시
        let location = touch.location(in: self)
        return !containerView.frame.contains(location)
    }
}

extension CharacterChangeConfirmPopupView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        
        // containerView 내부를 터치한 경우는 정상적으로 처리
        if containerView.frame.contains(point) {
            return hitView
        }
        
        // 배경(디밍) 영역을 터치한 경우는 이 뷰가 터치를 받아서 탭바 동작을 막음
        // (실제 팝업 닫기는 gestureRecognizer에서 처리)
        return self
    }
}
