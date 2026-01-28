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
        let petSelected: AnyPublisher<DamagoType, Never>
        let confirmChangeTapped: AnyPublisher<Void, Never>
    }

    struct State {
        var pets: [DamagoType] = DamagoType.allCases
        var selectedPet: DamagoType?
        var isLoading: Bool = false
        var route: Pulse<Route>?
    }

    enum Route {
        case showChangeConfirmPopup(petType: DamagoType)
        case changeSuccess
        case error(title: String, message: String)
    }

    var pets: [DamagoType] { DamagoType.allCases }

    @Published private var state = State()
    private var cancellables = Set<AnyCancellable>()

    private let updateUserUseCase: UpdateUserUseCase
    private let fetchUserInfoUseCase: FetchUserInfoUseCase

    init(updateUserUseCase: UpdateUserUseCase, fetchUserInfoUseCase: FetchUserInfoUseCase) {
        self.updateUserUseCase = updateUserUseCase
        self.fetchUserInfoUseCase = fetchUserInfoUseCase
    }

    func transform(_ input: Input) -> AnyPublisher<State, Never> {
        input.petSelected
            .sink { [weak self] petType in
                if petType.isAvailable {
                    self?.state.selectedPet = petType
                    self?.state.route = Pulse(.showChangeConfirmPopup(petType: petType))
                } else {
                    self?.state.route = Pulse(.error(
                        title: "🙌 추후 업데이트 예정입니다!",
                        message: "더 좋은 서비스로 찾아뵙겠습니다."
                    ))
                }
            }
            .store(in: &cancellables)

        input.confirmChangeTapped
            .sink { [weak self] in
                self?.changePet()
            }
            .store(in: &cancellables)

        return $state.eraseToAnyPublisher()
    }

    private func changePet() {
        guard let selectedPet = state.selectedPet else { return }

        Task {
            state.isLoading = true
            defer { state.isLoading = false }

            do {
                let userInfo = try await fetchUserInfoUseCase.execute()
                let currentPetName = userInfo.petStatus?.petName ?? "다마고"

                try await updateUserUseCase.execute(
                    nickname: nil,
                    anniversaryDate: nil,
                    useFCM: nil,
                    useLiveActivity: nil,
                    petName: currentPetName,
                    petType: selectedPet.rawValue
                )
                state.route = Pulse(.changeSuccess)
            } catch {
                state.route = Pulse(.error(title: "오류", message: error.localizedDescription))
            }
        }
    }
}
