//
//  GlobalStore.swift
//  Damago
//
//  Created by 박현수 on 1/19/26.
//

import Combine
import Foundation
import OSLog

protocol GlobalStoreProtocol {
    var globalState: AnyPublisher<GlobalState, Never> { get }
    
    func startMonitoring(uid: String)
    func stopMonitoring()
}

final class GlobalStore: GlobalStoreProtocol {
    private let observeGlobalStateUseCase: ObserveGlobalStateUseCase
    private let globalStateSubject = CurrentValueSubject<GlobalState, Never>(.empty)
    private var cancellables = Set<AnyCancellable>()

    var globalState: AnyPublisher<GlobalState, Never> {
        globalStateSubject.eraseToAnyPublisher()
    }

    init(observeGlobalStateUseCase: ObserveGlobalStateUseCase) {
        self.observeGlobalStateUseCase = observeGlobalStateUseCase
    }

    func startMonitoring(uid: String) {
        stopMonitoring()

        observeGlobalStateUseCase.execute(uid: uid)
            .sink { [weak self] newState in
                self?.globalStateSubject.send(newState)
            }
            .store(in: &cancellables)
    }

    func stopMonitoring() {
        cancellables.removeAll()
    }
}

