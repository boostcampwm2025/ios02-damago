//
//  MockDailyQuestionLocalDataSource.swift
//  DamagoRepositoryTests
//
//  Created by Eden Landelyse on 2/4/26.
//

import Foundation
import SwiftData
@testable import Damago

@MainActor
final class MockDailyQuestionLocalDataSource: DailyQuestionLocalDataSourceProtocol, @unchecked Sendable {
    var fetchQuestionResult: DailyQuestionEntity?
    var fetchQuestionError: Error?
    
    var fetchLatestQuestionHandler: (() async throws -> DailyQuestionEntity?)?
    var saveQuestionCalledWith: DailyQuestionEntity?
    
    var updateAnswerCalledWith: (questionID: String, user1Answer: String?, user2Answer: String?, bothAnswered: Bool, lastAnsweredAt: Date?)?
    var updateAnswerError: Error?
    
    func fetchQuestion(id: String) async throws -> DailyQuestionEntity? {
        if let error = fetchQuestionError { throw error }
        return fetchQuestionResult
    }

    func fetchLatestQuestion() async throws -> DailyQuestionEntity? {
        if let error = fetchQuestionError { throw error }
        return try await fetchLatestQuestionHandler?()
    }

    func saveQuestion(_ entity: DailyQuestionEntity) async throws {
        saveQuestionCalledWith = entity
    }

    func updateAnswer(
        questionID: String,
        user1Answer: String?,
        user2Answer: String?,
        bothAnswered: Bool,
        lastAnsweredAt: Date?
    ) async throws {
        if let error = updateAnswerError { throw error }
        updateAnswerCalledWith = (questionID, user1Answer, user2Answer, bothAnswered, lastAnsweredAt)
    }

    func saveDraftAnswer(questionID: String, draftAnswer: String?) async throws {}
    func loadDraftAnswer(questionID: String) async throws -> String? { nil }
    func deleteDraftAnswer(questionID: String) async throws { }
}
