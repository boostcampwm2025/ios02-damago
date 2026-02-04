//
//  DailyQuestionRepositoryTests.swift
//  DamagoRepositoryTests
//
//  Created by Eden Landelyse on 2/4/26.
//

import Testing

@MainActor
@Suite("DailyQuestionRepository 통합 테스트")
struct DailyQuestionRepositoryTests {
    
    @MainActor
    @Suite("Fetch 테스트")
    struct Fetch { }
    
    @MainActor
    @Suite("Submit 테스트")
    struct Submit { }
    
    @MainActor
    @Suite("Observe 테스트")
    struct Observe { }
}
