//
//  CollectionViewModel.swift
//  Damago
//
//  Created by loyH on 1/27/26.
//

import Combine
import Foundation

final class CollectionViewModel: ViewModel {
    let title = "컬렉션"

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let damagoSelected: AnyPublisher<DamagoType, Never>
        let confirmChangeTapped: AnyPublisher<Void, Never>
    }

    struct State {
        var damagos: [DamagoType] = DamagoType.allCases
        var selectedDamago: DamagoType?
        var currentDamagoType: DamagoType?
        var ownedDamagos: [DamagoType: Int] = [:]
        var isLoading: Bool = false
        var route: Pulse<Route>?
    }

    enum Route: Equatable {
        case showChangeConfirmPopup(damagoType: DamagoType)
        case error(title: String, message: String)
    }

    var damagos: [DamagoType] { DamagoType.allCases }

    @Published private var state = State()
    private var cancellables = Set<AnyCancellable>()

    private let updateUserUseCase: UpdateUserUseCase
    private let fetchUserInfoUseCase: FetchUserInfoUseCase
    private let globalStore: GlobalStoreProtocol

    init(
        updateUserUseCase: UpdateUserUseCase,
        fetchUserInfoUseCase: FetchUserInfoUseCase,
        globalStore: GlobalStoreProtocol
    ) {
        self.updateUserUseCase = updateUserUseCase
        self.fetchUserInfoUseCase = fetchUserInfoUseCase
        self.globalStore = globalStore
    }

    func transform(_ input: Input) -> AnyPublisher<State, Never> {
        input.viewDidLoad
            .sink { [weak self] in
                self?.loadCurrentDamago()
            }
            .store(in: &cancellables)

        globalStore.globalState
            .map { $0.ownedDamagos ?? [:] }
            .assign(to: \.state.ownedDamagos, on: self)
            .store(in: &cancellables)

        input.damagoSelected
            .sink { [weak self] damagoType in
                guard let self = self else { return }
                if damagoType == self.state.currentDamagoType { return }
                if self.state.ownedDamagos.keys.contains(damagoType) {
                    self.state.selectedDamago = damagoType
                    self.state.route = Pulse(.showChangeConfirmPopup(damagoType: damagoType))
                } else {
                    self.state.route = Pulse(.error(
                        title: "미보유 다마고입니다.",
                        message: "코인을 모아 상점해서 획득해보세요!"
                    ))
                }
            }
            .store(in: &cancellables)

        input.confirmChangeTapped
            .sink { [weak self] in
                self?.changeDamago()
            }
            .store(in: &cancellables)

        return $state.eraseToAnyPublisher()
    }

    private func changeDamago() {
        guard let selectedDamago = state.selectedDamago else { return }

        state.isLoading = true
        Task {
            defer { state.isLoading = false }

            do {
                try await updateUserUseCase.execute(
                    nickname: nil,
                    anniversaryDate: nil,
                    useFCM: nil,
                    useLiveActivity: nil,
                    damagoName: nil,
                    damagoType: selectedDamago
                )
                state.currentDamagoType = selectedDamago
            } catch {
                state.route = Pulse(.error(title: "오류", message: error.localizedDescription))
            }
        }
    }

    private func loadCurrentDamago() {
        Task {
            do {
                let userInfo = try await fetchUserInfoUseCase.execute()
                state.currentDamagoType = userInfo.damagoStatus.flatMap { $0.damagoType }
            } catch {
                state.currentDamagoType = nil
            }
        }
    }
}
