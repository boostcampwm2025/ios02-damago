//
//  DailyQuestionRepositoryTests+Observe.swift
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
extension DailyQuestionRepositoryTests.Observe {
    
    // MARK: - 시나리오: Firestore 데이터 수신 및 로컬 반영
    // 1. Firestore로부터 답변 데이터를 성공적으로 수신하면 DailyQuestionDTO로 변환하여 방출한다.
    // 2. 수신된 답변 데이터를 로컬 데이터소스(updateAnswer)에 즉시 반영한다.
    @Test("Firestore로부터 데이터를 수신하면 DTO로 변환하여 방출하고 로컬 데이터를 업데이트한다")
    func testObserveAnswer_Success_UpdatesLocal() async throws {
        let firestoreService = MockFirestoreService()
        let localDataSource = MockDailyQuestionLocalDataSource()
        let repository: DailyQuestionRepositoryProtocol = DailyQuestionRepository(
            networkProvider: MockNetworkProvider(),
            tokenProvider: MockTokenProvider(),
            firestoreService: firestoreService,
            localDataSource: localDataSource
        )
        
        let subject = PassthroughSubject<Result<Data, Error>, Never>()
        firestoreService.observeDataHandler = { _, _ in subject.eraseToAnyPublisher() }
        
        var emittedResult: Result<DailyQuestionDTO, Error>?
        let cancellable = repository.observeAnswer(
            coupleID: "c1",
            questionID: "q1",
            questionContent: "질문 내용",
            isUser1: true
        )
        .sink { emittedResult = $0 }
        
        let jsonString = """
        {
            "user1Answer": "내 답변",
            "user2Answer": "상대 답변",
            "bothAnswered": true,
            "lastAnsweredAt": null
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        subject.send(.success(jsonData))
        
        for _ in 0..<10 { await Task.yield() }
        
        let dto = try #require(try emittedResult?.get())
        #expect(dto.questionID == "q1")
        #expect(dto.user1Answer == "내 답변")
        
        #expect(localDataSource.updateAnswerCalledWith?.questionID == "q1")
        #expect(localDataSource.updateAnswerCalledWith?.user1Answer == "내 답변")
        
        cancellable.cancel()
    }
    
    // MARK: - 시나리오: Firestore 감시 중 에러 발생
    // 3. Firestore 수신 중 에러가 발생하면 에러 결과를 방출한다.
    @Test("Firestore 조회 중 에러 발생 시 failure 결과를 방출한다")
    func testObserveAnswer_Failure() async throws {
        let firestoreService = MockFirestoreService()
        let repository: DailyQuestionRepositoryProtocol = DailyQuestionRepository(
            networkProvider: MockNetworkProvider(),
            tokenProvider: MockTokenProvider(),
            firestoreService: firestoreService,
            localDataSource: MockDailyQuestionLocalDataSource()
        )
        
        let subject = PassthroughSubject<Result<Data, Error>, Never>()
        firestoreService.observeDataHandler = { _, _ in subject.eraseToAnyPublisher() }
        
        var emittedResult: Result<DailyQuestionDTO, Error>?
        let cancellable = repository.observeAnswer(
            coupleID: "c1",
            questionID: "q1",
            questionContent: "질문 내용",
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