//
//  CardGameCell.swift
//  Damago
//
//  Created by 박현수 on 2026/01/28.
//

import UIKit

final class CardGameCell: UICollectionViewCell {
    private let flipCardView = FlipCardView()

    private let overlayImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        overlayImageView.isHidden = true
        overlayImageView.image = nil
    }

    func configure(with item: CardItem, image: UIImage?) {
        flipCardView.configure(image: image)

        if flipCardView.isFlipped != item.isFlipped { flipCardView.setFlipped(item.isFlipped, animated: true) }

        flipCardView.isFlippable = false

        switch item.matchingState {
        case .match:
            overlayImageView.image = UIImage(systemName: "circle")?
                                        .withTintColor(.green, renderingMode: .alwaysOriginal)
            overlayImageView.isHidden = false
        case .mismatch:
            overlayImageView.image = UIImage(systemName: "xmark")?
                                        .withTintColor(.red, renderingMode: .alwaysOriginal)
            overlayImageView.isHidden = false
        case .none:
            overlayImageView.isHidden = true
        }
    }

    private func setupLayout() {
        contentView.addSubview(flipCardView)
        contentView.addSubview(overlayImageView)

        flipCardView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            flipCardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            flipCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            flipCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            flipCardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            overlayImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            overlayImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            overlayImageView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.8),
            overlayImageView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.8)
        ])

        flipCardView.isUserInteractionEnabled = false
    }
}
