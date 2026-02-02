//
//  DamagoNamingPopupViewModel.swift
//  Damago
//
//  Created by 김재영 on 2/2/26.
//

import Foundation
import Combine

final class DamagoNamingPopupViewModel: ViewModel {
    enum Mode {
        case onboarding
        case edit
        
        var titleText: String {
            switch self {
            case .onboarding: return "마음을 담아 이름을 선물해주세요."
            case .edit: return "이름을 바꿔볼까요?"
            }
        }
        
        var placeholderText: String {
            switch self {
            case .onboarding: return "이름 입력"
            case .edit: return "새 이름 입력"
            }
        }
        
        var confirmButtonTitle: String {
            switch self {
            case .onboarding: return "만나서 반가워!"
            case .edit: return "변경하기"
            }
        }
        
        var confirmButtonDisabledTitle: String {
            "이름을 알려줘!"
        }
    }
    
    struct Input {
        let textChanged: AnyPublisher<String, Never>
        let confirmTapped: AnyPublisher<Void, Never>
        let cancelTapped: AnyPublisher<Void, Never>
        let updateInitialName: AnyPublisher<String, Never>
    }
    
    struct State: Equatable {
        var isConfirmEnabled = false
        var currentName = ""
        var dismissRequest: Pulse<Void>?
        var confirmAction: Pulse<String>?
        var requestCancelConfirmation: Pulse<Void>?
    }
    
    let mode: Mode
    private var initialName: String
    
    @Published private var state = State()
    private var cancellables = Set<AnyCancellable>()
    
    init(mode: Mode, initialName: String? = nil) {
        self.mode = mode
        let trimmed = initialName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.initialName = trimmed
        self.state.currentName = trimmed
        self.state.isConfirmEnabled = !trimmed.isEmpty
    }
    
    func transform(_ input: Input) -> AnyPublisher<State, Never> {
        input.textChanged
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.handleTextChanged(text)
            }
            .store(in: &cancellables)
            
        input.updateInitialName
            .receive(on: DispatchQueue.main)
            .sink { [weak self] name in
                self?.handleUpdateInitialName(name)
            }
            .store(in: &cancellables)
            
        input.confirmTapped
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.handleConfirm()
            }
            .store(in: &cancellables)
            
        input.cancelTapped
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.handleCancel()
            }
            .store(in: &cancellables)
        
        return $state.eraseToAnyPublisher()
    }
    
    private func handleTextChanged(_ text: String) {
        state.currentName = text
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        state.isConfirmEnabled = !trimmed.isEmpty
    }
    
    private func handleUpdateInitialName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.initialName = trimmed
        
        if state.currentName.isEmpty {
            state.currentName = trimmed
            state.isConfirmEnabled = !trimmed.isEmpty
        }
    }
    
    private func handleConfirm() {
        guard state.isConfirmEnabled else { return }
        let trimmed = state.currentName.trimmingCharacters(in: .whitespacesAndNewlines)
        state.confirmAction = Pulse(trimmed)
    }
    
    private func handleCancel() {
        let currentTrimmed = state.currentName.trimmingCharacters(in: .whitespacesAndNewlines)
        if currentTrimmed.isEmpty || currentTrimmed == initialName {
            state.dismissRequest = Pulse(())
        } else {
            state.requestCancelConfirmation = Pulse(())
        }
    }
}
