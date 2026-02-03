//
//  UseCaseAssembly.swift
//  Damago
//
//  Created by 박현수 on 1/13/26.
//

final class UseCaseAssembly: Assembly {
    func assemble(_ container: any DIContainer) {
        container.register(SignInUseCase.self) {
            SignInUseCaseImpl(repository: container.resolve(UserRepositoryProtocol.self))
        }
        container.register(FetchCodeUseCase.self) {
            FetchCodeUseCaseImpl(userRepository: container.resolve(UserRepositoryProtocol.self))
        }
        container.register(FetchUserInfoUseCase.self) {
            FetchUserInfoUseCaseImpl(userRepository: container.resolve(UserRepositoryProtocol.self))
        }
        container.register(ConnectCoupleUseCase.self) {
            ConnectCoupleUseCaseImpl(userRepository: container.resolve(UserRepositoryProtocol.self))
        }
        container.register(FetchDailyQuestionUseCase.self) {
            FetchDailyQuestionUseCaseImpl(
                dailyQuestionRepository: container.resolve(DailyQuestionRepositoryProtocol.self)
            )
        }
        container.register(SubmitDailyQuestionAnswerUseCase.self) {
            SubmitDailyQuestionAnswerUseCaseImpl(
                dailyQuestionRepository: container.resolve(DailyQuestionRepositoryProtocol.self)
            )
        }
        container.register(ObserveDailyQuestionAnswerUseCase.self) {
            ObserveDailyQuestionAnswerUseCaseImpl(
                dailyQuestionRepository: container.resolve(DailyQuestionRepositoryProtocol.self)
            )
        }
        container.register(SignOutUseCase.self) {
            SignOutUseCaseImpl(repository: container.resolve(UserRepositoryProtocol.self))
        }
        container.register(ObserveGlobalStateUseCase.self) {
            ObserveGlobalStateUseCaseImpl(
                userRepository: container.resolve(UserRepositoryProtocol.self),
                damagoRepository: container.resolve(DamagoRepositoryProtocol.self)
            )
        }
        container.register(SignOutUseCase.self) {
            SignOutUseCaseImpl(
                repository: container.resolve(UserRepositoryProtocol.self)
            )
        }
        container.register(UpdateFCMTokenUseCase.self) {
            UpdateFCMTokenUseCaseImpl(userRepository: container.resolve(UserRepositoryProtocol.self))
        }
        container.register(UpdateUserUseCase.self) {
            UpdateUserUseCaseImpl(
                userRepository: container.resolve(UserRepositoryProtocol.self)
            )
        }
        
        container.register(FetchBalanceGameUseCase.self) {
            FetchBalanceGameUseCaseImpl(
                repository: container.resolve(BalanceGameRepositoryProtocol.self)
            )
        }
        
        container.register(SubmitBalanceGameChoiceUseCase.self) {
            SubmitBalanceGameChoiceUseCaseImpl(
                repository: container.resolve(BalanceGameRepositoryProtocol.self)
            )
        }
        
        container.register(ObserveBalanceGameAnswerUseCase.self) {
            ObserveBalanceGameAnswerUseCaseImpl(
                repository: container.resolve(BalanceGameRepositoryProtocol.self)
            )
        }

        container.register(WithdrawUseCase.self) {
            WithdrawUseCaseImpl(userRepository: container.resolve(UserRepositoryProtocol.self))
        }
        container.register(CheckConnectionUseCase.self) {
            CheckConnectionUseCaseImpl(userRepository: container.resolve(UserRepositoryProtocol.self))
        }
        container.register(ManageDailyQuestionDraftAnswerUseCase.self) {
            ManageDailyQuestionDraftAnswerUseCaseImpl(
                localDataSource: container.resolve(DailyQuestionLocalDataSourceProtocol.self)
            )
        }
        container.register(FetchDailyQuestionsHistoryUseCase.self) {
            FetchDailyQuestionsHistoryUseCaseImpl(repository: container.resolve(HistoryRepositoryProtocol.self))
        }
        container.register(FetchBalanceGamesHistoryUseCase.self) {
            FetchBalanceGamesHistoryUseCaseImpl(repository: container.resolve(HistoryRepositoryProtocol.self))
        }
        container.register(AdjustCoinAmountUseCase.self) {
            AdjustCoinAmountUseCaseImpl(userRepository: container.resolve(UserRepositoryProtocol.self))
        }
        
        container.register(SaveLiveActivityTokenUseCase.self) {
            SaveLiveActivityTokenUseCaseImpl(repository: container.resolve(PushRepositoryProtocol.self))
        }
        
        container.register(ObserveDamagoSnapshotUseCase.self) {
            ObserveDamagoSnapshotUseCaseImpl(repository: container.resolve(DamagoRepositoryProtocol.self))
        }
        
        container.register(GetPokeShortcutsUseCase.self) {
            GetPokeShortcutsUseCaseImpl(repository: container.resolve(PokeShortcutRepositoryProtocol.self))
        }
        
        container.register(UpdatePokeShortcutUseCase.self) {
            UpdatePokeShortcutUseCaseImpl(repository: container.resolve(PokeShortcutRepositoryProtocol.self))
        }
        
        container.register(FeedDamagoUseCase.self) {
            FeedDamagoUseCaseImpl(repository: container.resolve(DamagoRepositoryProtocol.self))
        }
        
        container.register(PokeDamagoUseCase.self) {
            PokeDamagoUseCaseImpl(repository: container.resolve(PushRepositoryProtocol.self))
        }
    }
}
