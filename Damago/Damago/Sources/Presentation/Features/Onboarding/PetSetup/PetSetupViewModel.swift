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
        var currentPetType: DamagoType?
        var currentPetName: String?
        var coupleID: String?
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
    private let fetchUserInfoUseCase: FetchUserInfoUseCase
    private let petRepository: PetRepositoryProtocol
    
    init(
        updateUserUseCase: UpdateUserUseCase,
        fetchUserInfoUseCase: FetchUserInfoUseCase,
        petRepository: PetRepositoryProtocol
    ) {
        self.updateUserUseCase = updateUserUseCase
        self.fetchUserInfoUseCase = fetchUserInfoUseCase
        self.petRepository = petRepository
    }
    
    func transform(_ input: Input) -> AnyPublisher<State, Never> {
        input.viewDidLoad
            .sink { [weak self] in
                self?.loadCurrentPetInfo()
            }
            .store(in: &cancellables)

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
    
    func prefillName(for petType: DamagoType) -> String? {
        guard petType == state.currentPetType else { return nil }
        return state.currentPetName
    }

    func observePrefillName(for petType: DamagoType) -> AnyPublisher<String, Never> {
        guard let coupleID = state.coupleID else {
            return Empty().eraseToAnyPublisher()
        }
        let damagoID = "\(coupleID)_\(petType.rawValue)"
        return petRepository.observePetSnapshot(damagoID: damagoID)
            .compactMap { try? $0.get().petName }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private func loadCurrentPetInfo() {
        Task {
            do {
                let userInfo = try await fetchUserInfoUseCase.execute()
                state.coupleID = userInfo.coupleID
                state.currentPetType = userInfo.petStatus.flatMap { DamagoType(rawValue: $0.petType) }
                state.currentPetName = userInfo.petStatus?.petName
            } catch {
                state.coupleID = nil
                state.currentPetType = nil
                state.currentPetName = nil
            }
        }
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
