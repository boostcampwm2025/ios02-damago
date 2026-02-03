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

    func submitWithOptimisticUpdate<T>(
        backupState: T?,
        updateLocal: () async throws -> Void,
        networkCall: () async throws -> Bool,
        rollbackLocal: (T?) async throws -> Void,
        onFailure: (Error) -> Void
    ) async throws -> Bool
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

    func submitWithOptimisticUpdate<T>(
        backupState: T?,
        updateLocal: () async throws -> Void,
        networkCall: () async throws -> Bool,
        rollbackLocal: (T?) async throws -> Void,
        onFailure: (Error) -> Void
    ) async throws -> Bool {
        // 로컬 선반영
        try await updateLocal()

        do {
            // 네트워크 요청
            return try await networkCall()
        } catch {
            // 실패 시 롤백
            onFailure(error)
            try await rollbackLocal(backupState)
            throw error
        }
    }
}
