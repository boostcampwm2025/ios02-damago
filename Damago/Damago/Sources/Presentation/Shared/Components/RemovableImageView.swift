//
//  RemovableImageView.swift
//  Damago
//
//  Created by 박현수 on 1/29/26.
//

import Combine
import UIKit

final class RemovableImageView: UIView {
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = .mediumButton
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let removeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .damagoPrimary
        button.layer.cornerRadius = .mediumButton
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    var removeTapPublisher: AnyPublisher<Void, Never> {
        removeButton.tapPublisher
    }
    
    init(image: UIImage) {
        super.init(frame: .zero)
        imageView.image = image
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: 80).isActive = true
        heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        addSubview(imageView)
        addSubview(removeButton)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            removeButton.topAnchor.constraint(equalTo: topAnchor, constant: .spacingXS),
            removeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingXS),
            removeButton.widthAnchor.constraint(equalToConstant: 24),
            removeButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
}
