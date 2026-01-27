//
//  CollectionView.swift
//  Damago
//
//  Created by loyH on 1/27/26.
//

import UIKit

final class CollectionView: UIView {
    let collectionView: UICollectionView = {
        let layout = CollectionView.createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .background
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.register(PetCell.self, forCellWithReuseIdentifier: PetCell.reuseIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func createLayout() -> UICollectionViewLayout {
        let itemInsets = NSDirectionalEdgeInsets(top: .spacingS, leading: .spacingS, bottom: .spacingS, trailing: .spacingS)
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0 / 3),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = itemInsets

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalWidth(1.0 / 3)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: .spacingM,
            leading: .spacingM,
            bottom: .spacingXL,
            trailing: .spacingM
        )

        return UICollectionViewCompositionalLayout(section: section)
    }

    private func setupUI() {
        backgroundColor = .background
        addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}
