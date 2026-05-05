//
//  BalanceGameRepositoryTests+Fetch.swift
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
extension BalanceGameRepositoryTests.Fetch {
    
    // MARK: - 시나리오 1, 4, 6
    // 1. 로컬 데이터가 오늘 데이터인 경우 방출하고 네트워크 조회로 넘어간다.
    // 4. 토큰을 가져오는 것이 성공하면 네트워크 요청을 보낸다.
    // 6. 네트워크 요청을 통해 dto를 전달받으면 로컬에 저장하여 다음 조회 시 로컬 데이터가 방출된다.
    @Test("로컬 데이터가 오늘 데이터인 경우 방출하고, 토큰 성공 시 네트워크 요청을 보낸 뒤 결과를 로컬에 저장한다")
    func testFetch_LocalHit_TokenSuccess_NetworkSuccess_SavesLocal() async throws {
        let localDataSource = MockBalanceGameLocalDataSource()
        localDataSource.fetchLatestGameHandler = {
            let entity = BalanceGameEntity(gameID: "g1", questionContent: "로컬 질문", option1: "A", option2: "B")
            entity.lastUpdated = Date()
            return entity
        }
        
        let tokenProvider = MockTokenProvider()
        tokenProvider.idTokenHandler = { "valid_token" }
        
        let networkProvider = MockNetworkProvider()
        networkProvider.requestHandler = { _ in
            BalanceGameDTO(
                gameID: "g1",
                questionContent: "네트워크 질문",
                option1: "A",
                option2: "B",
                myChoice: nil,
                opponentChoice: nil,
                isUser1: true,
                lastAnsweredAt: nil
            )
        }

        let repository: BalanceGameRepositoryProtocol = BalanceGameRepository(
            networkProvider: networkProvider,
            tokenProvider: tokenProvider,
            firestoreService: MockFirestoreService(),
            localDataSource: localDataSource
        )

        var emittedDTOs: [BalanceGameDTO] = []
        for await dto in repository.fetchBalanceGame() {
            emittedDTOs.append(dto)
        }

        #expect(emittedDTOs.count == 2)
        #expect(emittedDTOs[0].questionContent == "로컬 질문")
        #expect(emittedDTOs[1].questionContent == "네트워크 질문")
        #expect(localDataSource.saveGameCalledWith?.questionContent == "네트워크 질문")
    }

    @Test("사용자 2(isUser1: false)가 로컬 데이터를 조회할 때 선택지가 올바르게 매핑되어 방출된다")
    func testFetch_LocalHit_User2() async throws {
        let localDataSource = MockBalanceGameLocalDataSource()
        localDataSource.fetchLatestGameHandler = {
            let entity = BalanceGameEntity(
                gameID: "g1",
                questionContent: "로컬 질문",
                option1: "A",
                option2: "B",
                user1Choice: 1,
                user2Choice: 2,
                isUser1: false
            )
            entity.lastUpdated = Date()
            return entity
        }
        
        let networkProvider = MockNetworkProvider()
        networkProvider.requestHandler = { _ in
            BalanceGameDTO(
                gameID: "g1",
                questionContent: "네트워크",
                option1: "A",
                option2: "B",
                myChoice: 2,
                opponentChoice: 1,
                isUser1: false,
                lastAnsweredAt: nil
            )
        }

        let repository: BalanceGameRepositoryProtocol = BalanceGameRepository(
            networkProvider: networkProvider,
            tokenProvider: MockTokenProvider(),
            firestoreService: MockFirestoreService(),
            localDataSource: localDataSource
        )

        var emittedDTOs: [BalanceGameDTO] = []
        for await dto in repository.fetchBalanceGame() {
            emittedDTOs.append(dto)
        }

        #expect(emittedDTOs.count >= 1)
        #expect(emittedDTOs[0].myChoice == 2, "사용자 2에게는 user2Choice가 myChoice여야 함")
        #expect(emittedDTOs[0].opponentChoice == 1, "사용자 2에게는 user1Choice가 opponentChoice여야 함")
    }

    // MARK: - 시나리오 2
    // 2. 로컬 데이터가 예전 데이터라면 방출하지 않고 네트워크 조회로 넘어간다.
    @Test("로컬 데이터가 예전 데이터라면 방출하지 않고 네트워크 조회 결과만 방출한다")
    func testFetch_LocalStale_ContinuesToNetwork() async throws {
        let localDataSource = MockBalanceGameLocalDataSource()
        localDataSource.fetchLatestGameHandler = {
            let entity = BalanceGameEntity(gameID: "g_old", questionContent: "어제 질문", option1: "A", option2: "B")
            entity.lastUpdated = Calendar.current.date(byAdding: .day, value: -1, to: Date())
            return entity
        }
        
        let networkProvider = MockNetworkProvider()
        networkProvider.requestHandler = { _ in
            BalanceGameDTO(
                gameID: "g_new",
                questionContent: "오늘 질문",
                option1: "A",
                option2: "B", myChoice: nil, opponentChoice: nil, isUser1: true, lastAnsweredAt: nil
            )
        }

        let repository: BalanceGameRepositoryProtocol = BalanceGameRepository(
            networkProvider: networkProvider,
            tokenProvider: MockTokenProvider(),
            firestoreService: MockFirestoreService(),
            localDataSource: localDataSource
        )

        var emittedDTOs: [BalanceGameDTO] = []
        for await dto in repository.fetchBalanceGame() {
            emittedDTOs.append(dto)
        }

        #expect(emittedDTOs.count == 1)
        #expect(emittedDTOs[0].gameID == "g_new")
    }

    // MARK: - 시나리오 3
    // 3. 로컬 데이터를 가져오는 데 실패하면 네트워크 조회로 넘어간다.
    @Test("로컬 데이터를 가져오는 데 실패하더라도 네트워크 조회로 넘어간다")
    func testFetch_LocalFailure_ContinuesToNetwork() async throws {
        let localDataSource = MockBalanceGameLocalDataSource()
        localDataSource.fetchLatestGameHandler = { throw NSError(domain: "Local", code: -1) }
        
        let networkProvider = MockNetworkProvider()
        networkProvider.requestHandler = { _ in
            BalanceGameDTO(
                gameID: "g1",
                questionContent: "네트워크 질문",
                option1: "A",
                option2: "B", myChoice: nil, opponentChoice: nil, isUser1: true, lastAnsweredAt: nil
            )
        }

        let repository: BalanceGameRepositoryProtocol = BalanceGameRepository(
            networkProvider: networkProvider,
            tokenProvider: MockTokenProvider(),
            firestoreService: MockFirestoreService(),
            localDataSource: localDataSource
        )

        var emittedDTOs: [BalanceGameDTO] = []
        for await dto in repository.fetchBalanceGame() {
            emittedDTOs.append(dto)
        }

        #expect(emittedDTOs.count == 1)
    }

    // MARK: - 시나리오 5
    // 5. 로컬 데이터가 있고 토큰을 가져오는 데 실패하면 로컬 데이터를 유지한 채로 종료한다.
    @Test("로컬 데이터 방출 후 토큰 획득에 실패하면 로컬 데이터만 유지한 채로 종료한다")
    func testFetch_LocalHit_TokenFailure_EndsWithLocalOnly() async throws {
        let localDataSource = MockBalanceGameLocalDataSource()
        localDataSource.fetchLatestGameHandler = {
            let entity = BalanceGameEntity(gameID: "g1", questionContent: "로컬 데이터", option1: "A", option2: "B")
            entity.lastUpdated = Date()
            return entity
        }
        
        let tokenProvider = MockTokenProvider()
        tokenProvider.idTokenHandler = { throw NSError(domain: "Auth", code: 401) }

        let repository: BalanceGameRepositoryProtocol = BalanceGameRepository(
            networkProvider: MockNetworkProvider(),
            tokenProvider: tokenProvider,
            firestoreService: MockFirestoreService(),
            localDataSource: localDataSource
        )

        var emittedDTOs: [BalanceGameDTO] = []
        for await dto in repository.fetchBalanceGame() {
            emittedDTOs.append(dto)
        }

        #expect(emittedDTOs.count == 1)
        #expect(emittedDTOs[0].questionContent == "로컬 데이터")
    }

    // MARK: - 시나리오 7
    // 7. DTO 필드가 비어있거나 타입이 맞지 않는 경우
    @Test("네트워크 응답의 DTO 필드 결함 시 안전하게 종료된다")
    func testFetch_DecodingError_EndsGracefully() async throws {
        let networkProvider = MockNetworkProvider()
        networkProvider.requestHandler = { _ in
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid DTO"))
        }

        let repository: BalanceGameRepositoryProtocol = BalanceGameRepository(
            networkProvider: networkProvider,
            tokenProvider: MockTokenProvider(),
            firestoreService: MockFirestoreService(),
            localDataSource: MockBalanceGameLocalDataSource()
        )

        var emittedDTOs: [BalanceGameDTO] = []
        for await dto in repository.fetchBalanceGame() {
            emittedDTOs.append(dto)
        }

        #expect(emittedDTOs.isEmpty)
    }
}