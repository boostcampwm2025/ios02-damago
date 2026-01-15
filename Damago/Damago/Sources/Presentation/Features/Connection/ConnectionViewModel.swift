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
    }

    struct State {
        var myCode = ""
        var opponentCode = ""
        var isLoading = true
        var route: Pulse<Route>?
        var errorMessage: String?
    }

    enum Route {
        case activity(url: URL)
    }

    @Published private var state = State()

    private var cancellables = Set<AnyCancellable>()

    init() { }

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
                self.state.opponentCode = code ?? ""
            }
            .store(in: &cancellables)

        input.shareButtonDidTap
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                if let url = self.generateURL() { self.state.route = .init(.activity(url: url)) }
                else { self.state.errorMessage = "공유에 실패했습니다." }
            }
            .store(in: &cancellables)


        return $state.eraseToAnyPublisher()
    }

    private func resolveMyCode() async {

    }

    private func copyCodeToPasteboard() {

    }

    private func generateURL() -> URL? {
        return URL(string: "https://example.com")
    }
}
