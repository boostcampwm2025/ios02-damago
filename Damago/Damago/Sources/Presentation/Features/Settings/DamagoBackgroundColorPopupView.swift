//
//  DamagoBackgroundColorPopupView.swift
//  Damago
//
//  Created by loyH on 2/3/26.
//

import UIKit
import Combine

final class DamagoBackgroundColorPopupView: UIView {
    let confirmButtonTappedSubject = PassthroughSubject<DamagoBackgroundColorOption, Never>()
    let cancelButtonTappedSubject = PassthroughSubject<Void, Never>()

    private var selectedOption: DamagoBackgroundColorOption
    private var optionViews: [ColorOptionView] = []

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .damagoSecondary
        view.layer.cornerRadius = .largeCard
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "배경색 변경"
        label.font = .body1
        label.textColor = .textPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let colorStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = .spacingXL
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
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
            title: "확인",
            font: .body2
        )
        button.configure(enabled: config, disabled: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var cancellables = Set<AnyCancellable>()

    init(initialOption: DamagoBackgroundColorOption) {
        self.selectedOption = initialOption
        super.init(frame: .zero)
        setupUI()
        bind()
        updateSelection(to: initialOption)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        setupHierarchy()
        setupConstraints()
        setupBackgroundTapGesture()
    }

    private func setupHierarchy() {
        addSubview(containerView)
        [titleLabel, colorStackView, buttonStackView].forEach {
            containerView.addSubview($0)
        }
        buttonStackView.addArrangedSubview(cancelButton)
        buttonStackView.addArrangedSubview(confirmButton)

        let selectableOptions: [DamagoBackgroundColorOption] = [.black, .white]
        selectableOptions.forEach { option in
            let optionView = ColorOptionView(option: option)
            optionView.button.addTarget(self, action: #selector(colorButtonTapped(_:)), for: .touchUpInside)
            optionViews.append(optionView)
            colorStackView.addArrangedSubview(optionView)
        }
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 320),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: .spacingL),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: .spacingM),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -.spacingM),

            colorStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: .spacingM),
            colorStackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            colorStackView.widthAnchor.constraint(lessThanOrEqualToConstant: 172),

            buttonStackView.topAnchor.constraint(equalTo: colorStackView.bottomAnchor, constant: .spacingL),
            buttonStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: .spacingM),
            buttonStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -.spacingM),
            buttonStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -.spacingM),
            buttonStackView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func bind() {
        confirmButton.tapPublisher
            .sink { [weak self] in
                guard let self else { return }
                confirmButtonTappedSubject.send(self.selectedOption)
            }
            .store(in: &cancellables)

        cancelButton.tapPublisher
            .sink { [weak self] in
                self?.cancelButtonTappedSubject.send(())
            }
            .store(in: &cancellables)
    }

    @objc
    private func colorButtonTapped(_ sender: UIButton) {
        guard let option = optionViews.first(where: { $0.button === sender })?.option else { return }
        updateSelection(to: option)
    }

    private func updateSelection(to option: DamagoBackgroundColorOption) {
        selectedOption = option
        optionViews.forEach { view in
            view.badge.isHidden = (view.option != selectedOption)
        }
    }

    private func setupBackgroundTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap(_:)))
        tapGesture.delegate = self
        addGestureRecognizer(tapGesture)
    }

    @objc
    private func handleBackgroundTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        if !containerView.frame.contains(location) {
            cancelButtonTappedSubject.send(())
        }
    }
}

extension DamagoBackgroundColorPopupView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let location = touch.location(in: self)
        return !containerView.frame.contains(location)
    }
}

extension DamagoBackgroundColorPopupView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if containerView.frame.contains(point) {
            return hitView
        }
        return self
    }
}
