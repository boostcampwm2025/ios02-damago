//
//  CardGameConfigViewModel.swift
//  Damago
//
//  Created by 박현수 on 1/29/26.
//

import Combine
import Foundation

final class CardGameConfigViewModel: ViewModel {
    struct Input {
        let difficultyChanged: AnyPublisher<Int, Never>
        let imagesSelected: AnyPublisher<[Data], Never>
        let imageRemoved: AnyPublisher<Int, Never>
        let selectPhotoButtonDidTap: AnyPublisher<Void, Never>
        let startButtonDidTap: AnyPublisher<Void, Never>
    }
    
    struct State {
        var difficulty: CardGameDifficulty = .easy
        var selectedImages: [Data] = []
        var route: Pulse<Route>?

        var isValid: Bool {
            selectedImages.count == (difficulty.cardCount / 2)
        }
        
        var remainingImageCount: Int {
            let requiredCount = difficulty.cardCount / 2
            return max(0, requiredCount - selectedImages.count)
        }

        var instructionText: String {
            let requiredCount = difficulty.cardCount / 2

            if selectedImages.count == requiredCount || selectedImages.isEmpty {
                return ""
            } else if selectedImages.count < requiredCount {
                return "\(requiredCount - selectedImages.count)장의 사진이 더 필요합니다."
            } else {
                return "\(requiredCount)장이 넘는 사진을 선택했습니다."
            }
        }

        var countText: String {
            let requiredCount = difficulty.cardCount / 2
            let currentCount = selectedImages.count

            if currentCount == requiredCount {
                return "완료!"
            } else {
                return "\(currentCount) / \(requiredCount)"
            }
        }
    }
    
    enum Route {
        case showImagePicker(limit: Int)
        case startGame(difficulty: CardGameDifficulty, images: [Data])
    }
    
    @Published private var state = State()
    private var cancellables = Set<AnyCancellable>()
    
    func transform(_ input: Input) -> AnyPublisher<State, Never> {
        input.difficultyChanged
            .mapForUI { $0 == 0 ? CardGameDifficulty.easy : CardGameDifficulty.hard }
            .sink { [weak self] difficulty in
                self?.state.difficulty = difficulty
                self?.state.selectedImages.removeAll()
            }
            .store(in: &cancellables)
        
        input.imagesSelected
            .mapForUI { $0 }
            .sink { [weak self] images in
                self?.state.selectedImages.append(contentsOf: images)
            }
            .store(in: &cancellables)
        
        input.imageRemoved
            .mapForUI { $0 }
            .sink { [weak self] index in
                guard let self = self, self.state.selectedImages.indices.contains(index) else { return }
                self.state.selectedImages.remove(at: index)
            }
            .store(in: &cancellables)
            
        input.selectPhotoButtonDidTap
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                self.state.route = .init(.showImagePicker(limit: self.state.remainingImageCount))
            }
            .store(in: &cancellables)
        
        input.startButtonDidTap
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self, self.state.isValid else { return }
                
                self.state.route = .init(.startGame(difficulty: self.state.difficulty, images: self.state.selectedImages))
            }
            .store(in: &cancellables)
        
        return $state.eraseToAnyPublisher()
    }
}
