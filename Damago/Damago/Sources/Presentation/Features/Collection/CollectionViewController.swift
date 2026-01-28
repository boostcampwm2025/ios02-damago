//
//  CollectionViewController.swift
//  Damago
//
//  Created by loyH on 1/27/26.
//

import UIKit
import Combine

final class CollectionViewController: UIViewController {
    private let mainView = CollectionView()
    private let viewModel: CollectionViewModel

    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let petSelectedPublisher = PassthroughSubject<DamagoType, Never>()
    private let confirmChangeTappedPublisher = PassthroughSubject<Void, Never>()

    private var cancellables = Set<AnyCancellable>()
    private var currentPetType: DamagoType?

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
        bind()
        viewDidLoadPublisher.send()
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

    private func bind() {
        let input = CollectionViewModel.Input(
            viewDidLoad: viewDidLoadPublisher.eraseToAnyPublisher(),
            petSelected: petSelectedPublisher.eraseToAnyPublisher(),
            confirmChangeTapped: confirmChangeTappedPublisher.eraseToAnyPublisher()
        )

        let output = viewModel.transform(input)

        output
            .pulse(\.route)
            .sink { [weak self] route in
                self?.handleRoute(route)
            }
            .store(in: &cancellables)

        output
            .map(\.currentPetType)
            .removeDuplicates { $0?.rawValue == $1?.rawValue }
            .sink { [weak self] ct in
                self?.currentPetType = ct
                self?.mainView.collectionView.reloadData()
            }
            .store(in: &cancellables)
    }

    private func handleRoute(_ route: CollectionViewModel.Route) {
        switch route {
        case .showChangeConfirmPopup(let petType):
            showChangeConfirmPopup(for: petType)
        case .changeSuccess:
            LiveActivityManager.shared.synchronizeActivity()
        case .error(let title, let message):
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
        }
    }

    private func showChangeConfirmPopup(for petType: DamagoType) {
        let popupView = CharacterChangeConfirmPopupView()
        popupView.configure(with: petType)
        popupView.translatesAutoresizingMaskIntoConstraints = false

        guard let targetView = navigationController?.view ?? view else { return }
        targetView.addSubview(popupView)

        NSLayoutConstraint.activate([
            popupView.topAnchor.constraint(equalTo: targetView.topAnchor),
            popupView.leadingAnchor.constraint(equalTo: targetView.leadingAnchor),
            popupView.trailingAnchor.constraint(equalTo: targetView.trailingAnchor),
            popupView.bottomAnchor.constraint(equalTo: targetView.bottomAnchor)
        ])

        popupView.confirmButtonTappedSubject
            .sink { [weak self, weak popupView] in
                self?.confirmChangeTappedPublisher.send(())
                popupView?.removeFromSuperview()
            }
            .store(in: &cancellables)

        popupView.cancelButtonTappedSubject
            .sink { [weak popupView] in
                popupView?.removeFromSuperview()
            }
            .store(in: &cancellables)

        popupView.alpha = 0
        UIView.animate(withDuration: 0.2) {
            popupView.alpha = 1
        }
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
        cell.configure(with: petType, isCurrentPet: currentPetType == petType)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let petType = viewModel.pets[indexPath.item]
        if petType == currentPetType { return }
        petSelectedPublisher.send(petType)
    }
}
