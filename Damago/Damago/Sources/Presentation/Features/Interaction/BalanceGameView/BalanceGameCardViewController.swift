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

        // TODO: 네트워크 결과에 따라 아래 값을 바인딩하도록 교체
        self.leftChoiceText = "설레고 두근거리는 연애"
        self.rightChoiceText = "편하고 안정적인 연애"

        cardView.configure(
            category: "미니 미션",
            question: "Q: 연애할 때 어떤 분위기를 선호하나요?",
            leftChoice: "설레고 두근거리는 연애",
            rightChoice: "편하고 안정적인 연애",
            foods: 2,
            coins: 20
        )

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
        let previousSelectedChoice = self.lastSelectedChoice

        let renderChoice = state.pendingConfirm ?? state.selectedChoice
        self.cardView.render(selectedChoice: renderChoice)

        self.presentConfirmIfNeeded(pending: state.pendingConfirm)

        if let confirmed = state.showLockedAlert?.value {
            self.presentWaitingAlertIfNeeded(confirmed: confirmed)
        }

        // 확정 직후 1회 알림
        if previousSelectedChoice == nil, let confirmed = state.selectedChoice {
            self.presentWaitingAlertIfNeeded(confirmed: confirmed)
        }

        self.lastSelectedChoice = state.selectedChoice
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

        alert.addAction(UIAlertAction(title: "더 고민하기", style: .cancel) { [weak self] _ in
            self?.confirmResultSubject.send((pending, false))
        })

        alert.addAction(UIAlertAction(title: "확정하기", style: .default) { [weak self] _ in
            self?.confirmResultSubject.send((pending, true))
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
