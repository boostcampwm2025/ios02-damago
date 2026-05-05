//
//  Combine+.swift
//  Damago
//
//  Created by 박현수 on 1/8/26.
//

import Combine
import Foundation

struct Pulse<R>: Equatable {
    let value: R
    private let id = UUID()

    init(_ value: R) {
        self.value = value
    }

    static func == (lhs: Pulse<R>, rhs: Pulse<R>) -> Bool {
        lhs.id == rhs.id
    }
}

extension Publisher where Failure == Never {
    func mapForUI<T: Equatable>(
        _ transform: @escaping (Output) -> T
    ) -> AnyPublisher<T, Failure> {
        self
            .receive(on: DispatchQueue.main)
            .map(transform)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func mapForUI<T>(
        _ transform: @escaping (Output) -> T,
        isDuplicate: @escaping (T, T) -> Bool
    ) -> AnyPublisher<T, Failure> {
        self
            .receive(on: DispatchQueue.main)
            .map(transform)
            .removeDuplicates(by: isDuplicate)
            .eraseToAnyPublisher()
    }

    func compactMapForUI<T: Equatable>(
        _ transform: @escaping (Output) -> T?
    ) -> AnyPublisher<T, Failure> {
        self
            .receive(on: DispatchQueue.main)
            .compactMap(transform)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func compactMapForUI<T>(
        _ transform: @escaping (Output) -> T?,
        isDuplicate: @escaping (T, T) -> Bool
    ) -> AnyPublisher<T, Failure> {
        self
            .receive(on: DispatchQueue.main)
            .compactMap(transform)
            .removeDuplicates(by: isDuplicate)
            .eraseToAnyPublisher()
    }

    func pulse<R>(
        _ keyPath: KeyPath<Output, Pulse<R>?>
    ) -> AnyPublisher<R, Failure> {
        self
            .receive(on: DispatchQueue.main)
            .map(keyPath)
            .removeDuplicates()
            .compactMap { $0?.value }
            .eraseToAnyPublisher()
    }
}
