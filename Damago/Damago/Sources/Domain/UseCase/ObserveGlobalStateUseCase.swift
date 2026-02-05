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
    private let damagoRepository: DamagoRepositoryProtocol
    
    init(
        userRepository: UserRepositoryProtocol,
        damagoRepository: DamagoRepositoryProtocol
    ) {
        self.userRepository = userRepository
        self.damagoRepository = damagoRepository
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
        
        let damagoStream: AnyPublisher<DamagoSnapshotDTO?, Never>
        if let damagoID = userSnapshot.damagoID {
            damagoStream = damagoRepository.observeDamagoSnapshot(damagoID: damagoID)
                .map { try? $0.get() }
                .replaceError(with: nil)
                .prepend(nil)
                .eraseToAnyPublisher()
        } else {
            damagoStream = Just(nil).eraseToAnyPublisher()
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
        
        let ownedDamagosStream: AnyPublisher<[DamagoSnapshotDTO], Never>
        if let coupleID = userSnapshot.coupleID {
            ownedDamagosStream = damagoRepository.observeOwnedDamagos(coupleID: coupleID)
                .map { (try? $0.get()) ?? [] }
                .replaceError(with: [])
                .eraseToAnyPublisher()
        } else {
            ownedDamagosStream = Just([]).eraseToAnyPublisher()
        }
        
        return Publishers.CombineLatest4(coupleStream, damagoStream, partnerStream, ownedDamagosStream)
            .map { coupleSnapshot, damagoSnapshot, partnerSnapshot, ownedDamagos in
                GlobalState(
                    nickname: userSnapshot.nickname,
                    opponentName: partnerSnapshot?.nickname,
                    useFCM: userSnapshot.useFCM,
                    useLiveActivity: userSnapshot.useLiveActivity,
                    todayPokeCount: self.calculatePokeCount(userSnapshot: userSnapshot),
                    // coupleSnapshot이 아직 로드되지 않았을 때(prepend(nil) 등) userSnapshot.coupleID로
                    // 폴백하여, 다마고 변경 등으로 스트림이 재생성될 때 잘못된 "연결 해제" 감지를 방지
                    coupleID: coupleSnapshot?.id ?? userSnapshot.coupleID,
                    totalCoin: coupleSnapshot?.totalCoin,
                    foodCount: coupleSnapshot?.foodCount,
                    anniversaryDate: coupleSnapshot?.anniversaryDate,
                    currentQuestionID: coupleSnapshot?.currentQuestionID,
                    damagoID: userSnapshot.damagoID,
                    damagoName: damagoSnapshot?.damagoName,
                    damagoType: damagoSnapshot?.damagoType,
                    level: damagoSnapshot?.level,
                    currentExp: damagoSnapshot?.currentExp,
                    maxExp: damagoSnapshot?.maxExp,
                    isHungry: damagoSnapshot?.isHungry,
                    statusMessage: damagoSnapshot?.statusMessage,
                    lastFedAt: damagoSnapshot?.lastFedAt,
                    totalPlayTime: damagoSnapshot?.totalPlayTime,
                    lastActiveAt: damagoSnapshot?.lastActiveAt,
                    ownedDamagos: Dictionary(
                        uniqueKeysWithValues: ownedDamagos.map { ($0.damagoType, $0.level) }
                    )
                )
            }
            .eraseToAnyPublisher()
    }
    
    private func calculatePokeCount(userSnapshot: UserSnapshotDTO) -> Int {
        guard let lastDate = userSnapshot.lastPokeDate,
              let count = userSnapshot.todayPokeCount else {
            return 0
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        let today = formatter.string(from: Date())
        
        return lastDate == today ? count : 0
    }
}
