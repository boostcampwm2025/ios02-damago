//
//  MockFirestoreService.swift
//  DamagoRepositoryTests
//
//  Created by Eden Landelyse on 2/4/26.
//

import Foundation
import Combine
@testable import Damago
@testable import DamagoNetwork

final class MockFirestoreService: FirestoreService, @unchecked Sendable {
    var observeDataHandler: ((String, String) -> AnyPublisher<Result<Data, Error>, Never>)?
    var observeCalledWith: (collection: String, document: String)?
    
    func observe<T: Decodable>(
        collection: String,
        document: String
    ) -> AnyPublisher<Result<T, Error>, Never> {
        observeCalledWith = (collection, document)
        
        if let handler = observeDataHandler {
            return handler(collection, document).map { result in
                switch result {
                case .success(let data):
                    do {
                        let decoded = try JSONDecoder().decode(T.self, from: data)
                        return .success(decoded)
                    } catch {
                        return .failure(error)
                    }
                case .failure(let error):
                    return .failure(error)
                }
            }.eraseToAnyPublisher()
        }
        return Empty().eraseToAnyPublisher()
    }

    func observeQuery<T: Decodable>(
        collection: String,
        field: String,
        value: Any
    ) -> AnyPublisher<Result<[T], Error>, Never> {
        return Empty().eraseToAnyPublisher()
    }
}
