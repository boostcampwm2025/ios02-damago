//
//  ConnectionViewModel.swift
//  Damago
//
//  Created by 박현수 on 1/15/26.
//

import Combine
import Foundation

final class ConnectionViewModel: ViewModel {
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let copyButtonDidTap: AnyPublisher<Void, Never>
        let textfieldValueDidChange: AnyPublisher<String, Never>
        let shareButtonDidTap: AnyPublisher<Void, Never>
        let connectButtonDidTap: AnyPublisher<Void, Never>
    }

    struct State {
        var myCode = ""
        var opponentCode = ""
        var route: Pulse<Route>?
        var pasteboardCode: Pulse<String>?
        var isLoading = false

        var isConnectButtonEnabled: Bool { !opponentCode.isEmpty && !isLoading }
    }

    enum Route {
        case alert(message: String)
        case activity(url: URL)
        case home
    }

    @Published private var state: State

    private var cancellables = Set<AnyCancellable>()

    private let fetchCodeUseCase: FetchCodeUseCase
    private let connectCoupleUseCase: ConnectCoupleUseCase

    init(
        fetchCodeUseCase: FetchCodeUseCase,
        connectCoupleUseCase: ConnectCoupleUseCase,
        opponentCode: String? = nil
    ) {
        self.fetchCodeUseCase = fetchCodeUseCase
        self.connectCoupleUseCase = connectCoupleUseCase

        if let opponentCode {
            var state = State()
            state.opponentCode = opponentCode
            self.state = state
        } else {
            state = State()
        }
    }

    func transform(_ input: Input) -> Output {
        input.viewDidLoad
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                Task { await self.resolveMyCode() }
            }
            .store(in: &cancellables)

        input.copyButtonDidTap
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                self.copyCodeToPasteboard()
            }
            .store(in: &cancellables)

        input.textfieldValueDidChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] code in
                guard let self else { return }
                self.state.opponentCode = code
            }
            .store(in: &cancellables)

        input.shareButtonDidTap
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                if let url = self.generateURL() {
                    self.state.route = .init(.activity(url: url))
                } else {
                    self.state.route = .init(.alert(message: "공유에 실패했습니다."))
                }
            }
            .store(in: &cancellables)

        input.connectButtonDidTap
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                Task { await self.connect() }
            }
            .store(in: &cancellables)

        return $state.eraseToAnyPublisher()
    }

    private func resolveMyCode() async {
        do {
            let code = try await fetchCodeUseCase.execute()
            state.myCode = code
        } catch {
            state.route = .init(.alert(message: error.userFriendlyMessage))
        }
    }

    private func connect() async {
        state.isLoading = true
        
        do {
            try await connectCoupleUseCase.execute(code: state.opponentCode)
            UserDefaults.standard.setValue(true, forKey: "isConnected")
            
            // 커플 연결 성공 시 Live Activity 시작
            LiveActivityManager.shared.synchronizeActivity()
            
            state.isLoading = false
            state.route = .init(.home)
        } catch {
            state.isLoading = false
            state.route = .init(.alert(message: error.userFriendlyMessage))
        }
    }

    private func copyCodeToPasteboard() {
        guard !state.myCode.isEmpty else { return }
        state.pasteboardCode = .init(state.myCode)
    }

    private func generateURL() -> URL? {
        guard !state.myCode.isEmpty else { return nil }

        var components = URLComponents()
        components.scheme = "damago"
        components.host = "connection"
        components.queryItems = [
            URLQueryItem(name: "code", value: state.myCode)
        ]

        return components.url
    }
}
