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
    private let petNameChangeSubmittedPublisher = PassthroughSubject<String, Never>()
    private var currentPetTypeRaw: String = ""

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
        LiveActivityManager.shared.synchronizeActivity()

        let output = viewModel.transform(
            HomeViewModel.Input(
                viewDidLoad: viewDidLoadPublisher.eraseToAnyPublisher(),
                feedButtonDidTap: mainView.feedButton.tapPublisher,
                pokeMessageSelected: pokeMessageSelectedPublisher.eraseToAnyPublisher(),
                petNameChangeSubmitted: petNameChangeSubmittedPublisher.eraseToAnyPublisher()
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

        mainView.editNameButton.tapPublisher
            .sink { [weak self] in
                self?.showEditPetNamePopup()
            }
            .store(in: &cancellables)
        
        mainView.expBar.levelUpPublisher
            .sink { [weak self] level in
                self?.showLevelUpAlert(level: level)
            }
            .store(in: &cancellables)
    }

    private func showEditPetNamePopup() {
        let popupView = PetNameEditPopupView()
        let petType = DamagoType(rawValue: currentPetTypeRaw)
        popupView.configure(petType: petType, initialName: mainView.nameLabel.text)
        popupView.translatesAutoresizingMaskIntoConstraints = false

        let targetView = tabBarController?.view ?? view
        targetView?.addSubview(popupView)

        NSLayoutConstraint.activate([
            popupView.topAnchor.constraint(equalTo: targetView!.topAnchor),
            popupView.leadingAnchor.constraint(equalTo: targetView!.leadingAnchor),
            popupView.trailingAnchor.constraint(equalTo: targetView!.trailingAnchor),
            popupView.bottomAnchor.constraint(equalTo: targetView!.bottomAnchor)
        ])

        popupView.confirmButtonTappedSubject
            .sink { [weak self, weak popupView] name in
                self?.petNameChangeSubmittedPublisher.send(name)
                popupView?.removeFromSuperview()
            }
            .store(in: &cancellables)

        popupView.cancelButtonTappedSubject
            .sink { [weak popupView] in
                popupView?.removeFromSuperview()
            }
            .store(in: &cancellables)

        popupView.requestCancelConfirmationSubject
            .sink { [weak self, weak popupView] in
                guard let self, let popupView else { return }
                let alert = UIAlertController(
                    title: "취소할까요?",
                    message: "입력한 내용이 저장되지 않아요.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "계속 입력", style: .cancel))
                alert.addAction(UIAlertAction(title: "취소", style: .destructive) { _ in
                    popupView.removeFromSuperview()
                })
                self.present(alert, animated: true)
            }
            .store(in: &cancellables)

        popupView.alpha = 0
        UIView.animate(withDuration: 0.2) {
            popupView.alpha = 1
        }
    }
    
    private func showLevelUpAlert(level: Int) {
        let alert = UIAlertController(
            title: "🎉 레벨 업!",
            message: "축하합니다! Lv.\(level)이(가) 되었습니다!",
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
            .mapForUI({ ($0.isLoading, $0.isUpdatingName) }, isDuplicate: ==)
            .sink { [weak self] isLoading, isUpdatingName in
                guard let self else { return }
                if isUpdatingName {
                    self.progressView.show(in: self.view, message: "변경 중...")
                } else if isLoading {
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
            .pulse(\.route)
            .sink { [weak self] route in
                self?.handleRoute(route)
            }
            .store(in: &cancellables)

        output
            .mapForUI { $0 }
            .sink { [weak self] state in
                self?.mainView.updateCharacter(petType: state.petType, isHungry: state.isHungry)
                self?.currentPetTypeRaw = state.petType
            }
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

    private func handleRoute(_ route: HomeViewModel.Route) {
        switch route {
        case .nameChangeSuccess:
            // 별도 토스트 UI가 없어서 간단히 알럿
            let alert = UIAlertController(title: "완료", message: "이름이 변경됐어요.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
        case .error(let message):
            let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
        }
    }
}
