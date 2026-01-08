//
//  HomeViewController.swift
//  Damago
//
//  Created by 박현수 on 1/7/26.
//

import Combine
import UIKit

final class HomeViewController: UIViewController {
    private let mainView = HomeView()
    private let viewModel: HomeViewModel

    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()

    init(viewModel: HomeViewModel) {
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

        let output = viewModel.transform(
            HomeViewModel.Input(
                viewDidLoad: viewDidLoadPublisher.eraseToAnyPublisher(),
                feedButtonDidTap: mainView.feedButton.tapPublisher,
                pokeButtonDidTap: mainView.pokeButton.tapPublisher
            )
        )

        bind(output)

        viewDidLoadPublisher.send()
    }

    func bind(_ output: HomeViewModel.Output) {
        output
            .mapForUI { $0.dDay }
            .sink { [weak self] dDay in self?.mainView.updateDDay(days: dDay) }
            .store(in: &cancellables)

        output
            .mapForUI { $0.coinAmount }
            .sink { [weak self] amount in self?.mainView.updateCoin(amount: amount) }
            .store(in: &cancellables)

        output
            .mapForUI { $0.foodAmount }
            .sink { [weak self] amount in self?.mainView.foodBadge.text = "\(amount)" }
            .store(in: &cancellables)

        output
            .mapForUI { $0.petName }
            .sink { [weak self] name in self?.mainView.nameLabel.text = name }
            .store(in: &cancellables)

        output
            .mapForUI { $0.isFeedButtonEnabled }
            .sink { [weak self] isEnabled in self?.mainView.feedButton.isEnabled = isEnabled }
            .store(in: &cancellables)

        output
            .mapForUI { $0.isPokeButtonEnabled }
            .sink { [weak self] isEnabled in self?.mainView.pokeButton.isEnabled = isEnabled }
            .store(in: &cancellables)
    }
}
