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
    private var progressView: ProgressView?
    
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
            self?.showProgressView()
            self?.onMessageSelected?(message)
            // 전송 완료 시뮬레이션 (실제로는 네트워크 요청 완료 후 호출)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self?.hideProgressView()
                self?.showSendCompleteAlert {
                    self?.dismiss(animated: true) {
                        self?.onCancel?()
                    }
                }
            }
        }
        
        viewModel.onCancel = { [weak self] in
            self?.dismiss(animated: true) {
                self?.onCancel?()
            }
        }
        
        viewModel.onRequestSendConfirmation = { [weak self] message, confirmHandler in
            self?.showSendConfirmationAlert(message: message, confirmHandler: confirmHandler)
        }
        
        viewModel.onRequestCancelConfirmation = { [weak self] confirmHandler in
            self?.showCancelConfirmationAlert(confirmHandler: confirmHandler)
        }
    }
    
    private func showSendConfirmationAlert(message: String, confirmHandler: @escaping () -> Void) {
        let alert = UIAlertController(
            title: "메시지 전송",
            message: "이 메시지를 전송하시겠어요?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "전송", style: .default) { _ in
            confirmHandler()
        })
        
        present(alert, animated: true)
    }
    
    private func showCancelConfirmationAlert(confirmHandler: @escaping () -> Void) {
        let alert = UIAlertController(
            title: "편집 취소",
            message: "편집 내용이 저장되지 않습니다.\n정말 취소하시겠어요?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "계속 편집", style: .cancel))
        alert.addAction(UIAlertAction(title: "취소", style: .destructive) { _ in
            confirmHandler()
        })
        
        present(alert, animated: true)
    }
    
    private func showProgressView() {
        let progressView = ProgressView()
        progressView.show(in: view, message: "전송 중...")
        self.progressView = progressView
    }
    
    private func hideProgressView() {
        progressView?.hide()
        progressView = nil
    }
    
    private func showSendCompleteAlert(completion: @escaping () -> Void) {
        let alert = UIAlertController(
            title: "전송 완료",
            message: "메시지가 성공적으로 전송되었습니다.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            completion()
        })
        
        present(alert, animated: true)
    }
    
}
