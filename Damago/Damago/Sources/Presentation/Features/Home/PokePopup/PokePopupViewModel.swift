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
        let editButtonTapped: AnyPublisher<Void, Never>
        let shortcutSummaryChanged: AnyPublisher<(index: Int, summary: String), Never>
        let shortcutMessageChanged: AnyPublisher<(index: Int, message: String), Never>
        let saveButtonTapped: AnyPublisher<Void, Never>
    }
    
    struct State {
        let shortcuts: [PokeShortcut]
        let currentText: String
        let isEditing: Bool
        
        init(shortcuts: [PokeShortcut] = [], currentText: String = "", isEditing: Bool = false) {
            self.shortcuts = shortcuts
            self.currentText = currentText
            self.isEditing = isEditing
        }
    }
    
    @Published private var state = State()
    private var cancellables = Set<AnyCancellable>()
    private let shortcutRepository: PokeShortcutRepositoryProtocol
    private var originalShortcuts: [PokeShortcut] = [] // 편집 모드 진입 시 원본 데이터 저장
    
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
                self?.updateState(currentText: message)
            }
            .store(in: &cancellables)
        
        input.textChanged
            .sink { [weak self] text in
                self?.updateState(currentText: text)
            }
            .store(in: &cancellables)
        
        input.sendButtonTapped
            .sink { [weak self] _ in
                self?.handleSend()
            }
            .store(in: &cancellables)
        
        input.cancelButtonTapped
            .sink { [weak self] _ in
                if self?.state.isEditing == true {
                    self?.exitEditMode()
                } else {
                    self?.onCancel?()
                }
            }
            .store(in: &cancellables)
        
        input.editButtonTapped
            .sink { [weak self] _ in
                self?.toggleEditMode()
            }
            .store(in: &cancellables)
        
        input.shortcutSummaryChanged
            .sink { [weak self] index, summary in
                self?.updateShortcutSummary(at: index, summary: summary)
            }
            .store(in: &cancellables)
        
        input.shortcutMessageChanged
            .sink { [weak self] index, message in
                self?.updateShortcutMessage(at: index, message: message)
            }
            .store(in: &cancellables)
        
        input.saveButtonTapped
            .sink { [weak self] _ in
                self?.saveShortcuts()
            }
            .store(in: &cancellables)
        
        return $state.eraseToAnyPublisher()
    }
    
    private func loadShortcuts() {
        updateState(shortcuts: shortcutRepository.shortcuts)
    }
    
    private func handleSend() {
        guard !state.isEditing else { return }
        let message = state.currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !message.isEmpty {
            onMessageSelected?(message)
        }
    }
    
    private func toggleEditMode() {
        let willEnterEditMode = !state.isEditing
        if willEnterEditMode {
            // 편집 모드로 들어갈 때 원본 데이터 저장
            originalShortcuts = state.shortcuts
        }
        updateState(isEditing: !state.isEditing)
    }
    
    private func exitEditMode() {
        // 저장된 원본 데이터로 복원
        updateState(shortcuts: originalShortcuts, isEditing: false)
    }
    
    private func updateShortcutSummary(at index: Int, summary: String) {
        updateShortcut(at: index) { shortcut in
            PokeShortcut(summary: summary, message: shortcut.message)
        }
    }
    
    private func updateShortcutMessage(at index: Int, message: String) {
        updateShortcut(at: index) { shortcut in
            PokeShortcut(summary: shortcut.summary, message: message)
        }
    }
    
    private func updateShortcut(at index: Int, transform: (PokeShortcut) -> PokeShortcut) {
        guard index < state.shortcuts.count else { return }
        var updatedShortcuts = state.shortcuts
        updatedShortcuts[index] = transform(updatedShortcuts[index])
        updateState(shortcuts: updatedShortcuts)
    }
    
    private func updateState(shortcuts: [PokeShortcut]? = nil, currentText: String? = nil, isEditing: Bool? = nil) {
        state = State(
            shortcuts: shortcuts ?? state.shortcuts,
            currentText: currentText ?? state.currentText,
            isEditing: isEditing ?? state.isEditing
        )
    }
    
    private func saveShortcuts() {
        // 각 shortcut을 개별적으로 업데이트
        state.shortcuts.enumerated().forEach { index, shortcut in
            shortcutRepository.updateShortcut(at: index, shortcut: shortcut)
        }
        updateState(isEditing: false)
    }
}
