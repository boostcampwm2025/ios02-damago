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
    private let answerDidSubmitPublisher = PassthroughSubject<String, Never>()
    
    private var isNavigationBarHidden = true
    private var cancellables = Set<AnyCancellable>()
    
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
                answerDidSubmitted: answerDidSubmitPublisher.eraseToAnyPublisher(),
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
    
    private func bind(_ output: InteractionViewModel.Output) {
        output
            .mapForUI { $0.dailyQuestion }
            .sink { [weak self] question in
                self?.mainView.questionCardView.configure(question: question)
            }
            .store(in: &cancellables)
        
        output
            .pulse(\.route)
            .sink { [weak self] route in
                guard let self else { return }
                switch route {
                case .questionInput(let question, let myAnswer, let opponentAnswer):
                    let vm = DailyQuestionInputViewModel(
                        question: question,
                        myAnswer: myAnswer,
                        opponentAnswer: opponentAnswer
                    )
                    vm.answerCompleted
                        .subscribe(self.answerDidSubmitPublisher)
                        .store(in: &cancellables)
                    let vc = DailyQuestionInputViewController(viewModel: vm)
                    vc.hidesBottomBarWhenPushed = true
                    self.navigationController?.pushViewController(vc, animated: true)
                    
                case .history:
                    print("지난 내역 보기 클릭")
                    
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
