//
//  CardGameConfigViewController.swift
//  Damago
//
//  Created by 박현수 on 1/29/26.
//

import Combine
import PhotosUI
import UIKit

final class CardGameConfigViewController: UIViewController {
    private let mainView = CardGameConfigView()
    private let viewModel: CardGameConfigViewModel
    private var cancellables = Set<AnyCancellable>()

    private let imagesSubject = PassthroughSubject<[UIImage], Never>()
    
    init(viewModel: CardGameConfigViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func setupNavigation() {
        navigationItem.title = "게임 설정"
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    private func bind() {
        let input = CardGameConfigViewModel.Input(
            difficultyChanged: mainView.difficultySegmentedControl.selectedSegmentIndexPublisher,
            imagesSelected: imagesSubject.eraseToAnyPublisher(),
            imageRemoved: mainView.removeImagePublisher,
            selectPhotoButtonDidTap: mainView.selectPhotoButton.tapPublisher,
            startButtonDidTap: mainView.startButton.tapPublisher
        )
        
        let output = viewModel.transform(input)
        
        output
            .mapForUI(\.instructionText)
            .assign(to: \.text, on: mainView.instructionLabel)
            .store(in: &cancellables)
            
        output
            .mapForUI(\.countText)
            .assign(to: \.text, on: mainView.photoCountLabel)
            .store(in: &cancellables)
            
        output
            .mapForUI(\.isValid)
            .sink { [weak self] isValid in
                self?.mainView.startButton.isEnabled = isValid
            }
            .store(in: &cancellables)
            
        output
            .mapForUI(\.selectedImages)
            .sink { [weak self] images in
                self?.mainView.updateSelectedImages(images)
            }
            .store(in: &cancellables)
            
        output
            .mapForUI(\.remainingImageCount)
            .sink { [weak self] count in
                self?.mainView.selectPhotoButton.isEnabled = count > 0
            }
            .store(in: &cancellables)
            
        output
            .pulse(\.route)
            .sink { [weak self] route in
                switch route {
                case let .showImagePicker(limit):
                    self?.presentImagePicker(limit: limit)
                case let .startGame(difficulty, images):
                    self?.navigateToGame(difficulty: difficulty, images: images)
                }
            }
            .store(in: &cancellables)
    }
    
    private func presentImagePicker(limit: Int) {
        var config = PHPickerConfiguration()
        config.selectionLimit = limit
        config.filter = .images

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        self.present(picker, animated: true)
    }
    
    private func navigateToGame(difficulty: CardGameDifficulty, images: [UIImage]) {
        let adjustCoinUseCase = AppDIContainer.shared.resolve(AdjustCoinAmountUseCase.self)
        let vm = CardGameViewModel(
            difficulty: difficulty,
            images: images,
            adjustCoinAmountUseCase: adjustCoinUseCase
        )
        let vc = CardGameViewController(viewModel: vm)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension CardGameConfigViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard !results.isEmpty else { return }

        Task {
            let images = await withTaskGroup(of: UIImage?.self) { group in
                for result in results where result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    group.addTask { await self.loadHelper(provider: result.itemProvider) }
                }

                var loadedImages: [UIImage] = []
                for await image in group {
                    if let image = image { loadedImages.append(image) }
                }
                return loadedImages
            }

            imagesSubject.send(images)
        }
    }

    private func loadHelper(provider: NSItemProvider) async -> UIImage? {
        await withCheckedContinuation { continuation in
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                if let image = image as? UIImage {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
