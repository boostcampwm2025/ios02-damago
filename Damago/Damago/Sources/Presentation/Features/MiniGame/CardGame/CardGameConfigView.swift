//
//  CardGameConfigView.swift
//  Damago
//
//  Created by 박현수 on 1/29/26.
//

import Combine
import UIKit

final class CardGameConfigView: UIView {
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = .spacingL
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: .spacingM, left: .spacingM, bottom: .spacingXL, right: .spacingM)
        return stackView
    }()
    
    private let difficultyTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "난이도 선택"
        label.font = .title3
        label.textColor = .textPrimary
        return label
    }()
    
    let difficultySegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Easy (4장)", "Hard (8장)"])
        control.selectedSegmentIndex = 0
        control.selectedSegmentTintColor = .damagoPrimary
        control.setTitleTextAttributes([.foregroundColor: UIColor.textPrimary], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        return control
    }()
    
    private let difficultyStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = .spacingS
        return stackView
    }()

    private let photoSelectionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "사진 선택"
        label.font = .title3
        label.textColor = .textPrimary
        return label
    }()

    let instructionLabel: UILabel = {
        let label = UILabel()
        label.textColor = .red
        label.font = .caption
        return label
    }()

    let photoCountLabel: UILabel = {
        let label = UILabel()
        label.font = .body1
        label.textColor = .damagoPrimary
        label.textAlignment = .right
        return label
    }()
    
    let selectPhotoButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "사진 보관함에서 선택하기"
        
        var titleAttr = AttributeContainer()
        titleAttr.font = .body2
        config.attributedTitle = AttributedString("사진 보관함에서 선택하기", attributes: titleAttr)
        
        config.image = UIImage(systemName: "photo.on.rectangle")
        config.imagePadding = 8
        config.baseBackgroundColor = .damagoPrimary
        config.baseForegroundColor = .white
        config.cornerStyle = .medium

        let button = UIButton(configuration: config)
        return button
    }()
    
    private lazy var buttonAndCountStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [selectPhotoButton, photoCountLabel])
        stackView.axis = .horizontal
        stackView.spacing = .spacingM
        stackView.alignment = .center
        return stackView
    }()
    
    private let imagesScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        return scrollView
    }()
    
    let imagesStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = .spacingS
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let photoSectionStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = .spacingM
        return stackView
    }()
    
    let startButton: CTAButton = {
        let enabledConfig = CTAButton.Configuration(
            backgroundColor: .damagoPrimary,
            foregroundColor: .white,
            title: "게임 시작"
        )
        let disabledConfig = CTAButton.Configuration(
            backgroundColor: .disabled,
            foregroundColor: .white,
            title: "게임 시작",
            subtitle: "사진을 골라주세요!"
        )

        let button = CTAButton()
        button.configure(enabled: enabledConfig, disabled: disabledConfig)
        button.isEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let removeImageSubject = PassthroughSubject<Int, Never>()
    var removeImagePublisher: AnyPublisher<Int, Never> {
        removeImageSubject.eraseToAnyPublisher()
    }
    
    private var imageCancellables = Set<AnyCancellable>()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .background
        
        setupHierarchy()
        setupConstraints()
    }
    
    private func setupHierarchy() {
        addSubview(scrollView)
        addSubview(startButton)
        scrollView.addSubview(contentStackView)
        
        difficultyStackView.addArrangedSubview(difficultyTitleLabel)
        difficultyStackView.addArrangedSubview(difficultySegmentedControl)
        
        photoSectionStackView.addArrangedSubview(photoSelectionTitleLabel)
        photoSectionStackView.addArrangedSubview(buttonAndCountStack)

        imagesScrollView.addSubview(imagesStackView)

        photoSectionStackView.addArrangedSubview(imagesScrollView)
        photoSectionStackView.addArrangedSubview(instructionLabel)

        contentStackView.addArrangedSubview(difficultyStackView)
        contentStackView.addArrangedSubview(photoSectionStackView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            startButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingM),
            startButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingM),
            startButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -.spacingXL),
            startButton.heightAnchor.constraint(equalToConstant: 56),
            
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: startButton.topAnchor, constant: -.spacingM),
            
            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            imagesStackView.topAnchor.constraint(equalTo: imagesScrollView.contentLayoutGuide.topAnchor),
            imagesStackView.leadingAnchor.constraint(equalTo: imagesScrollView.contentLayoutGuide.leadingAnchor),
            imagesStackView.trailingAnchor.constraint(equalTo: imagesScrollView.contentLayoutGuide.trailingAnchor),
            imagesStackView.bottomAnchor.constraint(equalTo: imagesScrollView.contentLayoutGuide.bottomAnchor),
            imagesStackView.heightAnchor.constraint(equalTo: imagesScrollView.heightAnchor)
        ])
    }
    
    func updateSelectedImages(_ images: [UIImage]) {
        imageCancellables.removeAll()
        imagesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (index, image) in images.enumerated() {
            let removableImageView = RemovableImageView(image: image)
            removableImageView.removeTapPublisher
                .sink { [weak self] in
                    self?.removeImageSubject.send(index)
                }
                .store(in: &imageCancellables)
            
            imagesStackView.addArrangedSubview(removableImageView)
        }
    }
}
