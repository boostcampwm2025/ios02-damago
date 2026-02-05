//
//  Utils.swift
//  Damago
//
//  Created by 박현수 on 2/4/26.
//

import Foundation

/// 타임아웃을 적용하는 헬퍼 함수
func withTimeout(seconds: TimeInterval, operation: @escaping @Sendable () async -> Void) async throws {
    try await withThrowingTaskGroup(of: Void.self) { group in
        group.addTask {
            await operation()
        }
        group.addTask {
            try await Task.sleep(for: .seconds(seconds))
            throw TimeoutError()
        }
        try await group.next()
        group.cancelAll()
    }
}

struct TimeoutError: Error {}
