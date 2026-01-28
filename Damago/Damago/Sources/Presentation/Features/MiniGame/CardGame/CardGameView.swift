//
//  CardGameView.swift
//  Damago
//
//  Created by 박현수 on 2026/01/28.
//

import UIKit

final class CardGameView: UIView {
    let timerProgressView: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .default)
        view.progressTintColor = .damagoPrimary
        view.trackTintColor = .textTertiary
        view.layer.cornerRadius = .smallElement
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let coinIconImageView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(systemName: "dollarsign.circle")
        view.tintColor = .systemYellow
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let coinLabel: UILabel = {
        let label = UILabel()
        label.font = .body1
        label.textColor = .label
        label.text = "0"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout() // 플레이스홀더. difficulty에 따라 적절한 레이아웃으로 변경됨
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.isScrollEnabled = false
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let countdownLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 100, weight: .black)
        label.textColor = .damagoPrimary
        label.textAlignment = .center
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .background

        addSubview(timerProgressView)
        addSubview(coinIconImageView)
        addSubview(coinLabel)
        addSubview(collectionView)
        addSubview(countdownLabel)
        
        NSLayoutConstraint.activate([
            // Timer
            timerProgressView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingM),
            timerProgressView.centerYAnchor.constraint(equalTo: coinIconImageView.centerYAnchor),
            timerProgressView.widthAnchor.constraint(equalToConstant: 120),
            
            // Coin
            coinLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingM),
            coinLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: .spacingM),
            
            coinIconImageView.trailingAnchor.constraint(equalTo: coinLabel.leadingAnchor, constant: -.spacingS),
            coinIconImageView.centerYAnchor.constraint(equalTo: coinLabel.centerYAnchor),
            coinIconImageView.widthAnchor.constraint(equalToConstant: 24),
            coinIconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            // CollectionView
            collectionView.topAnchor.constraint(equalTo: coinLabel.bottomAnchor, constant: .spacingL),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingM),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingM),
            collectionView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -.spacingM),
            
            // Countdown Label
            countdownLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            countdownLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    static func createLayout(difficulty: CardGameDifficulty) -> UICollectionViewLayout {
        let rows = CGFloat(difficulty.rows)
        let columns = CGFloat(difficulty.columns)

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0 / columns),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(
            top: .spacingXS,
            leading: .spacingXS,
            bottom: .spacingXS,
            trailing: .spacingXS
        )

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0 / rows)
        )

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            repeatingSubitem: item,
            count: difficulty.columns
        )

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

        return UICollectionViewCompositionalLayout(section: section)
    }

    func updateCoin(_ coin: Int) {
        coinLabel.text = "\(coin)"
    }
    
    func updateTimer(_ progress: Float) {
        timerProgressView.setProgress(progress, animated: true)
    }
    
    func animateCountdown(_ count: Int?) {
        guard let count = count else {
            countdownLabel.alpha = 0
            return
        }
        
        countdownLabel.text = "\(count)"
        countdownLabel.alpha = 1
        countdownLabel.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut,
            animations: {
                self.countdownLabel.transform = .identity
            },
            completion: { _ in
                UIView.animate(withDuration: 0.2, delay: 0.3, options: .curveEaseIn) {
                    self.countdownLabel.alpha = 0
                    self.countdownLabel.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                }
            }
        )
    }
}
