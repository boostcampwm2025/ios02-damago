//
//  Utils.swift
//  Damago
//
//  Created by loyH on 2/5/26.
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
            throw TestError.timeout
        }
        try await group.next()
        group.cancelAll()
    }
}

enum TestError: Error {
    case timeout
    case dummy
}
