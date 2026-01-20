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
    private var cancellables = Set<AnyCancellable>()
    private var selectedChoice: BalanceGameCardView.Choice?

    override func loadView() {
        self.view = cardView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        // TODO: 네트워크 결과에 따라 아래 값을 바인딩하도록 교체
        cardView.configure(
            category: "미니 미션",
            question: "Q: 연애할 때 어떤 분위기를 선호하나요?",
            leftChoice: "설레고 두근거리는 연애",
            rightChoice: "편하고 안정적인 연애",
            foods: 2,
            coins: 20
        )

        cardView.render(selectedChoice: selectedChoice)

        cardView.leftChoiceButton.tapPublisher
            .sink { [weak self] in
                guard let self else { return }
                if self.selectedChoice == .left {
                    self.selectedChoice = nil
                } else {
                    self.selectedChoice = .left
                }
                self.cardView.render(selectedChoice: self.selectedChoice)
            }
            .store(in: &cancellables)

        cardView.rightChoiceButton.tapPublisher
            .sink { [weak self] in
                guard let self else { return }
                if self.selectedChoice == .right {
                    self.selectedChoice = nil
                } else {
                    self.selectedChoice = .right
                }
                self.cardView.render(selectedChoice: self.selectedChoice)
            }
            .store(in: &cancellables)
    }
}
