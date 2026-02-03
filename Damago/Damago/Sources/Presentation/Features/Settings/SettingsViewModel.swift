//
//  SettingsViewModel.swift
//  Damago
//
//  Created by 박현수 on 1/20/26.
//

import Combine
import Foundation
import UserNotifications
import ActivityKit

final class SettingsViewModel: ViewModel {
    struct SectionState: Equatable {
        var isNotificationEnabled: Bool
        var isLiveActivityEnabled: Bool
        var userName: String
        var anniversaryDate: String
        var dDay: Int
        var opponentName: String
        var damagoBackgroundOption: DamagoBackgroundColorOption
        let privacyPolicyURL: URL?
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let toggleChanged: AnyPublisher<(ToggleType, Bool), Never>
        let itemSelected: AnyPublisher<SettingsItem, Never>
        let damagoBackgroundChanged: AnyPublisher<DamagoBackgroundColorOption, Never>
        let alertActionDidConfirm: AnyPublisher<AlertActionType, Never>
    }

    struct State {
        var isNotificationEnabled: Bool = false
        var isLiveActivityEnabled: Bool = false
        var userName: String = ""
        var anniversaryDate: String = ""
        var dDay: Int = 0
        var opponentName: String = ""
        var damagoBackgroundOption: DamagoBackgroundColorOption = .defaultOption
        let privacyPolicyURL: URL? = URL(string: "https://strong-wren-d65.notion.site/Damago-2fce20acc2ad8056a0f8e16c8f0798b4")
        var route: Pulse<Route>?

        var notificationCurrentPermission: Bool = false
        var activityCurrentPermission: Bool = false

        var sectionState: SectionState {
            .init(
                isNotificationEnabled: isNotificationEnabled,
                isLiveActivityEnabled: isLiveActivityEnabled,
                userName: userName,
                anniversaryDate: anniversaryDate,
                dDay: dDay,
                opponentName: opponentName,
                damagoBackgroundOption: damagoBackgroundOption,
                privacyPolicyURL: privacyPolicyURL
            )
        }
    }

    enum Route {
        case editProfile
        case connection
        case webLink(url: URL?)
        case damagoBackgroundPicker(current: DamagoBackgroundColorOption)
        case alert(type: AlertActionType)
        case error(message: String)
        case openSettings
    }

    @Published private var state = State()
    private var cancellables = Set<AnyCancellable>()
    private let globalStore: GlobalStoreProtocol
    private let signOutUseCase: SignOutUseCase
    private let withdrawUseCase: WithdrawUseCase
    private let updateUserUseCase: UpdateUserUseCase

    init(
        globalStore: GlobalStoreProtocol,
        signOutUseCase: SignOutUseCase,
        withdrawUseCase: WithdrawUseCase,
        updateUserUseCase: UpdateUserUseCase
    ) {
        self.globalStore = globalStore
        self.signOutUseCase = signOutUseCase
        self.updateUserUseCase = updateUserUseCase
        self.withdrawUseCase = withdrawUseCase
    }

    func transform(_ input: Input) -> AnyPublisher<State, Never> {
        input.viewDidLoad
            .sink { [weak self] in
                self?.loadDamagoBackgroundOption()
                self?.refreshPermissionsAndBind()
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

        input.damagoBackgroundChanged
            .sink { [weak self] option in
                self?.handleDamagoBackgroundChange(option)
            }
            .store(in: &cancellables)

        input.alertActionDidConfirm
            .sink { [weak self] type in
                self?.performAction(type)
            }
            .store(in: &cancellables)

        return $state.eraseToAnyPublisher()
    }

    private func refreshPermissionsAndBind() {
        Task {
            let notiSettings = await UNUserNotificationCenter.current().notificationSettings()
            state.notificationCurrentPermission = (notiSettings.authorizationStatus == .authorized)
            state.activityCurrentPermission = ActivityAuthorizationInfo().areActivitiesEnabled
            bindGlobalState()
        }
    }

    private func bindGlobalState() {
        globalStore.globalState
            .compactMapForUI { [weak self] state -> Bool? in
                guard let self = self else { return nil }
                return state.useFCM && self.state.notificationCurrentPermission
            }
            .sink { [weak self] in self?.state.isNotificationEnabled = $0 }
            .store(in: &cancellables)

        globalStore.globalState
            .compactMapForUI { [weak self] state -> Bool? in
                guard let self = self else { return nil }
                return state.useLiveActivity && self.state.activityCurrentPermission
            }
            .sink { [weak self] in self?.state.isLiveActivityEnabled = $0 }
            .store(in: &cancellables)

        globalStore.globalState
            .compactMapForUI { $0.nickname }
            .sink { [weak self] in self?.state.userName = $0 }
            .store(in: &cancellables)

        globalStore.globalState
            .compactMapForUI { $0.opponentName }
            .sink { [weak self] name in
                self?.state.opponentName = name
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
        case .notification: state.isNotificationEnabled = isOn
        case .liveActivity: state.isLiveActivityEnabled = isOn
        }

        Task {
            if isOn {
                let isAuthorized = await checkAndRequestPermission(type: type)
                if isAuthorized {
                    updateLocalPermission(type: type, value: true)
                    await updateServerSetting(type: type, isOn: true)
                } else {
                    self.revertToggle(type: type, targetState: false)
                    self.state.route = Pulse(.alert(type: .openSettings))
                }
            } else {
                await updateServerSetting(type: type, isOn: false)
            }
        }
    }

    private func updateLocalPermission(type: ToggleType, value: Bool) {
        switch type {
        case .notification: state.notificationCurrentPermission = value
        case .liveActivity: state.activityCurrentPermission = value
        }
    }

    private func checkAndRequestPermission(type: ToggleType) async -> Bool {
        switch type {
        case .notification:
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()

            if settings.authorizationStatus == .notDetermined {
                return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            }
            return settings.authorizationStatus == .authorized

        case .liveActivity:
            return ActivityAuthorizationInfo().areActivitiesEnabled
        }
    }

    private func updateServerSetting(type: ToggleType, isOn: Bool) async {
        do {
            switch type {
            case .notification:
                try await updateUserUseCase.execute(
                    nickname: nil,
                    anniversaryDate: nil,
                    useFCM: isOn,
                    useLiveActivity: nil,
                    damagoName: nil,
                    damagoType: nil
                )
            case .liveActivity:
                try await updateUserUseCase.execute(
                    nickname: nil,
                    anniversaryDate: nil,
                    useFCM: nil,
                    useLiveActivity: isOn,
                    damagoName: nil,
                    damagoType: nil
                )
            }
        } catch {
            self.revertToggle(type: type, targetState: !isOn)
        }
    }

    private func revertToggle(type: ToggleType, targetState: Bool) {
        switch type {
        case .notification: state.isNotificationEnabled = targetState
        case .liveActivity: state.isLiveActivityEnabled = targetState
        }
    }

    private func handleSelection(item: SettingsItem) {
        switch item {
        case .profile:
            state.route = Pulse(.editProfile)
        case .relationship:
            state.route = Pulse(.connection)
        case .damagoBackground(let option):
            state.route = Pulse(.damagoBackgroundPicker(current: option))
        case .link(_, let url):
            state.route = Pulse(.webLink(url: url))
        case .action(let type):
            handleAccountAction(type)
        default:
            break
        }
    }

    private func loadDamagoBackgroundOption() {
        let defaults = AppGroupUserDefaults.sharedDefaults()
        let rawValue = defaults.string(forKey: AppGroupUserDefaults.damagoBackgroundColorKey)
        state.damagoBackgroundOption = DamagoBackgroundColorOption(rawValue: rawValue ?? "")
            ?? DamagoBackgroundColorOption.defaultOption
    }

    private func handleDamagoBackgroundChange(_ option: DamagoBackgroundColorOption) {
        let defaults = AppGroupUserDefaults.sharedDefaults()
        defaults.set(option.rawValue, forKey: AppGroupUserDefaults.damagoBackgroundColorKey)
        state.damagoBackgroundOption = option
        LiveActivityManager.shared.synchronizeActivity()
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
                UserDefaults.standard.set(false, forKey: "isOnboardingCompleted")
                LiveActivityManager.shared.synchronizeActivity()
                NotificationCenter.default.post(name: .authenticationStateDidChange, object: nil)
            } catch {
                state.route = Pulse(.error(message: error.userFriendlyMessage))
            }
        case .deleteAccount:
            Task {
                do {
                    try await withdrawUseCase.execute()
                    UserDefaults.standard.set(false, forKey: "isOnboardingCompleted")
                    NotificationCenter.default.post(name: .authenticationStateDidChange, object: nil)
                } catch {
                    state.route = Pulse(.error(message: error.localizedDescription))
                }
            }
        case .openSettings:
            state.route = Pulse(.openSettings)
        }
    }
}
