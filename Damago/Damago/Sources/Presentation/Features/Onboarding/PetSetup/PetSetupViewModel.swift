//
//  PetSetupViewModel.swift
//  Damago
//
//  Created by 김재영 on 1/26/26.
//

import Combine
import Foundation

final class PetSetupViewModel: ViewModel {
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let petSelected: AnyPublisher<DamagoType, Never>
        let confirmButtonTapped: AnyPublisher<String, Never>
    }
    
    struct State {
        var pets: [DamagoType] = DamagoType.allCases
        var selectedPet: DamagoType?
        var isLoading: Bool = false
        var route: Pulse<Route>?
    }
    
    enum Route {
        case home
        case showPopup(petType: DamagoType)
        case error(title: String, message: String)
    }
    
    @Published private var state = State()
    private var cancellables = Set<AnyCancellable>()
    
    private let updateUserUseCase: UpdateUserUseCase
    
    init(updateUserUseCase: UpdateUserUseCase) {
        self.updateUserUseCase = updateUserUseCase
    }
    
    func transform(_ input: Input) -> AnyPublisher<State, Never> {
        input.petSelected
            .sink { [weak self] petType in
                if petType.isAvailable {
                    self?.state.selectedPet = petType
                    self?.state.route = Pulse(.showPopup(petType: petType))
                } else {
                    self?.state.route = Pulse(.error(title: "🙌 추후 업데이트 예정입니다!", message: "더 좋은 서비스로 찾아뵙겠습니다."))
                }
            }
            .store(in: &cancellables)
            
        input.confirmButtonTapped
            .sink { [weak self] petName in
                self?.savePet(name: petName)
            }
            .store(in: &cancellables)
            
        return $state.eraseToAnyPublisher()
    }
    
    private func savePet(name: String) {
        guard let selectedPet = state.selectedPet else { return }
        
        Task {
            state.isLoading = true
            defer { state.isLoading = false }
            
            do {
                try await updateUserUseCase.execute(
                    nickname: nil,
                    anniversaryDate: nil,
                    useFCM: true,
                    useLiveActivity: true,
                    petName: name,
                    petType: selectedPet.rawValue
                )
                UserDefaults.standard.set(true, forKey: "isOnboardingCompleted")
                state.route = Pulse(.home)
            } catch {
                state.route = Pulse(.error(title: "오류", message: error.localizedDescription))
            }
        }
    }
    
    func selectPet(_ pet: DamagoType) {
        state.selectedPet = pet
    }
}
