//
//  DailyQuestionLocalDataSource.swift
//  Damago
//
//  Created by 김재영 on 1/22/26.
//

import Foundation
import SwiftData

import Foundation
import SwiftData

@MainActor
protocol DailyQuestionLocalDataSourceProtocol {
    func fetchQuestion(id: String) async throws -> DailyQuestionEntity?
    func fetchLatestQuestion() async throws -> DailyQuestionEntity?
    func saveQuestion(_ entity: DailyQuestionEntity) async throws
    func updateAnswer(questionID: String, user1Answer: String?, user2Answer: String?) async throws
}

@MainActor
final class DailyQuestionLocalDataSource: DailyQuestionLocalDataSourceProtocol {
    private let storage: SwiftDataStorage
    
    init(storage: SwiftDataStorage = .shared) {
        self.storage = storage
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
        storage.context.insert(entity)
        try storage.context.save()
    }
    
    func updateAnswer(questionID: String, user1Answer: String?, user2Answer: String?) async throws {
        let descriptor = FetchDescriptor<DailyQuestionEntity>(
            predicate: #Predicate { $0.questionID == questionID }
        )
        
        if let existingEntity = try storage.context.fetch(descriptor).first {
            existingEntity.user1Answer = user1Answer
            existingEntity.user2Answer = user2Answer
            existingEntity.lastUpdated = Date()
            
            try storage.context.save()
        }
    }
}
