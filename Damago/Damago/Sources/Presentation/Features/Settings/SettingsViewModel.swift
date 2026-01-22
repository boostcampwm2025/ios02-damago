//
//  SettingsViewModel.swift
//  Damago
//
//  Created by 박현수 on 1/20/26.
//

import Combine
import Foundation

final class SettingsViewModel: ViewModel {
    struct SectionState: Equatable {
        var isNotificationEnabled: Bool
        var isLiveActivityEnabled: Bool
        var userName: String
        var anniversaryDate: String
        var dDay: Int
        var opponentName: String
        let privacyPolicyURL: URL?
        let termsURL: URL?
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let toggleChanged: AnyPublisher<(ToggleType, Bool), Never>
        let itemSelected: AnyPublisher<SettingsItem, Never>
        let alertActionDidConfirm: AnyPublisher<AlertActionType, Never>
    }

    struct State {
        var isNotificationEnabled: Bool = false
        var isLiveActivityEnabled: Bool = false
        var userName: String = ""
        var anniversaryDate: String = ""
        var dDay: Int = 0
        var opponentName: String = ""
        let privacyPolicyURL: URL? = URL(string: "https://example.com")
        let termsURL: URL? = URL(string: "https://example.com")
        var route: Pulse<Route>?

        var sectionState: SectionState {
            .init(
                isNotificationEnabled: isNotificationEnabled,
                isLiveActivityEnabled: isLiveActivityEnabled,
                userName: userName,
                anniversaryDate: anniversaryDate,
                dDay: dDay,
                opponentName: opponentName,
                privacyPolicyURL: privacyPolicyURL,
                termsURL: termsURL
            )
        }
    }

    enum Route {
        case editProfile
        case webLink(url: URL?)
        case alert(type: AlertActionType)
        case error(message: String)
    }

    @Published private var state = State()
    private var cancellables = Set<AnyCancellable>()
    private let globalStore: GlobalStoreProtocol
    private let signOutUseCase: SignOutUseCase
    private let withdrawUseCase: WithdrawUseCase

    init(
        globalStore: GlobalStoreProtocol,
        signOutUseCase: SignOutUseCase,
        withdrawUseCase: WithdrawUseCase
    ) {
        self.globalStore = globalStore
        self.signOutUseCase = signOutUseCase
        self.withdrawUseCase = withdrawUseCase
    }

    func transform(_ input: Input) -> AnyPublisher<State, Never> {
        input.viewDidLoad
            .sink { [weak self] in
                self?.bindGlobalState()
            }
            .store(in: &cancellables)

        input.toggleChanged
            .sink { [weak self] type, isOn in
                self?.handleToggle(type: type, isOn: isOn)
            }
            .store(in: &cancellables)

        input.itemSelected
            .sink { [weak self] item in
                self?.handleSelection(item: item)
            }
            .store(in: &cancellables)

        input.alertActionDidConfirm
            .sink { [weak self] type in
                self?.performAction(type)
            }
            .store(in: &cancellables)

        return $state.eraseToAnyPublisher()
    }

    private func bindGlobalState() {
        globalStore.globalState
            .compactMapForUI { $0.useFCM }
            .sink { [weak self] in self?.state.isNotificationEnabled = $0 }
            .store(in: &cancellables)

        globalStore.globalState
            .compactMapForUI { $0.useLiveActivity }
            .sink { [weak self] in self?.state.isLiveActivityEnabled = $0 }
            .store(in: &cancellables)

        globalStore.globalState
            .compactMapForUI { $0.nickname }
            .sink { [weak self] in self?.state.userName = $0 }
            .store(in: &cancellables)

        globalStore.globalState
            .mapForUI { $0.opponentName }
            .sink { [weak self] name in
                if let name {
                    self?.state.opponentName = name
                } else {
                    self?.state.opponentName = ""
                }
            }
            .store(in: &cancellables)

        globalStore.globalState
            .compactMap { $0.anniversaryDate }
            .sink { [weak self] date in
                self?.state.anniversaryDate = date.toString()
                self?.state.dDay = date.daysBetween(to: Date()) ?? 0
            }
            .store(in: &cancellables)
    }

    private func handleToggle(type: ToggleType, isOn: Bool) {
        switch type {
        case .notification:
            state.isNotificationEnabled = isOn
        case .liveActivity:
            state.isLiveActivityEnabled = isOn
        }
    }

    private func handleSelection(item: SettingsItem) {
        switch item {
        case .profile:
            state.route = Pulse(.editProfile)
        case .link(_, let url):
            state.route = Pulse(.webLink(url: url))
        case .action(let type):
            handleAccountAction(type)
        default:
            break
        }
    }

    private func handleAccountAction(_ type: AlertActionType) {
        state.route = Pulse(.alert(type: type))
    }

    private func performAction(_ type: AlertActionType) {
        switch type {
        case .logout:
            do {
                try signOutUseCase.execute()
                // 로그아웃 시 커플 연결 상태 초기화 및 Live Activity 종료
                UserDefaults.standard.setValue(false, forKey: "isConnected")
                LiveActivityManager.shared.synchronizeActivity()
                NotificationCenter.default.post(name: .authenticationStateDidChange, object: nil)
            } catch {
                state.route = Pulse(.error(message: error.localizedDescription))
            }
        case .deleteAccount:
            Task {
                do {
                    try await withdrawUseCase.execute()
                    NotificationCenter.default.post(name: .authenticationStateDidChange, object: nil)
                } catch {
                    state.route = Pulse(.error(message: error.localizedDescription))
                }
            }
        }
    }
}
