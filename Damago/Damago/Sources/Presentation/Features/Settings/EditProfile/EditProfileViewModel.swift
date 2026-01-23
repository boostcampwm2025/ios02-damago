//
//  EditProfileViewModel.swift
//  Damago
//
//  Created by 박현수 on 1/21/26.
//

import Combine
import Foundation

final class EditProfileViewModel: ViewModel {
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let nicknameChanged: AnyPublisher<String, Never>
        let dateChanged: AnyPublisher<Date, Never>
        let saveButtonDidTap: AnyPublisher<Void, Never>
    }
    
    struct State {
        var nickname: String = ""
        var anniversaryDate: Date?
        var route: Pulse<Route>?
        var isUpdating: Bool = false

        var isSaveEnabled: Bool { !nickname.isEmpty && !isUpdating }
    }
    
    enum Route {
        case back
        case error(message: String)
    }
    
    @Published private var state = State()
    private var cancellables = Set<AnyCancellable>()
    
    private let globalStore: GlobalStoreProtocol
    private let updateUserUseCase: UpdateUserUseCase
    
    init(globalStore: GlobalStoreProtocol, updateUserUseCase: UpdateUserUseCase) {
        self.globalStore = globalStore
        self.updateUserUseCase = updateUserUseCase
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
            
        input.saveButtonDidTap
            .sink { [weak self] in
                self?.saveProfile()
            }
            .store(in: &cancellables)
            
        return $state.eraseToAnyPublisher()
    }
    
    private func bindGlobalState() {
        globalStore.globalState
            .compactMapForUI { $0.nickname }
            .sink { [weak self] nickname in
                self?.state.nickname = nickname
            }
            .store(in: &cancellables)

        globalStore.globalState
            .compactMapForUI { $0.anniversaryDate }
            .sink { [weak self] date in
                self?.state.anniversaryDate = date
            }
            .store(in: &cancellables)

        globalStore.globalState
            .compactMapForUI { $0.anniversaryDate }
            .sink { [weak self] date in
                self?.state.anniversaryDate = date
            }
            .store(in: &cancellables)
    }
    
    private func saveProfile() {
        Task {
            state.isUpdating = true
            defer { state.isUpdating = false }
            do {
                try await updateUserUseCase.execute(
                    nickname: state.nickname,
                    anniversaryDate: state.anniversaryDate,
                    useFCM: nil,
                    useLiveActivity: nil
                )
                state.route = Pulse(.back)
            } catch {
                state.route = Pulse(.error(message: error.localizedDescription))
            }
        }
    }
}
