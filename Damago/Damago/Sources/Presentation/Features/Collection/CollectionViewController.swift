//
//  CollectionViewController.swift
//  Damago
//
//  Created by loyH on 1/27/26.
//

import UIKit

final class CollectionViewController: UIViewController {
    private let mainView = CollectionView()
    private let viewModel: CollectionViewModel

    init(viewModel: CollectionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = mainView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupCollectionView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setupNavigation() {
        navigationItem.title = viewModel.title
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationBar.tintColor = .damagoPrimary
        navigationItem.backButtonDisplayMode = .minimal

        let shopButton = UIBarButtonItem(
            image: UIImage(systemName: "cart"),
            style: .plain,
            target: self,
            action: #selector(shopButtonTapped)
        )
        navigationItem.rightBarButtonItem = shopButton
    }

    private func setupCollectionView() {
        mainView.collectionView.dataSource = self
        mainView.collectionView.delegate = self
    }

    @objc private func shopButtonTapped() {
        // TODO: 상점 화면 연결
    }
}

extension CollectionViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.pets.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PetCell.reuseIdentifier,
            for: indexPath
        ) as? PetCell else {
            return UICollectionViewCell()
        }
        let petType = viewModel.pets[indexPath.item]
        cell.configure(with: petType)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let petType = viewModel.pets[indexPath.item]
        if petType.isAvailable {
            // TODO: 펫 상세 또는 선택 액션
        } else {
            let alert = UIAlertController(
                title: "🙌 추후 업데이트 예정입니다!",
                message: "더 좋은 서비스로 찾아뵙겠습니다.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
        }
    }
}
