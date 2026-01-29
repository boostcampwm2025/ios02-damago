//
//  BalanceGameCardView.swift
//  Damago
//
//  Created by Eden Landelyse on 1/25/26.
//

import UIKit

enum BalanceGameCardUIState {
    case choosing(selected: BalanceGameChoice?, headerStatus: String, targetDate: Date?, isSubmitting: Bool)
    case result(
        myChoice: BalanceGameChoice,
        opponentChoice: BalanceGameChoice,
        matchResult: BalanceGameCardViewModel.MatchResult?,
        isOpponentAnswered: Bool,
        headerStatus: String,
        targetDate: Date?
    )
}

final class BalanceGameCardView: UIView {
    private var category: String = "미니 미션"
    private var rewardFoods: Int?
    private var rewardCoins: Int?

    private let view: CardView = {
        let view = CardView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let headerView: TimerCardHeaderView = {
        let view = TimerCardHeaderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let questionLabel: UILabel = {
        let label = UILabel()
        label.text = nil
        label.font = .body3
        label.textColor = .black
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let choiceView: BalanceGameChoiceView = {
        let view = BalanceGameChoiceView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // ViewController에서 접근해야 할 버튼들 대리 참조용 버튼
    var leftChoiceButton: UIButton { choiceView.leftChoiceButton }
    var rightChoiceButton: UIButton { choiceView.rightChoiceButton }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear
        addSubview(view)
        [headerView, questionLabel, choiceView].forEach { view.addSubview($0) }
        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor),
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor),

            headerView.topAnchor.constraint(equalTo: topAnchor, constant: .spacingL),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingL),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingL),

            questionLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: .spacingL),
            questionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingL),
            questionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingL),

            choiceView.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: .spacingL),
            choiceView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingL),
            choiceView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingL),
            choiceView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -.spacingL),
            choiceView.heightAnchor.constraint(equalToConstant: 180)
        ])
    }

    // MARK: - redner 메서드

    func render(state: BalanceGameCardUIState) {
        switch state {
        case .choosing(let selected, let headerStatus, let targetDate, let isSubmitting):
            headerView.configure(
                title: "밸런스 게임",
                rightTitle: headerStatus,
                targetDate: targetDate,
                foods: rewardFoods,
                coins: rewardCoins,
                badge: category
            )
            choiceView.render(selected: selected, isResult: false)
            choiceView.isUserInteractionEnabled = !isSubmitting

        case .result(
            let myChoice,
            let opponentChoice,
            _,
            _,
            let headerStatus,
            let targetDate
        ):
            headerView.configure(
                title: "밸런스 게임",
                rightTitle: headerStatus,
                targetDate: targetDate,
                foods: rewardFoods,
                coins: rewardCoins,
                badge: category
            )
            choiceView.render(selected: nil, isResult: true, myChoice: myChoice, opponentChoice: opponentChoice)
        }
    }

    func configure(
        category: String,
        question: String,
        leftChoice: String,
        rightChoice: String,
        foods: Int? = nil,
        coins: Int? = nil
    ) {
        self.category = category
        self.rewardFoods = foods
        self.rewardCoins = coins

        headerView.configure(title: "밸런스 게임", foods: foods, coins: coins, badge: category)
        questionLabel.text = question
        choiceView.setChoiceTitles(left: leftChoice, right: rightChoice)

        render(state: .choosing(selected: nil, headerStatus: "", targetDate: nil, isSubmitting: false))
    }
}
