//
//  DailyQuestionRepositoryTestDoubles.swift
//  DamagoRepositoryTests
//
//  Created by Eden Landelyse on 2/4/26.
//

import Foundation
import Combine
@testable import Damago
@testable import DamagoNetwork

final class MockNetworkProvider: NetworkProvider, @unchecked Sendable {
    var requestHandler: ((EndPoint) async throws -> Any)?
    var requestSuccessHandler: ((EndPoint) async throws -> Bool)?
    
    var requestCalledWith: EndPoint?

    func request<T: Decodable>(_ endpoint: EndPoint) async throws -> T {
        requestCalledWith = endpoint
        if let handler = requestHandler {
            return try await handler(endpoint) as! T
        }
        fatalError("MockNetworkProvider: requestHandler not set")
    }

    func requestString(_ endpoint: EndPoint) async throws -> String {
        requestCalledWith = endpoint
        return ""
    }

    func requestSuccess(_ endpoint: EndPoint) async throws -> Bool {
        requestCalledWith = endpoint
        return try await requestSuccessHandler?(endpoint) ?? true
    }
}

final class MockTokenProvider: TokenProvider, @unchecked Sendable {
    var idTokenHandler: (() async throws -> String)?

    func idToken() async throws -> String {
        return try await idTokenHandler?() ?? "mock_id_token"
    }

    func fcmToken() async throws -> String {
        return "mock_fcm_token"
    }
}

final class MockFirestoreService: FirestoreService, @unchecked Sendable {
    var observeHandler: ((String, String) -> AnyPublisher<Result<Any, Error>, Never>)?
    
    func observe<T: Decodable>(
        collection: String,
        document: String
    ) -> AnyPublisher<Result<T, Error>, Never> {
        observeCalledWith = (collection, document)
        if let handler = observeHandler {
            return handler(collection, document).map { res in
                res.map { $0 as! T }
            }.eraseToAnyPublisher()
        }
        return Empty().eraseToAnyPublisher()
    }
    
    var observeCalledWith: (collection: String, document: String)?

    func observeQuery<T: Decodable>(
        collection: String,
        field: String,
        value: Any
    ) -> AnyPublisher<Result<[T], Error>, Never> {
        return Empty().eraseToAnyPublisher()
    }
}

@MainActor
final class MockDailyQuestionLocalDataSource: DailyQuestionLocalDataSourceProtocol, @unchecked Sendable {
    var fetchLatestQuestionHandler: (() async throws -> DailyQuestionEntity?)?
    var saveQuestionCalledWith: DailyQuestionEntity?
    
    func fetchQuestion(id: String) async throws -> DailyQuestionEntity? { nil }
    func fetchLatestQuestion() async throws -> DailyQuestionEntity? {
        return try await fetchLatestQuestionHandler?()
    }
    func saveQuestion(_ entity: DailyQuestionEntity) async throws {
        saveQuestionCalledWith = entity
    }
    func updateAnswer(questionID: String, user1Answer: String?, user2Answer: String?, bothAnswered: Bool, lastAnsweredAt: Date?) async throws {}
    func saveDraftAnswer(questionID: String, draftAnswer: String?) async throws {}
    func loadDraftAnswer(questionID: String) async throws -> String? { nil }
    func deleteDraftAnswer(questionID: String) async throws { }
}
