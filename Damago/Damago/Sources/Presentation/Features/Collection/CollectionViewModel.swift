//
//  CollectionViewModel.swift
//  Damago
//
//  Created by loyH on 1/27/26.
//

import Combine
import Foundation

final class CollectionViewModel: ViewModel {
    let title = "컬렉션"

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
    }

    struct State {
        var pets: [DamagoType] = DamagoType.allCases
    }

    var pets: [DamagoType] { DamagoType.allCases }

    func transform(_ input: Input) -> AnyPublisher<State, Never> {
        Just(State(pets: DamagoType.allCases)).eraseToAnyPublisher()
    }
}
