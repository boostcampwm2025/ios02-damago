//
//  DamagoNamingPopupViewModelTests.swift
//  DamagoViewModelTests
//
//  Created by 김재영 on 2/2/26.
//

import Testing
import Combine
import Foundation
@testable import Damago

@MainActor
final class DamagoNamingPopupViewModelTests {
    private var cancellables = Set<AnyCancellable>()
    
    struct TestInput {
        let textChanged = PassthroughSubject<String, Never>()
        let confirmTapped = PassthroughSubject<Void, Never>()
        let cancelTapped = PassthroughSubject<Void, Never>()
        let updateInitialName = PassthroughSubject<String, Never>()
        
        var input: DamagoNamingPopupViewModel.Input {
            DamagoNamingPopupViewModel.Input(
                textChanged: textChanged.eraseToAnyPublisher(),
                confirmTapped: confirmTapped.eraseToAnyPublisher(),
                cancelTapped: cancelTapped.eraseToAnyPublisher(),
                updateInitialName: updateInitialName.eraseToAnyPublisher()
            )
        }
    }
    
    @Test("초기 이름이 없을 때 확인 버튼은 비활성화되어야 한다")
    func testConfirmButtonDisabledInitially() async {
        // Given
        let viewModel = DamagoNamingPopupViewModel(mode: .onboarding, initialName: nil)
        let testInput = TestInput()
        
        // When
        var lastState: DamagoNamingPopupViewModel.State?
        viewModel.transform(testInput.input)
            .sink { lastState = $0 }
            .store(in: &cancellables)
        
        // Then
        #expect(lastState?.isConfirmEnabled == false)
    }
    
    @Test("이름을 입력하면 확인 버튼이 활성화되어야 한다")
    func testConfirmButtonEnabledOnInput() async {
        // Given
        let viewModel = DamagoNamingPopupViewModel(mode: .onboarding)
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)
        
        // When & Then
        await confirmation("Confirm button should be enabled") { confirm in
            // Then: 구독 설정 (기대 결과)
            output.map { $0.isConfirmEnabled }
                .removeDuplicates()
                .filter { $0 == true }
                .sink { _ in confirm() }
                .store(in: &cancellables)
            
            // When: 입력 발생
            testInput.textChanged.send("다마고치")
            await Task.yield()
        }
    }
    
    @Test("공백만 입력하면 확인 버튼은 비활성화 상태여야 한다")
    func testConfirmButtonDisabledOnWhitespace() async {
        // Given
        let viewModel = DamagoNamingPopupViewModel(mode: .onboarding)
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)
        
        var lastEnabled: Bool?
        output.map { $0.isConfirmEnabled }
            .sink { lastEnabled = $0 }
            .store(in: &cancellables)
        
        // When
        testInput.textChanged.send("   ")
        await Task.yield()
        
        // Then
        #expect(lastEnabled == false)
    }
    
    @Test("변경 사항이 없을 때 취소하면 닫기 요청이 발생해야 한다")
    func testDismissOnCancelWithoutChanges() async {
        // Given
        let viewModel = DamagoNamingPopupViewModel(mode: .edit, initialName: "기존이름")
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)
        
        // When & Then
        await confirmation("Dismiss request should be emitted") { confirm in
            // Then
            output.compactMap { $0.dismissRequest?.value }
                .sink { _ in confirm() }
                .store(in: &cancellables)
            
            // When
            testInput.textChanged.send("기존이름")
            await Task.yield()
            testInput.cancelTapped.send()
            await Task.yield()
        }
    }
    
    @Test("변경 사항이 있을 때 취소하면 확인 요청이 발생해야 한다")
    func testConfirmationOnCancelWithChanges() async {
        // Given
        let viewModel = DamagoNamingPopupViewModel(mode: .edit, initialName: "기존이름")
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)
        
        // When & Then
        await confirmation("Confirmation request should be emitted") { confirm in
            // Then
            output.compactMap { $0.requestCancelConfirmation?.value }
                .sink { _ in confirm() }
                .store(in: &cancellables)
            
            // When
            testInput.textChanged.send("새로운이름")
            await Task.yield()
            testInput.cancelTapped.send()
            await Task.yield()
        }
    }
    
    @Test("초기 이름이 나중에 업데이트되면 텍스트 필드와 버튼 상태가 갱신되어야 한다")
    func testUpdateInitialName() async {
        // Given
        let viewModel = DamagoNamingPopupViewModel(mode: .onboarding, initialName: nil)
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)
        
        var currentName = ""
        var isEnabled = false
        
        output.map { $0.currentName }.sink { currentName = $0 }.store(in: &cancellables)
        output.map { $0.isConfirmEnabled }.sink { isEnabled = $0 }.store(in: &cancellables)
        
        // When
        testInput.updateInitialName.send("나중에온이름")
        await Task.yield()
        
        // Then
        #expect(currentName == "나중에온이름")
        #expect(isEnabled == true)
    }
}
