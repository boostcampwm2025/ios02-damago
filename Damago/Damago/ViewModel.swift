//
//  ViewModel.swift
//  Damago
//
//  Created by 박현수 on 1/7/26.
//

import Combine

@MainActor
protocol ViewModel {
    associatedtype Input
    associatedtype State
    typealias Output = AnyPublisher<State, Never>

    func transform(_ input: Input) -> Output
}
