//
//  MockNetworkProvider.swift
//  DamagoRepositoryTests
//
//  Created by Eden Landelyse on 2/4/26.
//

import Foundation
@testable import Damago
@testable import DamagoNetwork

final class MockNetworkProvider: NetworkProvider, @unchecked Sendable {
    var requestHandler: ((EndPoint) async throws -> Any)?
    var requestSuccessResult: Bool = true
    var requestSuccessError: Error?
    
    var requestCalledWith: EndPoint?

    func request<T: Decodable>(_ endpoint: EndPoint) async throws -> T {
        requestCalledWith = endpoint
        if let handler = requestHandler {
            return try await handler(endpoint) as! T
        }
        throw NetworkError.invalidResponse
    }

    func requestString(_ endpoint: EndPoint) async throws -> String {
        requestCalledWith = endpoint
        return ""
    }

    func requestSuccess(_ endpoint: EndPoint) async throws -> Bool {
        requestCalledWith = endpoint
        if let error = requestSuccessError { throw error }
        return requestSuccessResult
    }
}
