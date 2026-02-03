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
        let hasChanges: Bool
        
        init(
            shortcuts: [PokeShortcut] = [],
            currentText: String = "",
            isEditing: Bool = false,
            hasChanges: Bool = false
        ) {
            self.shortcuts = shortcuts
            self.currentText = currentText
            self.isEditing = isEditing
            self.hasChanges = hasChanges
        }
    }
    
    @Published private var state = State()
    private var cancellables = Set<AnyCancellable>()
    private let getPokeShortcutsUseCase: GetPokeShortcutsUseCase
    private let updatePokeShortcutUseCase: UpdatePokeShortcutUseCase
    private var originalShortcuts: [PokeShortcut] = [] // 편집 모드 진입 시 원본 데이터 저장
    
    var onMessageSelected: ((String) -> Void)?
    var onCancel: (() -> Void)?
    var onRequestCancelConfirmation: ((@escaping () -> Void) -> Void)?
    
    init(
        getPokeShortcutsUseCase: GetPokeShortcutsUseCase,
        updatePokeShortcutUseCase: UpdatePokeShortcutUseCase
    ) {
        self.getPokeShortcutsUseCase = getPokeShortcutsUseCase
        self.updatePokeShortcutUseCase = updatePokeShortcutUseCase
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
                guard let self = self else { return }
                
                // 변경 사항이 있을 때만 확인 알럿 표시
                if self.state.hasChanges {
                    self.requestCancelConfirmation()
                } else {
                    // 변경 사항이 없으면 바로 취소
                    if self.state.isEditing {
                        self.exitEditMode()
                    } else {
                        self.onCancel?()
                    }
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
        updateState(shortcuts: getPokeShortcutsUseCase.execute())
    }
    
    private func handleSend() {
        guard !state.isEditing else { return }
        let message = state.currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }

        onMessageSelected?(message)
    }
    
    private func requestCancelConfirmation() {
        onRequestCancelConfirmation? { [weak self] in
            if self?.state.isEditing == true {
                // 편집 모드였다면 편집 모드 종료
                self?.exitEditMode()
            } else {
                // 일반 모드였다면 팝업 닫기
                self?.onCancel?()
            }
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
        let newShortcuts = shortcuts ?? state.shortcuts
        let newCurrentText = currentText ?? state.currentText
        let newIsEditing = isEditing ?? state.isEditing
        
        // 변경 사항 확인
        let hasChanges: Bool
        if newIsEditing {
            // 편집 모드: 원본과 비교
            hasChanges = newShortcuts != originalShortcuts
        } else {
            // 일반 모드: 텍스트가 비어있지 않은지 확인
            hasChanges = !newCurrentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        state = State(
            shortcuts: newShortcuts,
            currentText: newCurrentText,
            isEditing: newIsEditing,
            hasChanges: hasChanges
        )
    }
    
    private func saveShortcuts() {
        // 각 shortcut을 개별적으로 업데이트
        state.shortcuts.enumerated().forEach { index, shortcut in
            updatePokeShortcutUseCase.execute(at: index, shortcut: shortcut)
        }
        updateState(isEditing: false)
    }
}
