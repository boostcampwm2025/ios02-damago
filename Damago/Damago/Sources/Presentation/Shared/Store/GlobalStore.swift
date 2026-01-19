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
    var petStatus: AnyPublisher<PetStatus, Never> { get }
    var coupleSharedInfo: AnyPublisher<CoupleSharedInfo, Never> { get }
    
    func startMonitoring(damagoID: String, coupleID: String)
    func stopMonitoring()
}

final class GlobalStore: GlobalStoreProtocol {
    private let observePetStatusUseCase: ObservePetStatusUseCase
    private let observeCoupleSharedInfoUseCase: ObserveCoupleSharedInfoUseCase

    private let petStatusSubject = CurrentValueSubject<PetStatus?, Never>(nil)
    private let coupleSharedInfoSubject = CurrentValueSubject<CoupleSharedInfo?, Never>(nil)

    private var cancellables = Set<AnyCancellable>()

    var petStatus: AnyPublisher<PetStatus, Never> {
        petStatusSubject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    var coupleSharedInfo: AnyPublisher<CoupleSharedInfo, Never> {
        coupleSharedInfoSubject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    init(
        observePetStatusUseCase: ObservePetStatusUseCase,
        observeCoupleSharedInfoUseCase: ObserveCoupleSharedInfoUseCase
    ) {
        self.observePetStatusUseCase = observePetStatusUseCase
        self.observeCoupleSharedInfoUseCase = observeCoupleSharedInfoUseCase
    }

    func startMonitoring(damagoID: String, coupleID: String) {
        stopMonitoring()

        observePetStatusUseCase.execute(damagoID: damagoID)
            .sink { [weak self] result in
                switch result {
                case let .success(status):
                    self?.petStatusSubject.send(status)
                case let .failure(error):
                    SharedLogger.firebase.error("Pet status monitoring failed: \(error)")
                }
            }
            .store(in: &cancellables)

        observeCoupleSharedInfoUseCase.execute(coupleID: coupleID)
            .sink { [weak self] result in
                switch result {
                case let .success(info):
                    self?.coupleSharedInfoSubject.send(info)
                case let .failure(error):
                    SharedLogger.firebase.error("Couple info monitoring failed: \(error)")
                }
            }
            .store(in: &cancellables)
    }

    func stopMonitoring() {
        cancellables.removeAll()
    }
}
