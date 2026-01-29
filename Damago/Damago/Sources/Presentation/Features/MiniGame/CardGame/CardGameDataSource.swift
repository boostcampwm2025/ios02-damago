//
//  CardGameDataSource.swift
//  Damago
//
//  Created by 박현수 on 2026/01/28.
//

import UIKit

final class CardGameDataSource: UICollectionViewDiffableDataSource<CardGameSection, CardItem> {
    init(collectionView: UICollectionView) {
        let cellRegistration = UICollectionView.CellRegistration<CardGameCell, CardItem> { cell, _, item in
            cell.configure(with: item)
        }

        super.init(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: itemIdentifier
            )
        }
    }

    func update(with items: [CardItem], animating: Bool = false) {
        var snapshot = NSDiffableDataSourceSnapshot<CardGameSection, CardItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)
        self.apply(snapshot, animatingDifferences: animating)
    }
}
