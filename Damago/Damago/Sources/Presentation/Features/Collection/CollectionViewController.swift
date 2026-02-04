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
    private let damagoSelectedPublisher = PassthroughSubject<DamagoType, Never>()
    private let confirmChangeTappedPublisher = PassthroughSubject<Void, Never>()

    private var cancellables = Set<AnyCancellable>()
    private var currentDamagoType: DamagoType?
    private var ownedDamagos: [DamagoType: Int] = [:]

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
            damagoSelected: damagoSelectedPublisher.eraseToAnyPublisher(),
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
            .map(\.currentDamagoType)
            .removeDuplicates { $0?.rawValue == $1?.rawValue }
            .sink { [weak self] ct in
                self?.currentDamagoType = ct
                self?.mainView.collectionView.reloadData()
            }
            .store(in: &cancellables)

        output
            .map(\.ownedDamagos)
            .sink { [weak self] in
                self?.ownedDamagos = $0
                self?.mainView.collectionView.reloadData()
            }
            .store(in: &cancellables)
    }

    private func handleRoute(_ route: CollectionViewModel.Route) {
        switch route {
        case .showChangeConfirmPopup(let damagoType):
            showChangeConfirmPopup(for: damagoType)
        case .error(let title, let message):
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
        }
    }

    private func showChangeConfirmPopup(for damagoType: DamagoType) {
        let popupView = DamagoChangeConfirmPopupView()
        popupView.configure(with: damagoType)
        popupView.translatesAutoresizingMaskIntoConstraints = false

        // 탭바까지 덮도록 tabBarController의 view에 추가
        guard let targetView = tabBarController?.view ?? navigationController?.view ?? view else { return }
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

    @objc
    private func shopButtonTapped() {
        let globalStore = AppDIContainer.shared.resolve(GlobalStoreProtocol.self)
        let createDamagoUseCase = AppDIContainer.shared.resolve(CreateDamagoUseCase.self)
        let storeViewModel = StoreViewModel(
            globalStore: globalStore,
            createDamagoUseCase: createDamagoUseCase
        )
        let storeVC = StoreViewController(viewModel: storeViewModel)
        storeVC.modalPresentationStyle = .fullScreen
        self.present(storeVC, animated: true)
    }
}

extension CollectionViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.damagos.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: DamagoCell.reuseIdentifier,
            for: indexPath
        ) as? DamagoCell else {
            return UICollectionViewCell()
        }
        let damagoType = viewModel.damagos[indexPath.item]
        let isAvailable = ownedDamagos.keys.contains(damagoType)
        let isHighLevel = (ownedDamagos[damagoType] ?? 0) >= 30
        
        cell.configure(
            with: damagoType,
            isCurrentDamago: currentDamagoType == damagoType,
            showTemplete: !isAvailable,
            isHighLevel: isHighLevel
        )
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let damagoType = viewModel.damagos[indexPath.item]
        if damagoType == currentDamagoType { return }
        damagoSelectedPublisher.send(damagoType)
    }
}
