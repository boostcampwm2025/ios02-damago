//
//  DailyQuestionRepositoryProtocol.swift
//  Damago
//
//  Created by 김재영 on 1/20/26.
//

protocol DailyQuestionRepositoryProtocol {
    func fetchDailyQuestion() async throws -> DailyQuestionDTO
}
