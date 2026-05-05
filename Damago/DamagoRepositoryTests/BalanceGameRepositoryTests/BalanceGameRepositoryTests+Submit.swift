//
//  BalanceGameRepositoryTests+Submit.swift
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
extension BalanceGameRepositoryTests.Submit {
    
    // **submit**
    // - 로컬 데이터를 가져와 업데이트한다.
    // - 토큰을 가져와 일일문답 api 요청을 수행하여 성공여부를 반환한다.
    // - api 요청 실패 시 이전 상태로 복구하고 에러를 방출한다.

    @Test("로컬 데이터를 가져와 업데이트하고 토큰을 가져와 API 요청 후 성공을 반환한다")
    func testSubmitChoice_Success() async throws {
        let localDataSource = MockBalanceGameLocalDataSource()
        localDataSource.fetchGameResult = BalanceGameEntity(
            gameID: "g1",
            questionContent: "질문",
            option1: "A",
            option2: "B",
            user1Choice: 1
        )
        
        let tokenProvider = MockTokenProvider()
        let networkProvider = MockNetworkProvider()
        networkProvider.requestSuccessResult = true
        
        let repository: BalanceGameRepositoryProtocol = BalanceGameRepository(
            networkProvider: networkProvider,
            tokenProvider: tokenProvider,
            firestoreService: MockFirestoreService(),
            localDataSource: localDataSource
        )
        
        let result = try await repository.submitChoice(gameID: "g1", choice: 2, isUser1: true)
        
        #expect(result == true)
        #expect(localDataSource.updateChoiceCalledWith?.user1Choice == 2)
        #expect(networkProvider.requestCalledWith != nil)
    }

    @Test("사용자 2(isUser1: false)가 답변 제출 성공 시 로컬의 user2Choice를 업데이트한다")
    func testSubmitChoice_User2_Success() async throws {
        let localDataSource = MockBalanceGameLocalDataSource()
        localDataSource.fetchGameResult = BalanceGameEntity(
            gameID: "g1",
            questionContent: "질문",
            option1: "A",
            option2: "B",
            user2Choice: 1
        )
        
        let repository: BalanceGameRepositoryProtocol = BalanceGameRepository(
            networkProvider: MockNetworkProvider(),
            tokenProvider: MockTokenProvider(),
            firestoreService: MockFirestoreService(),
            localDataSource: localDataSource
        )
        
        let result = try await repository.submitChoice(gameID: "g1", choice: 2, isUser1: false)
        
        #expect(result == true)
        #expect(localDataSource.updateChoiceCalledWith?.user2Choice == 2)
        #expect(localDataSource.updateChoiceCalledWith?.user1Choice == nil)
    }
    
    @Test("api 요청 실패 시 이전 상태로 복구하고 에러를 방출한다")
    func testSubmitChoice_APIFailure_RollbacksLocal() async throws {
        let localDataSource = MockBalanceGameLocalDataSource()
        localDataSource.fetchGameResult = BalanceGameEntity(
            gameID: "g1",
            questionContent: "질문",
            option1: "A",
            option2: "B",
            user1Choice: 1
        )
        
        let networkProvider = MockNetworkProvider()
        networkProvider.requestSuccessError = NSError(domain: "API", code: 500)
        
        let repository: BalanceGameRepositoryProtocol = BalanceGameRepository(
            networkProvider: networkProvider,
            tokenProvider: MockTokenProvider(),
            firestoreService: MockFirestoreService(),
            localDataSource: localDataSource
        )
        
        await #expect(throws: Error.self) {
            try await repository.submitChoice(gameID: "g1", choice: 2, isUser1: true)
        }
        
        #expect(localDataSource.updateChoiceCalledWith?.user1Choice == 1)
    }

    @Test("토큰 획득 실패 시에도 이전 상태로 복구하고 에러를 던진다")
    func testSubmitChoice_TokenFailure_RollbacksLocal() async throws {
        let localDataSource = MockBalanceGameLocalDataSource()
        localDataSource.fetchGameResult = BalanceGameEntity(
            gameID: "g1",
            questionContent: "질문",
            option1: "A",
            option2: "B",
            user1Choice: 1
        )
        
        let tokenProvider = MockTokenProvider()
        tokenProvider.idTokenHandler = { throw NSError(domain: "Auth", code: 401) }
        
        let repository: BalanceGameRepositoryProtocol = BalanceGameRepository(
            networkProvider: MockNetworkProvider(),
            tokenProvider: tokenProvider,
            firestoreService: MockFirestoreService(),
            localDataSource: localDataSource
        )
        
        await #expect(throws: Error.self) {
            try await repository.submitChoice(gameID: "g1", choice: 2, isUser1: true)
        }
        
        #expect(localDataSource.updateChoiceCalledWith?.user1Choice == 1)
    }
}
