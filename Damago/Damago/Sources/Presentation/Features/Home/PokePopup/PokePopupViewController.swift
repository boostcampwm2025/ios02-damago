//
//  PokePopupViewController.swift
//  Damago
//
//  Created by loyH on 1/13/26.
//

import Combine
import UIKit

final class PokePopupViewController: UIViewController {
    private let popupView = PokePopupView()
    private let viewModel: PokePopupViewModel
    
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    
    var onMessageSelected: ((String) -> Void)?
    var onCancel: (() -> Void)?
    
    init(shortcutRepository: PokeShortcutRepositoryProtocol) {
        self.viewModel = PokePopupViewModel(shortcutRepository: shortcutRepository)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = popupView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let output = viewModel.transform(
            PokePopupViewModel.Input(
                viewDidLoad: viewDidLoadPublisher.eraseToAnyPublisher(),
                shortcutSelected: popupView.shortcutSelectedSubject.eraseToAnyPublisher(),
                textChanged: popupView.customTextField.textPublisher,
                sendButtonTapped: popupView.sendButton.tapPublisher,
                cancelButtonTapped: popupView.cancelButton.tapPublisher,
                editButtonTapped: popupView.editButton.tapPublisher,
                shortcutSummaryChanged: popupView.shortcutSummaryChangedSubject.eraseToAnyPublisher(),
                shortcutMessageChanged: popupView.shortcutMessageChangedSubject.eraseToAnyPublisher(),
                saveButtonTapped: popupView.saveButton.tapPublisher
            )
        )
        
        bind(output)
        setupViewModelCallbacks()
        
        viewDidLoadPublisher.send()
    }
    
    private func bind(_ output: PokePopupViewModel.Output) {
        output
            .sink { [weak self] state in
                self?.popupView.updateUI(with: state)
            }
            .store(in: &cancellables)
    }
    
    private func setupViewModelCallbacks() {
        viewModel.onMessageSelected = { [weak self] message in
            self?.dismiss(animated: true) {
                self?.onMessageSelected?(message)
            }
        }
        
        viewModel.onCancel = { [weak self] in
            self?.dismiss(animated: true) {
                self?.onCancel?()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = .clear
    }
}
