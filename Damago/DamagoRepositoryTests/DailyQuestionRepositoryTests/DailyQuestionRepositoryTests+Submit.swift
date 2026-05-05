//
//  DailyQuestionRepositoryTests+Submit.swift
//  DamagoRepositoryTests
//
//  Created by Eden Landelyse on 2/4/26.
//

// swiftlint:disable trailing_closure

import Foundation
import Testing

@testable import Damago
@testable import DamagoNetwork

@MainActor
extension DailyQuestionRepositoryTests.Submit {
    
    // MARK: - 시나리오: 답변 제출 성공
    // 1. 로컬 데이터를 가져와 업데이트한다.
    // 2. 토큰을 가져와 일일문답 api 요청을 수행하여 성공여부를 반환한다.
    @Test("답변 제출 성공 시 로컬을 업데이트하고 API 요청 후 성공을 반환한다")
    func testSubmitAnswer_Success() async throws {
        let localDataSource = MockDailyQuestionLocalDataSource()
        localDataSource.fetchQuestionResult = DailyQuestionEntity(
            questionID: "q1",
            questionContent: "질문",
            user1Answer: "기존답변"
        )
        
        let tokenProvider = MockTokenProvider()
        let networkProvider = MockNetworkProvider()
        networkProvider.requestSuccessResult = true
        
        let repository: DailyQuestionRepositoryProtocol = DailyQuestionRepository(
            networkProvider: networkProvider,
            tokenProvider: tokenProvider,
            firestoreService: MockFirestoreService(),
            localDataSource: localDataSource
        )
        
        let result = try await repository.submitAnswer(questionID: "q1", answer: "새답변", isUser1: true)
        
        #expect(result == true)
        #expect(localDataSource.updateAnswerCalledWith?.user1Answer == "새답변")
        #expect(networkProvider.requestCalledWith != nil)
    }

    @Test("사용자 2(isUser1: false)가 답변 제출 성공 시 로컬의 user2Answer를 업데이트한다")
    func testSubmitAnswer_User2_Success() async throws {
        let localDataSource = MockDailyQuestionLocalDataSource()
        localDataSource.fetchQuestionResult = DailyQuestionEntity(
            questionID: "q1",
            questionContent: "질문",
            user2Answer: "기존답변2"
        )
        
        let repository: DailyQuestionRepositoryProtocol = DailyQuestionRepository(
            networkProvider: MockNetworkProvider(),
            tokenProvider: MockTokenProvider(),
            firestoreService: MockFirestoreService(),
            localDataSource: localDataSource
        )
        
        let result = try await repository.submitAnswer(questionID: "q1", answer: "새답변2", isUser1: false)
        
        #expect(result == true)
        #expect(localDataSource.updateAnswerCalledWith?.user2Answer == "새답변2")
        #expect(localDataSource.updateAnswerCalledWith?.user1Answer == nil)
    }
    
    // MARK: - 시나리오: API 요청 실패 시 롤백
    // 3. api 요청 실패 시 이전 상태로 복구하고 에러를 방출한다.
    @Test("API 요청 실패 시 로컬 데이터를 이전 상태로 복구(롤백)하고 에러를 던진다")
    func testSubmitAnswer_APIFailure_RollbacksLocal() async throws {
        let localDataSource = MockDailyQuestionLocalDataSource()
        localDataSource.fetchQuestionResult = DailyQuestionEntity(
            questionID: "q1",
            questionContent: "질문",
            user1Answer: "기존답변",
            bothAnswered: false
        )
        
        let networkProvider = MockNetworkProvider()
        networkProvider.requestSuccessError = NSError(domain: "API", code: 500)
        
        let repository: DailyQuestionRepositoryProtocol = DailyQuestionRepository(
            networkProvider: networkProvider,
            tokenProvider: MockTokenProvider(),
            firestoreService: MockFirestoreService(),
            localDataSource: localDataSource
        )
        
        await #expect(throws: Error.self) {
            try await repository.submitAnswer(questionID: "q1", answer: "새답변", isUser1: true)
        }
        
        #expect(localDataSource.updateAnswerCalledWith?.user1Answer == "기존답변")
    }
    
    @Test("토큰 획득 실패 시에도 로컬 데이터를 롤백하고 에러를 던진다")
    func testSubmitAnswer_TokenFailure_RollbacksLocal() async throws {
        let localDataSource = MockDailyQuestionLocalDataSource()
        localDataSource.fetchQuestionResult = DailyQuestionEntity(
            questionID: "q1",
            questionContent: "질문",
            user1Answer: "기존답변"
        )
        
        let tokenProvider = MockTokenProvider()
        tokenProvider.idTokenHandler = { throw NSError(domain: "Auth", code: 401) }
        
        let repository: DailyQuestionRepositoryProtocol = DailyQuestionRepository(
            networkProvider: MockNetworkProvider(),
            tokenProvider: tokenProvider,
            firestoreService: MockFirestoreService(),
            localDataSource: localDataSource
        )
        
        await #expect(throws: Error.self) {
            try await repository.submitAnswer(questionID: "q1", answer: "새답변", isUser1: true)
        }
        
        #expect(localDataSource.updateAnswerCalledWith?.user1Answer == "기존답변")
    }
}
