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
        case damagoSetup
        case partnerAlreadySelected
        case error(message: String)
    }
    
    @Published private var state = State()
    private var cancellables = Set<AnyCancellable>()
    
    private let updateUserUseCase: UpdateUserUseCase
    private let fetchUserInfoUseCase: FetchUserInfoUseCase
    
    init(
        updateUserUseCase: UpdateUserUseCase,
        fetchUserInfoUseCase: FetchUserInfoUseCase
    ) {
        self.updateUserUseCase = updateUserUseCase
        self.fetchUserInfoUseCase = fetchUserInfoUseCase
    }
    
    func transform(_ input: Input) -> AnyPublisher<State, Never> {
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
                    damagoName: nil,
                    damagoType: nil
                )
                
                // 최신 정보를 직접 조회하여 파트너가 펫을 결정했는지 확인
                let userInfo = try await fetchUserInfoUseCase.execute()
                
                if userInfo.damagoID != nil {
                    state.route = Pulse(.partnerAlreadySelected)
                } else {
                    state.route = Pulse(.damagoSetup)
                }
            } catch {
                state.route = Pulse(.error(message: error.localizedDescription))
            }
        }
    }
}
