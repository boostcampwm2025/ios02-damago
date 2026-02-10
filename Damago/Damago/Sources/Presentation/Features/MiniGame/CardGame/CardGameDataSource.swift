//
//  CardGameDataSource.swift
//  Damago
//
//  Created by 박현수 on 2026/01/28.
//

import UIKit

final class CardGameDataSource: UICollectionViewDiffableDataSource<CardGameSection, CardItem> {
    var imageProvider: ((Data) -> UIImage?)?

    init(collectionView: UICollectionView) {
        let registration = UICollectionView.CellRegistration<CardGameCell, CardItem> { cell, _, item in
            let dataSource = collectionView.dataSource as? CardGameDataSource
            let image = item.image.flatMap { dataSource?.imageProvider?($0) }
            cell.configure(with: item, image: image)
        }

        super.init(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            collectionView.dequeueConfiguredReusableCell(
                using: registration,
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
