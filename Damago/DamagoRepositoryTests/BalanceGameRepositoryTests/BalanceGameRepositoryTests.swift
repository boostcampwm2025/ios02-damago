//
//  BalanceGameRepositoryTests.swift
//  DamagoRepositoryTests
//
//  Created by Eden Landelyse on 2/4/26.
//

import Foundation
import Testing

@testable import Damago
@testable import DamagoNetwork

@MainActor
@Suite("BalanceGameRepository 통합 테스트")
struct BalanceGameRepositoryTests {
    
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
