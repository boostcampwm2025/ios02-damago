//
//  DataSyncStrategy.swift
//  Damago
//
//  Created by Eden Landelyse on 2/3/26.
//

import Foundation

protocol DataSyncStrategy {
    func createFetchStream<T>(
        fetchLocal: @escaping () async throws -> T?,
        checkIsUpToDate: @escaping (T) -> Bool,
        fetchNetwork: @escaping () async throws -> T,
        saveToLocal: @escaping (T) async -> Void,
        onNetworkError: @escaping (Error) -> Void
    ) -> AsyncStream<T>
}

extension DataSyncStrategy {
    func createFetchStream<T>(
        fetchLocal: @escaping () async throws -> T?,
        checkIsUpToDate: @escaping (T) -> Bool,
        fetchNetwork: @escaping () async throws -> T,
        saveToLocal: @escaping (T) async -> Void,
        onNetworkError: @escaping (Error) -> Void
    ) -> AsyncStream<T> {
        AsyncStream { continuation in
            Task {
                // 로컬 데이터 조회
                if let localData = try? await fetchLocal(), checkIsUpToDate(localData) {
                    continuation.yield(localData)
                }

                // 네트워크 데이터 조회
                do {
                    let remoteData = try await fetchNetwork()
                    await saveToLocal(remoteData)
                    continuation.yield(remoteData)
                } catch {
                    onNetworkError(error)
                }

                continuation.finish()
            }
        }
    }
}
