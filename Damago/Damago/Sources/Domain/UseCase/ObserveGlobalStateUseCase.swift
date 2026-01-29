//
//  ObserveGlobalStateUseCase.swift
//  Damago
//
//  Created by 박현수 on 1/21/26.
//

import Combine
import Foundation

protocol ObserveGlobalStateUseCase {
    func execute(uid: String) -> AnyPublisher<GlobalState, Never>
}

final class ObserveGlobalStateUseCaseImpl: ObserveGlobalStateUseCase {
    private let userRepository: UserRepositoryProtocol
    private let petRepository: PetRepositoryProtocol
    
    init(
        userRepository: UserRepositoryProtocol,
        petRepository: PetRepositoryProtocol
    ) {
        self.userRepository = userRepository
        self.petRepository = petRepository
    }
    
    func execute(uid: String) -> AnyPublisher<GlobalState, Never> {
        userRepository.observeUserSnapshot(uid: uid)
            .map { result -> AnyPublisher<GlobalState, Never> in
                switch result {
                case let .success(userSnapshot):
                    return self.combineSnapshots(userSnapshot: userSnapshot)
                case .failure:
                    return Just(GlobalState.empty).eraseToAnyPublisher()
                }
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
    
    private func combineSnapshots(userSnapshot: UserSnapshotDTO) -> AnyPublisher<GlobalState, Never> {
        let coupleStream: AnyPublisher<CoupleSnapshotDTO?, Never>
        if let coupleID = userSnapshot.coupleID {
            coupleStream = userRepository.observeCoupleSnapshot(coupleID: coupleID)
                .map { try? $0.get() }
                .replaceError(with: nil)
                .prepend(nil)
                .eraseToAnyPublisher()
        } else {
            coupleStream = Just(nil).eraseToAnyPublisher()
        }
        
        let petStream: AnyPublisher<PetSnapshotDTO?, Never>
        if let damagoID = userSnapshot.damagoID {
            petStream = petRepository.observePetSnapshot(damagoID: damagoID)
                .map { try? $0.get() }
                .replaceError(with: nil)
                .prepend(nil)
                .eraseToAnyPublisher()
        } else {
            petStream = Just(nil).eraseToAnyPublisher()
        }

        let partnerStream: AnyPublisher<UserSnapshotDTO?, Never>
        if let partnerUID = userSnapshot.partnerUID {
            partnerStream = userRepository.observeUserSnapshot(uid: partnerUID)
                .map { try? $0.get() }
                .replaceError(with: nil)
                .prepend(nil)
                .eraseToAnyPublisher()
        } else {
            partnerStream = Just(nil).eraseToAnyPublisher()
        }
        
        return Publishers.CombineLatest3(coupleStream, petStream, partnerStream)
            .map { coupleSnapshot, petSnapshot, partnerSnapshot in
                GlobalState(
                    nickname: userSnapshot.nickname,
                    opponentName: partnerSnapshot?.nickname,
                    useFCM: userSnapshot.useFCM,
                    useLiveActivity: userSnapshot.useLiveActivity,
                    // coupleSnapshot이 아직 로드되지 않았을 때(prepend(nil) 등) userSnapshot.coupleID로
                    // 폴백하여, 다마고 변경 등으로 스트림이 재생성될 때 잘못된 "연결 해제" 감지를 방지
                    coupleID: coupleSnapshot?.id ?? userSnapshot.coupleID,
                    totalCoin: coupleSnapshot?.totalCoin,
                    foodCount: coupleSnapshot?.foodCount,
                    anniversaryDate: coupleSnapshot?.anniversaryDate,
                    currentQuestionID: coupleSnapshot?.currentQuestionID,
                    petName: petSnapshot?.petName,
                    petType: petSnapshot?.petType,
                    level: petSnapshot?.level,
                    currentExp: petSnapshot?.currentExp,
                    maxExp: petSnapshot?.maxExp,
                    isHungry: petSnapshot?.isHungry,
                    statusMessage: petSnapshot?.statusMessage,
                    lastFedAt: petSnapshot?.lastFedAt,
                    totalPlayTime: petSnapshot?.totalPlayTime,
                    lastActiveAt: petSnapshot?.lastActiveAt
                )
            }
            .eraseToAnyPublisher()
    }
}
