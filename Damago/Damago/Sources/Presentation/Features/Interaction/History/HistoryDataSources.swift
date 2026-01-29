//
//  HistoryDataSources.swift
//  Damago
//
//  Created by 박현수 on 1/26/26.
//

import UIKit

nonisolated enum HistorySection: Hashable {
    case main
}

final class DailyQuestionHistoryDataSource: UICollectionViewDiffableDataSource<HistorySection, DailyQuestionHistory> {
    init(collectionView: UICollectionView) {
        let registration =
        UICollectionView.CellRegistration<DailyQuestionHistoryCell, DailyQuestionHistory> { cell, _, item in
            cell.configure(with: item)
        }
        
        super.init(collectionView: collectionView) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: item)
        }
    }
}

final class BalanceGameHistoryDataSource: UICollectionViewDiffableDataSource<HistorySection, BalanceGameHistory> {
    init(collectionView: UICollectionView) {
        let registration =
        UICollectionView.CellRegistration<BalanceGameHistoryCell, BalanceGameHistory> { cell, _, item in
            cell.configure(with: item)
        }
        
        super.init(collectionView: collectionView) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: item)
        }
    }
}
