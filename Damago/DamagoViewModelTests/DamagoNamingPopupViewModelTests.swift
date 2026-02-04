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
            let stream = AsyncStream<Void> { continuation in
                output.map { $0.isConfirmEnabled }
                    .removeDuplicates()
                    .filter { $0 == true }
                    .sink { _ in continuation.yield() }
                    .store(in: &cancellables)
            }
            var iterator = stream.makeAsyncIterator()
            
            testInput.textChanged.send("다마고치")
            
            await iterator.next()
            confirm()
        }
    }
    
    @Test("공백만 입력하면 확인 버튼은 비활성화 상태여야 한다")
    func testConfirmButtonDisabledOnWhitespace() async {
        // Given
        let viewModel = DamagoNamingPopupViewModel(mode: .onboarding)
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)
        
        // When & Then
        await confirmation("Confirm button should be disabled") { confirm in
            let stream = AsyncStream<Bool> { continuation in
                output.map { $0.isConfirmEnabled }
                    .removeDuplicates()
                    .sink { isEnabled in continuation.yield(isEnabled) }
                    .store(in: &cancellables)
            }
            var iterator = stream.makeAsyncIterator()
            
            // 1. 유효한 이름 입력
            testInput.textChanged.send("ValidName")
            var isEnabled = await iterator.next()
            while isEnabled == false {
                isEnabled = await iterator.next()
            }
            
            // 2. 공백 입력
            testInput.textChanged.send("   ")
            
            isEnabled = await iterator.next()
            while isEnabled == true {
                if let next = await iterator.next() {
                    isEnabled = next
                } else {
                    break
                }
            }
            
            if isEnabled == false {
                confirm()
            }
        }
    }
    
    @Test("변경 사항이 없을 때 취소하면 닫기 요청이 발생해야 한다")
    func testDismissOnCancelWithoutChanges() async {
        // Given
        let viewModel = DamagoNamingPopupViewModel(mode: .edit, initialName: "기존이름")
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)
        
        // When & Then
        await confirmation("Dismiss request should be emitted") { confirm in
            let stream = AsyncStream<Void> { continuation in
                output.compactMap { $0.dismissRequest?.value }
                    .sink { _ in continuation.yield() }
                    .store(in: &cancellables)
            }
            var iterator = stream.makeAsyncIterator()
            
            // 1. 초기값 설정 (입력)
            testInput.textChanged.send("기존이름")
            
            // 2. 취소 버튼 탭
            testInput.cancelTapped.send()
            
            // 3. 대기
            await iterator.next()
            confirm()
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
            let stream = AsyncStream<Void> { continuation in
                output.compactMap { $0.requestCancelConfirmation?.value }
                    .sink { _ in continuation.yield() }
                    .store(in: &cancellables)
            }
            var iterator = stream.makeAsyncIterator()
            
            // 1. 이름 변경
            testInput.textChanged.send("새로운이름")
            
            // 2. 취소 버튼 탭
            testInput.cancelTapped.send()
            
            // 3. 대기
            await iterator.next()
            confirm()
        }
    }
    
    @Test("초기 이름이 나중에 업데이트되면 텍스트 필드와 버튼 상태가 갱신되어야 한다")
    func testUpdateInitialName() async {
        // Given
        let viewModel = DamagoNamingPopupViewModel(mode: .onboarding, initialName: nil)
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)
        
        // When & Then
        await confirmation("Name and button state should be updated", expectedCount: 2) { confirm in
            // 두 개의 스트림을 각각 생성
            let nameStream = AsyncStream<Void> { continuation in
                output.map { $0.currentName }
                    .filter { $0 == "나중에온이름" }
                    .sink { _ in continuation.yield() }
                    .store(in: &cancellables)
            }
            var nameIterator = nameStream.makeAsyncIterator()
            
            let buttonStream = AsyncStream<Void> { continuation in
                output.map { $0.isConfirmEnabled }
                    .filter { $0 == true }
                    .sink { _ in continuation.yield() }
                    .store(in: &cancellables)
            }
            var buttonIterator = buttonStream.makeAsyncIterator()
            
            testInput.updateInitialName.send("나중에온이름")
            
            await nameIterator.next()
            confirm()
            
            await buttonIterator.next()
            confirm()
        }
    }
}
