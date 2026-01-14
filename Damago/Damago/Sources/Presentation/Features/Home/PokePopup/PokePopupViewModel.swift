//
//  PokePopupViewModel.swift
//  Damago
//
//  Created by loyH on 1/14/26.
//

import Combine
import Foundation

final class PokePopupViewModel: ViewModel {
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let shortcutSelected: AnyPublisher<String, Never>
        let textChanged: AnyPublisher<String, Never>
        let sendButtonTapped: AnyPublisher<Void, Never>
        let cancelButtonTapped: AnyPublisher<Void, Never>
    }
    
    struct State {
        let shortcuts: [PokeShortcut]
        let currentText: String
        
        init(shortcuts: [PokeShortcut] = [], currentText: String = "") {
            self.shortcuts = shortcuts
            self.currentText = currentText
        }
    }
    
    @Published private var state = State()
    private var cancellables = Set<AnyCancellable>()
    private let shortcutRepository: PokeShortcutRepositoryProtocol
    
    var onMessageSelected: ((String) -> Void)?
    var onCancel: (() -> Void)?
    
    init(shortcutRepository: PokeShortcutRepositoryProtocol) {
        self.shortcutRepository = shortcutRepository
    }
    
    func transform(_ input: Input) -> AnyPublisher<State, Never> {
        input.viewDidLoad
            .sink { [weak self] _ in
                self?.loadShortcuts()
            }
            .store(in: &cancellables)
        
        input.shortcutSelected
            .sink { [weak self] message in
                guard let self = self else { return }
                self.state = State(shortcuts: self.state.shortcuts, currentText: message)
            }
            .store(in: &cancellables)
        
        input.textChanged
            .sink { [weak self] text in
                guard let self = self else { return }
                self.state = State(shortcuts: self.state.shortcuts, currentText: text)
            }
            .store(in: &cancellables)
        
        input.sendButtonTapped
            .sink { [weak self] _ in
                self?.handleSend()
            }
            .store(in: &cancellables)
        
        input.cancelButtonTapped
            .sink { [weak self] _ in
                self?.onCancel?()
            }
            .store(in: &cancellables)
        
        return $state.eraseToAnyPublisher()
    }
    
    private func loadShortcuts() {
        state = State(shortcuts: shortcutRepository.shortcuts, currentText: state.currentText)
    }
    
    private func handleSend() {
        let message = state.currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !message.isEmpty {
            onMessageSelected?(message)
        }
    }
}
