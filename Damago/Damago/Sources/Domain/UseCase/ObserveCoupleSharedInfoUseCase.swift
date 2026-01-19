//
//  ObserveCoupleSharedInfoUseCase.swift
//  Damago
//
//  Created by 박현수 on 1/19/26.
//

import Combine

protocol ObserveCoupleSharedInfoUseCase {
    func execute(coupleID: String) -> AnyPublisher<Result<CoupleSharedInfo, Error>, Never>
}

final class ObserveCoupleSharedInfoUseCaseImpl: ObserveCoupleSharedInfoUseCase {
    private let userRepository: UserRepositoryProtocol
    
    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }
    
    func execute(coupleID: String) -> AnyPublisher<Result<CoupleSharedInfo, Error>, Never> {
        return userRepository.observeCoupleSharedInfo(coupleID: coupleID)
    }
}
