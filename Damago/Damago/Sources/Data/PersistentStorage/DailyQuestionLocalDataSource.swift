//
//  DailyQuestionLocalDataSource.swift
//  Damago
//
//  Created by 김재영 on 1/22/26.
//

import Foundation
import SwiftData

@MainActor
protocol DailyQuestionLocalDataSourceProtocol {
    func fetchQuestion(id: String) async throws -> DailyQuestionEntity?
    func fetchLatestQuestion() async throws -> DailyQuestionEntity?
    func saveQuestion(_ entity: DailyQuestionEntity) async throws
    func updateAnswer(
        questionID: String,
        user1Answer: String?,
        user2Answer: String?,
        bothAnswered: Bool,
        lastAnsweredAt: Date?
    ) async throws
    func saveDraftAnswer(questionID: String, draftAnswer: String?) async throws
    func loadDraftAnswer(questionID: String) async throws -> String?
    func deleteDraftAnswer(questionID: String) async throws
}

@MainActor
final class DailyQuestionLocalDataSource: DailyQuestionLocalDataSourceProtocol {
    private let storage: SwiftDataStorage

    init(storage: SwiftDataStorage) {
        self.storage = storage
    }

    @MainActor
    convenience init() {
        self.init(storage: .shared)
    }

    func fetchQuestion(id: String) async throws -> DailyQuestionEntity? {
        let descriptor = FetchDescriptor<DailyQuestionEntity>(
            predicate: #Predicate { $0.questionID == id }
        )
        return try storage.context.fetch(descriptor).first
    }

    func fetchLatestQuestion() async throws -> DailyQuestionEntity? {
        var descriptor = FetchDescriptor<DailyQuestionEntity>(
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try storage.context.fetch(descriptor).first
    }

    func saveQuestion(_ entity: DailyQuestionEntity) async throws {
        let targetID = entity.questionID
        let descriptor = FetchDescriptor<DailyQuestionEntity>(
            predicate: #Predicate { $0.questionID == targetID }
        )
        
        if let existingEntity = try storage.context.fetch(descriptor).first {
            existingEntity.questionContent = entity.questionContent
            existingEntity.user1Answer = entity.user1Answer
            existingEntity.user2Answer = entity.user2Answer
            existingEntity.bothAnswered = entity.bothAnswered
            existingEntity.lastAnsweredAt = entity.lastAnsweredAt
            existingEntity.isUser1 = entity.isUser1
            existingEntity.lastUpdated = Date()
            return
        } else {
            storage.context.insert(entity)
        }
        
        try storage.context.save()
    }

    func updateAnswer(
        questionID: String,
        user1Answer: String?,
        user2Answer: String?,
        bothAnswered: Bool,
        lastAnsweredAt: Date?
    ) async throws {
        let descriptor = FetchDescriptor<DailyQuestionEntity>(
            predicate: #Predicate { $0.questionID == questionID }
        )

        if let existingEntity = try storage.context.fetch(descriptor).first {
            existingEntity.user1Answer = user1Answer
            existingEntity.user2Answer = user2Answer
            existingEntity.bothAnswered = bothAnswered
            existingEntity.lastAnsweredAt = lastAnsweredAt
            existingEntity.lastUpdated = Date()

            try storage.context.save()
        }
    }
    
    func saveDraftAnswer(questionID: String, draftAnswer: String?) async throws {
        let descriptor = FetchDescriptor<DailyQuestionEntity>(
            predicate: #Predicate { $0.questionID == questionID }
        )
        
        if let existingEntity = try storage.context.fetch(descriptor).first {
            existingEntity.draftAnswer = draftAnswer
            existingEntity.lastUpdated = Date()
            try storage.context.save()
        } else {
            // 질문 엔티티가 없으면 생성 (나중에 질문 정보가 채워질 수 있음)
            let entity = DailyQuestionEntity(
                questionID: questionID,
                questionContent: "",
                draftAnswer: draftAnswer
            )
            storage.context.insert(entity)
            try storage.context.save()
        }
    }
    
    func loadDraftAnswer(questionID: String) async throws -> String? {
        let descriptor = FetchDescriptor<DailyQuestionEntity>(
            predicate: #Predicate { $0.questionID == questionID }
        )
        return try storage.context.fetch(descriptor).first?.draftAnswer
    }
    
    func deleteDraftAnswer(questionID: String) async throws {
        let descriptor = FetchDescriptor<DailyQuestionEntity>(
            predicate: #Predicate { $0.questionID == questionID }
        )
        
        if let existingEntity = try storage.context.fetch(descriptor).first {
            existingEntity.draftAnswer = nil
            existingEntity.lastUpdated = Date()
            try storage.context.save()
        }
    }
}
