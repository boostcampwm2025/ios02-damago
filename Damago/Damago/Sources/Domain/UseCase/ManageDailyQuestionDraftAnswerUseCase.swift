//
//  ManageDailyQuestionDraftAnswerUseCase.swift
//  Damago
//
//  Created by loyH on 1/26/26.
//

protocol ManageDailyQuestionDraftAnswerUseCase {
    func saveDraftAnswer(questionID: String, draftAnswer: String?) async throws
    func loadDraftAnswer(questionID: String) async throws -> String?
    func deleteDraftAnswer(questionID: String) async throws
}

final class ManageDailyQuestionDraftAnswerUseCaseImpl: ManageDailyQuestionDraftAnswerUseCase {
    private let localDataSource: DailyQuestionLocalDataSourceProtocol
    
    init(localDataSource: DailyQuestionLocalDataSourceProtocol) {
        self.localDataSource = localDataSource
    }
    
    func saveDraftAnswer(questionID: String, draftAnswer: String?) async throws {
        try await localDataSource.saveDraftAnswer(questionID: questionID, draftAnswer: draftAnswer)
    }
    
    func loadDraftAnswer(questionID: String) async throws -> String? {
        try await localDataSource.loadDraftAnswer(questionID: questionID)
    }
    
    func deleteDraftAnswer(questionID: String) async throws {
        try await localDataSource.deleteDraftAnswer(questionID: questionID)
    }
}
