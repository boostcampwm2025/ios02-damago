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
    private let progressView = ProgressView()

    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let pokeMessageSelectedPublisher = PassthroughSubject<String, Never>()

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
                pokeMessageSelected: pokeMessageSelectedPublisher.eraseToAnyPublisher()
            )
        )

        bind(output)
        setupActions()

        viewDidLoadPublisher.send()
    }
    
    private func setupActions() {
        mainView.pokeButton.tapPublisher
            .sink { [weak self] _ in
                self?.showPokeMessagePopup()
            }
            .store(in: &cancellables)
        
        mainView.expBar.levelUpPublisher
            .sink { [weak self] level in
                self?.showLevelUpAlert(level: level)
            }
            .store(in: &cancellables)
    }
    
    private func showLevelUpAlert(level: Int) {
        let alert = UIAlertController(
            title: "🎉 레벨 업!",
            message: "축하합니다! Lv.\(level)이 되었습니다!",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "확인", style: .default))

        present(alert, animated: true)
    }
    
    private func showPokeMessagePopup() {
        let shortcutRepository = AppDIContainer.shared.resolve(PokeShortcutRepositoryProtocol.self)
        let popupViewController = PokePopupViewController(shortcutRepository: shortcutRepository)
        popupViewController.modalPresentationStyle = .overFullScreen
        popupViewController.modalTransitionStyle = .crossDissolve
        
        popupViewController.onMessageSelected = { [weak self] message in
            self?.pokeMessageSelectedPublisher.send(message)
        }
        
        present(popupViewController, animated: true)
    }

    func bind(_ output: HomeViewModel.Output) {
        output
            .mapForUI { $0.isLoading }
            .sink { [weak self] isLoading in
                guard let self else { return }
                if isLoading {
                    self.progressView.show(in: self.view, message: "불러오는 중...")
                } else {
                    self.progressView.hide()
                }
            }
            .store(in: &cancellables)

        output
            .mapForUI { $0.dDay }
            .sink { [weak self] in self?.mainView.updateDDay(days: $0) }
            .store(in: &cancellables)

        output
            .mapForUI { $0.totalCoin }
            .sink { [weak self] in self?.mainView.updateCoin(amount: $0) }
            .store(in: &cancellables)

        output
            .mapForUI { HomeView.FeedButtonState(foodAmount: $0.foodCount, isEnabled: $0.isFeedButtonEnabled) }
            .sink { [weak self] in self?.mainView.updateFeedButton(state: $0) }
            .store(in: &cancellables)

        output
            .mapForUI { $0.petName }
            .sink { [weak self] in self?.mainView.nameLabel.text = $0 }
            .store(in: &cancellables)

        output
            .mapForUI { $0.isPokeButtonEnabled }
            .sink { [weak self] in self?.mainView.pokeButton.isEnabled = $0 }
            .store(in: &cancellables)

        output
            .mapForUI { ExperienceBar.State(level: $0.level, currentExp: $0.currentExp, maxExp: $0.maxExp) }
            .sink { [weak self] in self?.mainView.expBar.update(with: $0) }
            .store(in: &cancellables)
    }
}
