//
//  BalanceGameCardViewController.swift
//  Damago
//
//  Created by Eden Landelyse on 1/20/26.
//

import UIKit
import Combine

final class BalanceGameCardViewController: UIViewController {
    private let cardView = BalanceGameCardView()
    private let viewModel: BalanceGameCardViewModel
    private var cancellables = Set<AnyCancellable>()

    // ViewModel의 Input으로 되돌려보내기 위해 설정
    private let confirmResultSubject = PassthroughSubject<(BalanceGameChoice, Bool), Never>()

    // ViewModel이 같은 pendingConfirm을 연속으로 방출할 때 중복 알럿 방지용
    private var lastPresentedPending: BalanceGameChoice?

    // 마지막 선택이 없을 경우(최초 선택 확정) 1회 선택 완료 알럿을 띄우기 위함
    private var lastSelectedChoice: BalanceGameChoice?

    private var leftChoiceText: String?
    private var rightChoiceText: String?

    init(viewModel: BalanceGameCardViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = cardView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        bindViewModel()
    }

    private func bindViewModel() {
        // UIButton이 가진 publisher를 viewModel에 맞게 변환
        let leftTapped: AnyPublisher<BalanceGameChoice, Never> =
        cardView.leftChoiceButton.tapPublisher
            .map { BalanceGameChoice.left }
            .eraseToAnyPublisher()

        let rightTapped: AnyPublisher<BalanceGameChoice, Never> =
        cardView.rightChoiceButton.tapPublisher
            .map { BalanceGameChoice.right }
            .eraseToAnyPublisher()

        let choiceTapped: AnyPublisher<BalanceGameChoice, Never> =
        Publishers.Merge(leftTapped, rightTapped)
            .eraseToAnyPublisher()

        let input = BalanceGameCardViewModel.Input(
            choiceTapped: choiceTapped,
            confirmResult: confirmResultSubject.eraseToAnyPublisher()
        )

        let output = viewModel.transform(input)
        bind(output)
    }

    private func bind(_ output: BalanceGameCardViewModel.Output) {
        output
            .sink { [weak self] state in
                self?.render(state)
            }
            .store(in: &cancellables)
    }

    private func render(_ state: BalanceGameCardViewModel.State) {
        guard let uiModel = state.uiModel else { return }

        // 질문 텍스트 및 보상 정보 업데이트
        let question: String
        let option1: String
        let option2: String
        
        switch uiModel {
        case .input(let inputState):
            question = inputState.questionContent
            option1 = inputState.option1
            option2 = inputState.option2
        case .result(let resultState):
            question = resultState.questionContent
            option1 = resultState.option1
            option2 = resultState.option2
        }

        self.leftChoiceText = option1
        self.rightChoiceText = option2

        cardView.configure(
            category: "미니 미션",
            question: "Q: \(question)",
            leftChoice: option1,
            rightChoice: option2,
            foods: 2,
            coins: 20
        )

        let viewState: BalanceGameCardUIState

        // ViewModel의 State에 결과 데이터가 포함되어 있으면 .result 상태, 아니면 .choosing 상태
        if let myChoice = state.myChoice,
           let opponentChoice = state.opponentChoice {

            viewState = .result(
                myChoice: myChoice,
                opponentChoice: opponentChoice,
                matchResult: state.matchResult,
                isOpponentAnswered: state.isOpponentAnswered,
                headerStatus: state.headerStatus,
                targetDate: state.targetDate
            )
        } else {
            // 결과 데이터가 없거나 불완전하면 선택 중 상태로 간주
            let choiceToRender = state.pendingConfirm ?? state.myChoice
            viewState = .choosing(
                selected: choiceToRender,
                headerStatus: state.headerStatus,
                targetDate: state.targetDate
            )
        }

        // 최종적으로 View에 상태를 전달하여 화면을 업데이트합니다.
        cardView.render(state: viewState)

        // 1. "선택 후 변경할 수 없습니다!" 알럿 (pendingConfirm)
        presentConfirmIfNeeded(pending: state.pendingConfirm)

        // 2. "상대방 답변 대기 중" 알럿 (showLockedAlert)
        if let choice = state.showLockedAlert?.value {
            presentWaitingAlertIfNeeded(confirmed: choice)
        }

        // 마지막 선택 상태를 업데이트합니다. (항상 마지막에)
        self.lastSelectedChoice = state.myChoice
    }

    private func presentConfirmIfNeeded(pending: BalanceGameChoice?) {
        guard let pending else {
            lastPresentedPending = nil
            return
        }

        guard lastPresentedPending != pending else { return }
        lastPresentedPending = pending

        let choiceText: String = {
            switch pending {
            case .left:
                return leftChoiceText ?? "왼쪽"
            case .right:
                return rightChoiceText ?? "오른쪽"
            }
        }()

        let message = "\n선택 후 변경할 수 없습니다!"
        let alert = UIAlertController(title: "\"\(choiceText)\"", message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "더 고민하기", style: .cancel) { [weak self, alert] _ in
            alert.dismiss(animated: true) {
                self?.confirmResultSubject.send((pending, false))
            }
        })

        alert.addAction(UIAlertAction(title: "확정하기", style: .default) { [weak self, alert] _ in
            alert.dismiss(animated: true) {
                self?.confirmResultSubject.send((pending, true))
            }
        })

        present(alert, animated: true)
    }

    private func presentWaitingAlertIfNeeded(confirmed: BalanceGameChoice) {
        guard presentedViewController == nil else { return }

        let message = "선택완료! 상대방 답변을 기다리는 중이에요"
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))

        if Thread.isMainThread {
            present(alert, animated: true)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.present(alert, animated: true)
            }
        }
    }
}
