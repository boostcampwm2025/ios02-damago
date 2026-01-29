//
//  InteractionViewModel.swift
//  Damago
//
//  Created by 김재영 on 1/15/26.
//

import Combine
import Foundation
import OSLog

final class InteractionViewModel: ViewModel {
    let title = "커플 활동"
    let subtitle = "더 가까워지기 위한 일상 활동"

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let questionSubmitButtonDidTap: AnyPublisher<Void, Never>
        let historyButtonDidTap: AnyPublisher<Void, Never>
    }

    struct State {
        var dailyQuestionUIModel: DailyQuestionUIModel?
        var balanceGameUIModel: BalanceGameUIModel?
        var route: Pulse<Route>?
    }

    enum Route {
        case questionInput(uiModel: DailyQuestionUIModel)
        case history
    }

    private let fetchDailyQuestionUseCase: FetchDailyQuestionUseCase
    private let observeDailyQuestionAnswerUseCase: ObserveDailyQuestionAnswerUseCase
    private let userRepository: UserRepositoryProtocol
    private let globalStore: GlobalStoreProtocol

    private let fetchBalanceGameUseCase: FetchBalanceGameUseCase
    private let observeBalanceGameAnswerUseCase: ObserveBalanceGameAnswerUseCase
    private let submitBalanceGameChoiceUseCase: SubmitBalanceGameChoiceUseCase

    @Published private var state = State()
    private var cancellables = Set<AnyCancellable>()
    private var dailyQuestionObservationCancellable: AnyCancellable?
    private var balanceGameObservationCancellable: AnyCancellable?
    private var coupleID: String?

    var dailyQuestionUIModelPublisher: AnyPublisher<DailyQuestionUIModel, Never> {
        $state
            .compactMap { $0.dailyQuestionUIModel }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var balanceGameUIModelPublisher: AnyPublisher<BalanceGameUIModel, Never> {
        $state
            .compactMap { $0.balanceGameUIModel }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    init(
        fetchDailyQuestionUseCase: FetchDailyQuestionUseCase,
        observeDailyQuestionAnswerUseCase: ObserveDailyQuestionAnswerUseCase,
        fetchBalanceGameUseCase: FetchBalanceGameUseCase,
        observeBalanceGameAnswerUseCase: ObserveBalanceGameAnswerUseCase,
        submitBalanceGameChoiceUseCase: SubmitBalanceGameChoiceUseCase,
        userRepository: UserRepositoryProtocol,
        globalStore: GlobalStoreProtocol
    ) {
        self.fetchDailyQuestionUseCase = fetchDailyQuestionUseCase
        self.observeDailyQuestionAnswerUseCase = observeDailyQuestionAnswerUseCase
        self.fetchBalanceGameUseCase = fetchBalanceGameUseCase
        self.observeBalanceGameAnswerUseCase = observeBalanceGameAnswerUseCase
        self.submitBalanceGameChoiceUseCase = submitBalanceGameChoiceUseCase
        self.userRepository = userRepository
        self.globalStore = globalStore
    }

    func transform(_ input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] in
                self?.bindGlobalStore()
            }
            .store(in: &cancellables)

        input.questionSubmitButtonDidTap
            .sink { [weak self] in
                guard let self, let uiModel = self.state.dailyQuestionUIModel else { return }
                self.state.route = Pulse(.questionInput(uiModel: uiModel))
            }
            .store(in: &cancellables)

        input.historyButtonDidTap
            .sink { [weak self] in
                self?.state.route = Pulse(.history)
            }
            .store(in: &cancellables)

        return $state.eraseToAnyPublisher()
    }

    // swiftlint:disable trailing_closure
    private func bindGlobalStore() {
        globalStore.globalState
            .handleEvents(receiveOutput: { [weak self] state in
                self?.coupleID = state.coupleID
            })
            .compactMapForUI { $0.coupleID }
            .first()
            .sink { [weak self] _ in
                self?.fetchDailyQuestionData()
                self?.fetchBalanceGameData()
            }
            .store(in: &cancellables)
    }
    // swiftlint:enable trailing_closure

    // MARK: - Daily Question
    private func fetchDailyQuestionData() {
        Task { [weak self] in
            guard let self else { return }
            for await uiModel in fetchDailyQuestionUseCase.execute() {
                self.state.dailyQuestionUIModel = uiModel
                self.startObservingDailyQuestion(uiModel: uiModel)
            }
        }
    }

    private func startObservingDailyQuestion(uiModel: DailyQuestionUIModel) {
        guard let coupleID = self.coupleID else { return }
        dailyQuestionObservationCancellable?.cancel()

        let questionID: String
        let questionContent: String
        let isUser1: Bool

        switch uiModel {
        case .input(let state):
            questionID = state.questionID
            questionContent = state.questionContent
            isUser1 = state.isUser1
        case .result(let state):
            questionID = state.questionID
            questionContent = state.questionContent
            isUser1 = state.isUser1
        }

        self.dailyQuestionObservationCancellable = self.observeDailyQuestionAnswerUseCase
            .execute(coupleID: coupleID, questionID: questionID, questionContent: questionContent, isUser1: isUser1)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                if case .success(let updatedModel) = result {
                    self?.state.dailyQuestionUIModel = updatedModel
                }
            }
    }

    // MARK: - Balance Game
    private func fetchBalanceGameData() {
        Task { [weak self] in
            guard let self else { return }
            for await uiModel in fetchBalanceGameUseCase.execute() {
                self.state.balanceGameUIModel = uiModel
                self.startObservingBalanceGame(uiModel: uiModel)
            }
        }
    }

    private func startObservingBalanceGame(uiModel: BalanceGameUIModel) {
        guard let coupleID = self.coupleID else { return }
        balanceGameObservationCancellable?.cancel()

        let gameID: String
        let questionContent: String
        let option1: String
        let option2: String
        let isUser1: Bool

        switch uiModel {
        case .input(let state):
            gameID = state.gameID
            questionContent = state.questionContent
            option1 = state.option1
            option2 = state.option2
            isUser1 = state.isUser1
        case .result(let state):
            gameID = state.gameID
            questionContent = state.questionContent
            option1 = state.option1
            option2 = state.option2
            isUser1 = state.isUser1
        }

        self.balanceGameObservationCancellable = self.observeBalanceGameAnswerUseCase
            .execute(
                coupleID: coupleID,
                gameID: gameID,
                questionContent: questionContent,
                option1: option1,
                option2: option2,
                isUser1: isUser1
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                if case .success(let updatedModel) = result {
                    self?.state.balanceGameUIModel = updatedModel
                }
            }
    }

    func submitBalanceGameChoice(choice: BalanceGameChoice) async throws {
        guard let uiModel = state.balanceGameUIModel else { return }
        let gameID: String

        switch uiModel {
        case .input(let state): gameID = state.gameID
        case .result(let state): gameID = state.gameID
        }
        try await submitBalanceGameChoiceUseCase.execute(gameID: gameID, choice: choice.rawValue)
    }
}
