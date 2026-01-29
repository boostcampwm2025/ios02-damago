//
//  CardGameViewController.swift
//  Damago
//
//  Created by 박현수 on 2026/01/28.
//

import Combine
import UIKit

final class CardGameViewController: UIViewController {
    private let mainView = CardGameView()
    private let viewModel: CardGameViewModel
    private var cancellables = Set<AnyCancellable>()

    private lazy var dataSource = CardGameDataSource(collectionView: mainView.collectionView)

    private let cardDidTapSubject = PassthroughSubject<Int, Never>()
    private let alertConfirmDidTapSubject = PassthroughSubject<Void, Never>()

    init(viewModel: CardGameViewModel) {
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
        setupCollectionView()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setupCollectionView() {
        mainView.collectionView.delegate = self
    }

    private func bind() {
        let input = CardGameViewModel.Input(
            viewDidLoad: Just(()).eraseToAnyPublisher(),
            cardTapped: cardDidTapSubject.eraseToAnyPublisher(),
            alertConfirmDidTap: alertConfirmDidTapSubject.eraseToAnyPublisher()
        )

        let output = viewModel.transform(input)

        output
            .mapForUI { $0.items }
            .sink { [weak self] items in
                self?.applySnapshot(items: items)
            }
            .store(in: &cancellables)

        output
            .mapForUI(
                { ($0.remainingMilliseconds, $0.maximumMilliseconds) },
                isDuplicate: { $0.0 == $1.0 }
            )
            .sink { [weak self] remainingMilliseconds, maximumMilliseconds in
                let progress = Float(remainingMilliseconds) / Float(maximumMilliseconds)
                self?.mainView.updateTimer(progress)
            }
            .store(in: &cancellables)

        output
            .mapForUI { $0.score }
            .sink { [weak self] score in
                self?.mainView.updateCoin(score)
            }
            .store(in: &cancellables)

        output
            .mapForUI { $0.countdown }
            .removeDuplicates()
            .sink { [weak self] count in
                self?.mainView.animateCountdown(count)
            }
            .store(in: &cancellables)

        output
            .mapForUI { $0.difficulty }
            .sink { [weak self] difficulty in
                self?.updateLayoutIfNeeded(difficulty: difficulty)
            }
            .store(in: &cancellables)

        output
            .pulse(\.route)
            .sink { [weak self] route in
                switch route {
                case let .alert(title, message):
                    self?.showAlert(title: title, message: message)
                case .back:
                    self?.navigationController?.popViewController(animated: true)
                }
            }
            .store(in: &cancellables)
    }

    private func applySnapshot(items: [CardItem]) {
        var snapshot = NSDiffableDataSourceSnapshot<CardGameSection, CardItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)

        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            self?.alertConfirmDidTapSubject.send()
        })
        present(alert, animated: true)
    }

    private func updateLayoutIfNeeded(difficulty: CardGameDifficulty) {
        guard mainView.collectionView.collectionViewLayout is UICollectionViewFlowLayout
        else { return }

        let layout = CardGameView.createLayout(difficulty: difficulty)
        mainView.collectionView.setCollectionViewLayout(layout, animated: false)

    }
}

extension CardGameViewController: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        cardDidTapSubject.send(indexPath.item)
    }
}
