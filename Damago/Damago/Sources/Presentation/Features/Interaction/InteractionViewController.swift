//
//  InteractionViewController.swift
//  Damago
//
//  Created by 김재영 on 1/15/26.
//

import UIKit
import Combine

final class InteractionViewController: UIViewController {
    private let mainView = InteractionView()
    private let viewModel: InteractionViewModel
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    
    private var isNavigationBarHidden = true
    private var cancellables = Set<AnyCancellable>()

    private var balanceGameCardChildViewController: BalanceGameCardViewController?

    init(viewModel: InteractionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupDelegate()
        mainView.configure(title: viewModel.title, subtitle: viewModel.subtitle)
        
        let output = viewModel.transform(
            InteractionViewModel.Input(
                viewDidLoad: viewDidLoadPublisher.eraseToAnyPublisher(),
                questionSubmitButtonDidTap: mainView.questionCardView.submitButton.tapPublisher,
                historyButtonDidTap: mainView.historyButton.tapPublisher
            )
        )
        
        bind(output)
        viewDidLoadPublisher.send()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    private func setupNavigation() {
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.title = ""
        navigationItem.backButtonDisplayMode = .minimal
    }
    
    private func setupDelegate() {
        mainView.scrollView.delegate = self
    }

    private func setupBalanceGameCard(uiModel: BalanceGameUIModel) {
        guard balanceGameCardChildViewController == nil else { return }

        let vm = BalanceGameCardViewModel(
            uiModel: uiModel,
            uiModelPublisher: viewModel.balanceGameUIModelPublisher
        ) { [weak self] choice in
            try await self?.viewModel.submitBalanceGameChoice(choice: choice)
        }

        let vc = BalanceGameCardViewController(viewModel: vm)
        self.balanceGameCardChildViewController = vc
        let containerView = mainView.balanceGameCardView

        addChild(vc)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(vc.view)

        NSLayoutConstraint.activate([
            vc.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            vc.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            vc.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        vc.didMove(toParent: self)
    }
    
    private func bind(_ output: InteractionViewModel.Output) {
        output
            .mapForUI { $0.dailyQuestionUIModel }
            .compactMap { $0 }
            .sink { [weak self] uiModel in
                let questionContent: String
                let buttonTitle: String
                
                switch uiModel {
                case .input(let inputState):
                    questionContent = inputState.questionContent
                    buttonTitle = "답변 제출"
                case .result(let resultState):
                    questionContent = resultState.questionContent
                    buttonTitle = resultState.buttonTitle
                }
                
                self?.mainView.questionCardView.configure(question: questionContent, buttonTitle: buttonTitle)
            }
            .store(in: &cancellables)

        output
            .mapForUI { $0.balanceGameUIModel }
            .compactMap { $0 }
            .first()
            .sink { [weak self] uiModel in
                self?.setupBalanceGameCard(uiModel: uiModel)
            }
            .store(in: &cancellables)
        
        output
            .pulse(\.route)
            .sink { [weak self] route in
                guard let self else { return }
                navigationController?.setNavigationBarHidden(false, animated: true)
                isNavigationBarHidden = false
                switch route {
                case .questionInput(let uiModel):
                    let submitUseCase = AppDIContainer.shared.resolve(SubmitDailyQuestionAnswerUseCase.self)
                    let manageDraftUseCase = AppDIContainer.shared.resolve(ManageDailyQuestionDraftAnswerUseCase.self)
                    
                    let vm = DailyQuestionInputViewModel(
                        uiModel: uiModel,
                        uiModelPublisher: self.viewModel.dailyQuestionUIModelPublisher,
                        submitDailyQuestionAnswerUseCase: submitUseCase,
                        manageDraftAnswerUseCase: manageDraftUseCase
                    )
                    let vc = DailyQuestionInputViewController(viewModel: vm)
                    vc.hidesBottomBarWhenPushed = true
                    self.navigationController?.pushViewController(vc, animated: true)
                    
                case .history:
                    let fetchDailyQuestionsHistoryUseCase = AppDIContainer.shared.resolve(
                        FetchDailyQuestionsHistoryUseCase.self
                    )
                    let fetchBalanceGamesHistoryUseCase = AppDIContainer.shared.resolve(
                        FetchBalanceGamesHistoryUseCase.self
                    )
                    let vm = HistoryViewModel(
                        fetchDailyQuestionsHistoryUseCase: fetchDailyQuestionsHistoryUseCase,
                        fetchBalanceGamesHistoryUseCase: fetchBalanceGamesHistoryUseCase
                    )
                    let vc = HistoryViewController(viewModel: vm)
                    vc.hidesBottomBarWhenPushed = true
                    self.navigationController?.pushViewController(vc, animated: true)
                    
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - UIScrollViewDelegate
extension InteractionViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let threshold: CGFloat = 40
        let scrollY = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        
        if scrollY > threshold {
            if isNavigationBarHidden {
                navigationController?.setNavigationBarHidden(false, animated: true)
                navigationItem.title = viewModel.title
                isNavigationBarHidden = false
            }
        } else {
            if !isNavigationBarHidden {
                navigationController?.setNavigationBarHidden(true, animated: true)
                navigationItem.title = ""
                isNavigationBarHidden = true
            }
        }
        
        let fadeThreshold: CGFloat = 50
        let alpha = max(0, min(1, 1 - (scrollY / fadeThreshold)))
        mainView.setSubtitleAlpha(alpha)
    }
}
