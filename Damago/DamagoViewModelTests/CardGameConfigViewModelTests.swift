//
//  CardGameConfigViewModelTests.swift
//  DamagoViewModelTests
//
//  Created by 박현수 on 2/4/26.
//

import Testing
import Combine
import Foundation
@testable import Damago

@MainActor
final class CardGameConfigViewModelTests {
    private var cancellables = Set<AnyCancellable>()
    
    struct TestInput {
        let difficultyChanged = PassthroughSubject<Int, Never>()
        let imagesSelected = PassthroughSubject<[Data], Never>()
        let imageRemoved = PassthroughSubject<Int, Never>()
        let selectPhotoButtonDidTap = PassthroughSubject<Void, Never>()
        let startButtonDidTap = PassthroughSubject<Void, Never>()
        
        var input: CardGameConfigViewModel.Input {
            CardGameConfigViewModel.Input(
                difficultyChanged: difficultyChanged.eraseToAnyPublisher(),
                imagesSelected: imagesSelected.eraseToAnyPublisher(),
                imageRemoved: imageRemoved.eraseToAnyPublisher(),
                selectPhotoButtonDidTap: selectPhotoButtonDidTap.eraseToAnyPublisher(),
                startButtonDidTap: startButtonDidTap.eraseToAnyPublisher()
            )
        }
    }
    
    @Test("초기 상태 검증")
    func testInitialState() async throws {
        let viewModel = CardGameConfigViewModel()
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)
        
        try await withTimeout(seconds: 1.0) {
            var iterator = output.values.makeAsyncIterator()
            if let state = await iterator.next() {
                #expect(state.difficulty == .easy)
                #expect(state.selectedImages.isEmpty == true)
                #expect(state.isValid == false)
            }
        }
    }
    
    @Test("난이도 변경 시 선택된 이미지 초기화 및 난이도 업데이트")
    func testDifficultyChange() async throws {
        let viewModel = CardGameConfigViewModel()
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)

        try await withTimeout(seconds: 1.0) {
            // When: 이미지 추가
            var iterator = output.values.makeAsyncIterator()
            testInput.imagesSelected.send([Data([0x01])])

            // Then: 이미지 추가 확인
            while let state = await iterator.next() {
                if await state.selectedImages.count == 1 {
                    #expect(state.selectedImages.count == 1)
                    return
                }
            }

            // When: 난이도 변경 (Hard)
            testInput.difficultyChanged.send(1)
            // Then: 초기화 확인
            while let state = await iterator.next() {
                if await state.difficulty == .hard {
                    #expect(state.selectedImages.isEmpty == true)
                    return
                }
            }
        }
    }
    
    @Test("이미지 추가 및 삭제")
    func testImageSelectionAndRemoval() async throws {
        let viewModel = CardGameConfigViewModel()
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)
        
        let dummyData1 = Data([0x01])
        let dummyData2 = Data([0x02])

        try await withTimeout(seconds: 1.0) {
            var iterator = output.values.makeAsyncIterator()
            _ = await iterator.next()

            // When: 이미지 2개 추가
            testInput.imagesSelected.send([dummyData1, dummyData2])

            while let state = await iterator.next() {
                if await state.selectedImages.count == 2 {
                    #expect(state.selectedImages == [dummyData1, dummyData2])
                    return
                }
            }

            testInput.imageRemoved.send(0)

            while let state = await iterator.next() {
                if await state.selectedImages.count == 1 {
                    #expect(state.selectedImages == [dummyData2])
                    return
                }
            }
        }
    }
    
    @Test("Easy 난이도에서 4장(2쌍) 선택 시 유효성 검증")
    func testValidationForEasy() async throws {
        let viewModel = CardGameConfigViewModel()
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)

        // When: 4장 선택
        let dummyImages = (0..<4).map { Data([UInt8($0)]) }

        try await withTimeout(seconds: 1.0) {
            var iterator = output.values.makeAsyncIterator()
            testInput.imagesSelected.send(dummyImages)

            while let state = await iterator.next() {
                if await state.isValid {
                    #expect(state.isValid == true)
                    return
                }
            }
        }
    }
    
    @Test("게임 시작 버튼 클릭 시 Route 발생")
    func testStartGameRoute() async throws {
        let viewModel = CardGameConfigViewModel()
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)
        

        // Given: 유효한 상태 만들기 (4장 선택)
        let dummyImages = (0..<4).map { Data([UInt8($0)]) }

        // Then: Route 확인
        try await withTimeout(seconds: 1.0) {
            var iterator = output.values.makeAsyncIterator()
            testInput.imagesSelected.send(dummyImages)
            // When: 시작 버튼 탭
            testInput.startButtonDidTap.send()

            while let state = await iterator.next() {
                if let route = await state.route?.value, case .startGame = route {
                    #expect(true)
                    return
                }
            }
        }
    }
}
