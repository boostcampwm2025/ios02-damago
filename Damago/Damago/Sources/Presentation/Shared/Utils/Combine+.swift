//
//  Combine+.swift
//  Damago
//
//  Created by 박현수 on 1/8/26.
//

import Combine
import Foundation
import UIKit

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
            .map(transform)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func mapForUI<T>(
        _ transform: @escaping (Output) -> T,
        isDuplicate: @escaping (T, T) -> Bool
    ) -> AnyPublisher<T, Failure> {
        self
            .map(transform)
            .removeDuplicates(by: isDuplicate)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func pulse<R>(
        _ keyPath: KeyPath<Output, Pulse<R>?>
    ) -> AnyPublisher<R, Failure> {
        self
            .map(keyPath)
            .removeDuplicates()
            .compactMap { $0?.value }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// Publisher가 이벤트를 발행할 때 지정된 뷰의 키보드를 내립니다.
    func dismissKeyboard(from view: UIView) -> AnyPublisher<Output, Failure> {
        self
            .handleEvents(receiveOutput: { _ in
                view.endEditing(true)
            })
            .eraseToAnyPublisher()
    }
}
