//
//  BalanceGameRepositoryTests+Observe.swift
//  DamagoRepositoryTests
//
//  Created by Eden Landelyse on 2/4/26.
//

// swiftlint:disable trailing_closure

import Combine
import Foundation
import Testing

@testable import Damago
@testable import DamagoNetwork

@MainActor
extension BalanceGameRepositoryTests.Observe {
    
    // MARK: - 시나리오: Firestore 데이터 수신 및 로컬 반영
    // 1. Firestore로부터 답변 데이터를 성공적으로 수신하면 BalanceGameDTO로 변환하여 방출한다.
    // 2. 수신된 답변 데이터를 로컬 데이터소스(updateChoice)에 즉시 반영한다.
    @Test("Firestore로부터 데이터를 수신하면 DTO로 변환하여 방출하고 로컬 데이터를 업데이트한다")
    func testObserveAnswer_Success_UpdatesLocal() async throws {
        let firestoreService = MockFirestoreService()
        let localDataSource = MockBalanceGameLocalDataSource()
        let repository: BalanceGameRepositoryProtocol = BalanceGameRepository(
            networkProvider: MockNetworkProvider(),
            tokenProvider: MockTokenProvider(),
            firestoreService: firestoreService,
            localDataSource: localDataSource
        )
        
        let subject = PassthroughSubject<Result<Data, Error>, Never>()
        firestoreService.observeDataHandler = { _, _ in subject.eraseToAnyPublisher() }
        
        var emittedResult: Result<BalanceGameDTO, Error>?
        let cancellable = repository.observeAnswer(
            coupleID: "c1",
            gameID: "g1",
            questionContent: "밸런스 게임 질문",
            option1: "A",
            option2: "B",
            isUser1: true
        )
        .sink { emittedResult = $0 }
        
        // FirestoreBalanceGameAnswerDTO 필드에 맞춘 JSON 데이터 (내부 필드명은 DTO 정의에 따름)
        let jsonString = """
        {
            "user1Answer": 1,
            "user2Answer": 2,
            "bothAnswered": true,
            "lastAnsweredAt": null,
            "user1AnsweredAt": null,
            "user2AnsweredAt": null
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        subject.send(.success(jsonData))
        
        for _ in 0..<10 { await Task.yield() }
        
        let dto = try #require(try emittedResult?.get())
        #expect(dto.gameID == "g1")
        #expect(dto.myChoice == 1)
        #expect(dto.opponentChoice == 2)
        
        #expect(localDataSource.updateChoiceCalledWith?.gameID == "g1")
        #expect(localDataSource.updateChoiceCalledWith?.user1Choice == 1)
        #expect(localDataSource.updateChoiceCalledWith?.user2Choice == 2)
        
        cancellable.cancel()
    }

    @Test("사용자 2(isUser1: false)가 Firestore로부터 데이터를 수신하면 선택지가 올바르게 매핑되어 방출된다")
    func testObserveAnswer_User2_Success() async throws {
        let firestoreService = MockFirestoreService()
        let localDataSource = MockBalanceGameLocalDataSource()
        let repository: BalanceGameRepositoryProtocol = BalanceGameRepository(
            networkProvider: MockNetworkProvider(),
            tokenProvider: MockTokenProvider(),
            firestoreService: firestoreService,
            localDataSource: localDataSource
        )
        
        let subject = PassthroughSubject<Result<Data, Error>, Never>()
        firestoreService.observeDataHandler = { _, _ in subject.eraseToAnyPublisher() }
        
        var emittedResult: Result<BalanceGameDTO, Error>?
        let cancellable = repository.observeAnswer(
            coupleID: "c1",
            gameID: "g1",
            questionContent: "질문",
            option1: "A",
            option2: "B",
            isUser1: false
        )
        .sink { emittedResult = $0 }
        
        let jsonString = "{\"user1Answer\": 1, \"user2Answer\": 2, \"bothAnswered\": true, \"lastAnsweredAt\": null}"
        subject.send(.success(jsonString.data(using: .utf8)!))
        
        for _ in 0..<10 { await Task.yield() }
        
        let dto = try #require(try emittedResult?.get())
        #expect(dto.myChoice == 2, "사용자 2에게는 user2Answer가 myChoice여야 함")
        #expect(dto.opponentChoice == 1, "사용자 2에게는 user1Answer가 opponentChoice여야 함")
        
        cancellable.cancel()
    }
    
    // MARK: - 시나리오: Firestore 감시 중 에러 발생
    // 3. Firestore 수신 중 에러가 발생하면 에러 결과를 방출한다.
    @Test("Firestore 조회 중 에러 발생 시 failure 결과를 방출한다")
    func testObserveAnswer_Failure() async throws {
        let firestoreService = MockFirestoreService()
        let localDataSource = MockBalanceGameLocalDataSource()
        let repository: BalanceGameRepositoryProtocol = BalanceGameRepository(
            networkProvider: MockNetworkProvider(),
            tokenProvider: MockTokenProvider(),
            firestoreService: firestoreService,
            localDataSource: localDataSource
        )
        
        let subject = PassthroughSubject<Result<Data, Error>, Never>()
        firestoreService.observeDataHandler = { _, _ in subject.eraseToAnyPublisher() }
        
        var emittedResult: Result<BalanceGameDTO, Error>?
        let cancellable = repository.observeAnswer(
            coupleID: "c1",
            gameID: "g1",
            questionContent: "질문 내용",
            option1: "A",
            option2: "B",
            isUser1: true
        )
        .sink { emittedResult = $0 }
        
        let error = NSError(domain: "Firestore", code: -1)
        subject.send(.failure(error))
        
        if case .failure(let receivedError) = emittedResult {
            #expect((receivedError as NSError).domain == "Firestore")
        } else {
            Issue.record("에러가 방출되어야 합니다.")
        }
        
        cancellable.cancel()
    }
}