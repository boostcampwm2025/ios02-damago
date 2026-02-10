//
//  SignInViewModelTests.swift
//  DamagoViewModelTests
//
//  Created by Gemini on 2/4/26.
//

import Testing
import Combine
import Foundation
@testable import Damago

@MainActor
final class SignInViewModelTests {
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Mocks

    @MainActor
    class MockSignInUseCase: SignInUseCase {
        var executeCalled = false
        var executeResult: Result<Void, Error> = .success(())
        var onExecute: (() -> Void)?
        
        func execute() async throws {
            executeCalled = true
            onExecute?()
            switch executeResult {
            case .success:
                return
            case .failure(let error):
                throw error
            }
        }
    }

    // MARK: - Test Input

    struct TestInput {
        let signInButtonDidTap = PassthroughSubject<Void, Never>()
        let alertButtonDidTap = PassthroughSubject<Void, Never>()
        
        var input: SignInViewModel.Input {
            SignInViewModel.Input(
                signInButtonDidTap: signInButtonDidTap.eraseToAnyPublisher(),
                alertButtonDidTap: alertButtonDidTap.eraseToAnyPublisher()
            )
        }
    }

    // MARK: - Tests

    @Test("로그인 성공 시 UseCase가 실행되고 연결 화면으로 라우팅되어야 한다")
    func testSignInSuccess() async {
        // Given
        let mockSignInUseCase = MockSignInUseCase()
        mockSignInUseCase.executeResult = .success(())
        
        let expectedOpponentCode = "12345"
        let viewModel = SignInViewModel(
            signInUseCase: mockSignInUseCase,
            opponentCode: expectedOpponentCode
        )
        
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)
        
        // When & Then
        await confirmation("SignIn UseCase 실행 및 Connection 라우팅 확인", expectedCount: 2) { confirm in
            var isUseCaseExecuted = false
            var isRouteUpdated = false
            
            let stream = AsyncStream<Void> { continuation in
                // 1. UseCase 실행
                mockSignInUseCase.onExecute = {
                    if !isUseCaseExecuted {
                        isUseCaseExecuted = true
                        confirm()
                        continuation.yield()
                    }
                }
                
                // 2. Route 변경
                output.compactMap { $0.route }
                    .compactMap { $0.value }
                    .filter {
                        if case .connection(let code) = $0, code == expectedOpponentCode { return true }
                        return false
                    }
                    .sink { _ in
                        if !isRouteUpdated {
                            isRouteUpdated = true
                            confirm()
                            continuation.yield()
                        }
                    }
                    .store(in: &cancellables)
            }
            var iterator = stream.makeAsyncIterator()
            
            testInput.signInButtonDidTap.send(())
            
            while !isUseCaseExecuted || !isRouteUpdated {
                await iterator.next()
            }
        }
        
        #expect(mockSignInUseCase.executeCalled)
    }

    @Test("로그인 실패 시 에러 알림으로 라우팅되어야 한다")
    func testSignInFailure() async {
        // Given
        let mockSignInUseCase = MockSignInUseCase()
        struct TestError: Error, LocalizedError {
            var errorDescription: String? { "로그인 실패" }
        }
        mockSignInUseCase.executeResult = .failure(TestError())
        
        let viewModel = SignInViewModel(
            signInUseCase: mockSignInUseCase,
            opponentCode: nil
        )
        
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)
        
        // When & Then
        await confirmation("SignIn UseCase 실행 및 Alert 라우팅 확인", expectedCount: 2) { confirm in
            // 상태 플래그
            var isUseCaseExecuted = false
            var isRouteUpdated = false
            
            let stream = AsyncStream<Void> { continuation in
                // 1. UseCase 실행
                mockSignInUseCase.onExecute = {
                    if !isUseCaseExecuted {
                        isUseCaseExecuted = true
                        confirm()
                        continuation.yield()
                    }
                }
                
                // 2. Route 변경
                output.compactMap { $0.route }
                    .compactMap { $0.value }
                    .filter {
                        if case .alert = $0 { return true }
                        return false
                    }
                    .sink { _ in
                        if !isRouteUpdated {
                            isRouteUpdated = true
                            confirm()
                            continuation.yield()
                        }
                    }
                    .store(in: &cancellables)
            }
            var iterator = stream.makeAsyncIterator()
            
            testInput.signInButtonDidTap.send(())
            
            while !isUseCaseExecuted || !isRouteUpdated {
                await iterator.next()
            }
        }
        
        #expect(mockSignInUseCase.executeCalled)
    }
}
