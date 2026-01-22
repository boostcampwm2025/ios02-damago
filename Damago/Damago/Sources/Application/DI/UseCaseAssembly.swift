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
        container.register(ObservePetStatusUseCase.self) {
            ObservePetStatusUseCaseImpl(petRepository: container.resolve(PetRepositoryProtocol.self))
        }
        container.register(ObserveCoupleSharedInfoUseCase.self) {
            ObserveCoupleSharedInfoUseCaseImpl(userRepository: container.resolve(UserRepositoryProtocol.self))
        }
        container.register(SignOutUseCase.self) {
            SignOutUseCaseImpl(repository: container.resolve(UserRepositoryProtocol.self))
        }
        container.register(UpdateFCMTokenUseCase.self) {
            UpdateFCMTokenUseCaseImpl(userRepository: container.resolve(UserRepositoryProtocol.self))
        }
    }
}
