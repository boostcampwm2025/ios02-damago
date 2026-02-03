//
//  DamagoSetupViewModel.swift
//  Damago
//
//  Created by 김재영 on 1/26/26.
//

import Combine
import Foundation

final class DamagoSetupViewModel: ViewModel {
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let damagoSelected: AnyPublisher<DamagoType, Never>
        let confirmButtonTapped: AnyPublisher<String, Never>
    }
    
    struct State {
        var damagos: [DamagoType] = DamagoType.allCases
        var selectedDamago: DamagoType?
        var currentDamagoType: DamagoType?
        var currentDamagoName: String?
        var coupleID: String?
        var ownedDamagos: [DamagoType: Int] = [:]
        var isLoading: Bool = false
        var route: Pulse<Route>?
    }
    
    enum Route {
        case home
        case showPopup(damagoType: DamagoType)
        case error(title: String, message: String)
    }
    
    @Published private(set) var state = State()
    private var cancellables = Set<AnyCancellable>()
    
    private let updateUserUseCase: UpdateUserUseCase
    private let fetchUserInfoUseCase: FetchUserInfoUseCase
    private let damagoRepository: DamagoRepositoryProtocol
    private let globalStore: GlobalStoreProtocol
    
    init(
        updateUserUseCase: UpdateUserUseCase,
        fetchUserInfoUseCase: FetchUserInfoUseCase,
        damagoRepository: DamagoRepositoryProtocol,
        globalStore: GlobalStoreProtocol
    ) {
        self.updateUserUseCase = updateUserUseCase
        self.fetchUserInfoUseCase = fetchUserInfoUseCase
        self.damagoRepository = damagoRepository
        self.globalStore = globalStore
    }
    
    func transform(_ input: Input) -> AnyPublisher<State, Never> {
        input.viewDidLoad
            .sink { [weak self] in
                self?.loadCurrentDamagoInfo()
            }
            .store(in: &cancellables)

        globalStore.globalState
            .map { $0.ownedDamagos ?? [:] }
            .assign(to: \.state.ownedDamagos, on: self)
            .store(in: &cancellables)

        input.damagoSelected
            .sink { [weak self] damagoType in
                guard let self = self else { return }
                self.state.selectedDamago = damagoType
                self.state.route = Pulse(.showPopup(damagoType: damagoType))
            }
            .store(in: &cancellables)
            
        input.confirmButtonTapped
            .sink { [weak self] damagoName in
                self?.saveDamago(name: damagoName)
            }
            .store(in: &cancellables)
            
        return $state.eraseToAnyPublisher()
    }
    
    func prefillName(for damagoType: DamagoType) -> String? {
        guard damagoType == state.currentDamagoType else { return nil }
        return state.currentDamagoName
    }

    func observePrefillName(for damagoType: DamagoType) -> AnyPublisher<String, Never> {
        guard let coupleID = state.coupleID else {
            return Empty().eraseToAnyPublisher()
        }
        let damagoID = "\(coupleID)_\(damagoType.rawValue)"
        return damagoRepository.observeDamagoSnapshot(damagoID: damagoID)
            .compactMap { try? $0.get().damagoName }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private func loadCurrentDamagoInfo() {
        Task {
            do {
                let userInfo = try await fetchUserInfoUseCase.execute()
                state.coupleID = userInfo.coupleID
                state.currentDamagoType = userInfo.damagoStatus.flatMap { $0.damagoType }
                state.currentDamagoName = userInfo.damagoStatus?.damagoName
            } catch {
                state.coupleID = nil
                state.currentDamagoType = nil
                state.currentDamagoName = nil
            }
        }
    }

    private func saveDamago(name: String) {
        guard let selectedDamago = state.selectedDamago else { return }
        
        Task {
            state.isLoading = true
            defer { state.isLoading = false }
            
            do {
                try await updateUserUseCase.execute(
                    nickname: nil,
                    anniversaryDate: nil,
                    useFCM: true,
                    useLiveActivity: true,
                    damagoName: name,
                    damagoType: selectedDamago
                )
                UserDefaults.standard.set(true, forKey: "isOnboardingCompleted")
                state.route = Pulse(.home)
            } catch {
                state.route = Pulse(.error(title: "오류", message: error.localizedDescription))
            }
        }
    }
    
    func selectDamago(_ damago: DamagoType) {
        state.selectedDamago = damago
    }
}
