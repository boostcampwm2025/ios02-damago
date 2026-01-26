//
//  ProfileSettingViewModel.swift
//  Damago
//
//  Created by 김재영 on 1/26/26.
//

import Combine
import Foundation

final class ProfileSettingViewModel: ViewModel {
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let nicknameChanged: AnyPublisher<String, Never>
        let dateChanged: AnyPublisher<Date, Never>
        let nextButtonDidTap: AnyPublisher<Void, Never>
    }
    
    struct State {
        var nickname: String = ""
        var anniversaryDate: Date?
        var route: Pulse<Route>?
        var isUpdating: Bool = false
        
        var isNextEnabled: Bool {
            !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isUpdating
        }
    }
    
    enum Route {
        case petSetup
        case error(message: String)
    }
    
    @Published private var state = State()
    private var cancellables = Set<AnyCancellable>()
    
    private let updateUserUseCase: UpdateUserUseCase
    private let globalStore: GlobalStoreProtocol
    
    init(updateUserUseCase: UpdateUserUseCase, globalStore: GlobalStoreProtocol) {
        self.updateUserUseCase = updateUserUseCase
        self.globalStore = globalStore
    }
    
    func transform(_ input: Input) -> AnyPublisher<State, Never> {
        input.viewDidLoad
            .sink { [weak self] in
                self?.bindGlobalState()
            }
            .store(in: &cancellables)
            
        input.nicknameChanged
            .sink { [weak self] nickname in
                self?.state.nickname = nickname
            }
            .store(in: &cancellables)
            
        input.dateChanged
            .sink { [weak self] date in
                self?.state.anniversaryDate = date
            }
            .store(in: &cancellables)
            
        input.nextButtonDidTap
            .sink { [weak self] in
                self?.saveAndNext()
            }
            .store(in: &cancellables)
            
        return $state.eraseToAnyPublisher()
    }
    
    private func bindGlobalState() {
        globalStore.globalState
            .compactMapForUI { $0.nickname }
            .sink { [weak self] nickname in
                if self?.state.nickname.isEmpty == true {
                    self?.state.nickname = nickname
                }
            }
            .store(in: &cancellables)
    }
    
    private func saveAndNext() {
        Task {
            state.isUpdating = true
            defer { state.isUpdating = false }
            
            do {
                try await updateUserUseCase.execute(
                    nickname: state.nickname,
                    anniversaryDate: state.anniversaryDate,
                    useFCM: nil,
                    useLiveActivity: nil,
                    petName: nil,
                    petType: nil
                )
                state.route = Pulse(.petSetup)
            } catch {
                state.route = Pulse(.error(message: error.localizedDescription))
            }
        }
    }
}
