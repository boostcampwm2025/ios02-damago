//
//  BalanceGameHistoryView.swift
//  Damago
//
//  Created by 박현수 on 1/26/26.
//

import UIKit

final class BalanceGameHistoryView: UIView {
    private let matchRateContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let matchRateLabel: UILabel = {
        let label = UILabel()
        label.font = .title3
        label.textColor = .damagoPrimary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let collectionView: UICollectionView = {
        let layout = BalanceGameHistoryView.createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .background
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
    
    func updateMatchRate(_ rate: Int) {
        matchRateLabel.text = "평균 \(rate)% 일치했어요!"
    }
    
    private func setupUI() {
        addSubview(matchRateContainer)
        matchRateContainer.addSubview(matchRateLabel)
        addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            matchRateContainer.topAnchor.constraint(equalTo: topAnchor),
            matchRateContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            matchRateContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            matchRateContainer.heightAnchor.constraint(equalToConstant: 60),
            
            matchRateLabel.centerXAnchor.constraint(equalTo: matchRateContainer.centerXAnchor),
            matchRateLabel.centerYAnchor.constraint(equalTo: matchRateContainer.centerYAnchor),
            
            collectionView.topAnchor.constraint(equalTo: matchRateContainer.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private static func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(150)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(150)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = .spacingM
        section.contentInsets = NSDirectionalEdgeInsets(
            top: .spacingM,
            leading: .spacingM,
            bottom: .spacingM,
            trailing: .spacingM
        )
        
        return UICollectionViewCompositionalLayout(section: section)
    }
}
