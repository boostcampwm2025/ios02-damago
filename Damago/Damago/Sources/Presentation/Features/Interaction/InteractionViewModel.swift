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
    
    @Published private var state = State()
    private var cancellables = Set<AnyCancellable>()
    private var observationCancellable: AnyCancellable?
    private var coupleID: String?
    
    var uiModelPublisher: AnyPublisher<DailyQuestionUIModel, Never> {
        $state
            .compactMap { $0.dailyQuestionUIModel }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    init(
        fetchDailyQuestionUseCase: FetchDailyQuestionUseCase,
        observeDailyQuestionAnswerUseCase: ObserveDailyQuestionAnswerUseCase,
        userRepository: UserRepositoryProtocol,
        globalStore: GlobalStoreProtocol
    ) {
        self.fetchDailyQuestionUseCase = fetchDailyQuestionUseCase
        self.observeDailyQuestionAnswerUseCase = observeDailyQuestionAnswerUseCase
        self.userRepository = userRepository
        self.globalStore = globalStore
    }
    
    func transform(_ input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] in
                self?.initializeData()
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

    private func initializeData() {
        Task {
            do {
                let userInfo = try await userRepository.getUserInfo()
                self.coupleID = userInfo.coupleID
                // 초기 데이터는 GlobalStore 구독으로 처리되므로 여기서 명시적 fetch는 생략 가능하지만,
                // GlobalStore가 아직 데이터를 안 줬을 수도 있으므로 안전하게 fetch 호출
                await fetchDailyQuestionData()
            } catch {
                SharedLogger.interaction.error("UserInfo 가져오기 실패: \(error.localizedDescription)")
            }
        }
    }
    
    private func bindGlobalStore() {
        globalStore.coupleSharedInfo
            .compactMap { $0.currentQuestionId }
            .removeDuplicates()
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.fetchDailyQuestionData()
                }
            }
            .store(in: &cancellables)
    }

    private func fetchDailyQuestionData() async {
        do {
            let uiModel = try await fetchDailyQuestionUseCase.execute()
            self.state.dailyQuestionUIModel = uiModel
            self.startObserving(uiModel: uiModel)
        } catch {
            SharedLogger.interaction.error("오늘의 질문 가져오기 실패: \(error.localizedDescription)")
        }
    }
    
    private func startObserving(uiModel: DailyQuestionUIModel) {
        guard let coupleID = self.coupleID else { return }
        
        observationCancellable?.cancel()
        
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
        
        self.observationCancellable = self.observeDailyQuestionAnswerUseCase
            .execute(
                coupleID: coupleID,
                questionID: questionID,
                questionContent: questionContent,
                isUser1: isUser1
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                if case .success(let updatedModel) = result {
                    if self?.state.dailyQuestionUIModel != updatedModel {
                        self?.state.dailyQuestionUIModel = updatedModel
                    }
                }
            }
    }
}
