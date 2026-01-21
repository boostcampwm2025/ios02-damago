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
        var isConnected: Bool
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
        var userName: String = "사용자 A"
        var anniversaryDate: String = "2022.02.02."
        var dDay: Int = 100
        var isConnected: Bool = true
        var opponentName: String = "사용자 B"
        let privacyPolicyURL: URL? = URL(string: "https://example.com")
        let termsURL: URL? = URL(string: "https://example.com")
        var route: Pulse<Route>?

        var sectionState: SectionState {
            .init(
                isNotificationEnabled: isNotificationEnabled,
                isLiveActivityEnabled: isLiveActivityEnabled,
                userName: userName,
                anniversaryDate: anniversaryDate,
                dDay: 100,
                isConnected: isConnected,
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
    private let signOutUseCase: SignOutUseCase

    init(signOutUseCase: SignOutUseCase) {
        self.signOutUseCase = signOutUseCase
    }

    func transform(_ input: Input) -> AnyPublisher<State, Never> {
        input.viewDidLoad
            .sink { }
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
                NotificationCenter.default.post(name: .authenticationStateDidChange, object: nil)
            } catch {
                state.route = Pulse(.error(message: error.localizedDescription))
            }
        case .deleteAccount:
            break
        }
    }
}
