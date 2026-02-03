//
//  DamagoNamingPopupViewController.swift
//  Damago
//
//  Created by 김재영 on 2/2/26.
//

import UIKit
import Combine

final class DamagoNamingPopupViewController: UIViewController {
    private let mainView = DamagoNamingPopupView()
    private let viewModel: DamagoNamingPopupViewModel
    private var cancellables = Set<AnyCancellable>()
    
    let confirmAction = PassthroughSubject<String, Never>()
    let updateInitialNameSubject = PassthroughSubject<String, Never>()
    
    init(viewModel: DamagoNamingPopupViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        // 팝업 스타일 설정
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
    }
    
    private func configureUI() {
        mainView.configureInitialState(
            title: viewModel.mode.titleText,
            placeholder: viewModel.mode.placeholderText,
            confirmTitle: viewModel.mode.confirmButtonTitle,
            confirmDisabledTitle: viewModel.mode.confirmButtonDisabledTitle,
            isEditMode: viewModel.mode == .edit
        )
    }
    
    func configure(with damagoType: DamagoType?) {
        mainView.configure(with: damagoType)
    }
    
    private func bind() {
        let input = DamagoNamingPopupViewModel.Input(
            textChanged: mainView.nameTextField.textPublisher,
            confirmTapped: mainView.confirmButton.tapPublisher,
            cancelTapped: mainView.cancelButton.tapPublisher,
            updateInitialName: updateInitialNameSubject.eraseToAnyPublisher()
        )
        
        let output = viewModel.transform(input)
        
        output.mapForUI { $0.isConfirmEnabled }
            .assign(to: \.isEnabled, on: mainView.confirmButton)
            .store(in: &cancellables)
            
        output.mapForUI { $0.currentName }
            .sink { [weak self] text in
                if self?.mainView.nameTextField.text != text {
                    self?.mainView.nameTextField.text = text
                }
            }
            .store(in: &cancellables)
            
        output.compactMapForUI { $0.confirmAction?.value }
            .sink { [weak self] name in
                self?.confirmAction.send(name)
                self?.dismiss(animated: true)
            }
            .store(in: &cancellables)
            
        output.map { $0.dismissRequest }
            .removeDuplicates()
            .compactMap { $0?.value }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.dismiss(animated: true)
            }
            .store(in: &cancellables)
            
        output.map { $0.requestCancelConfirmation }
            .removeDuplicates()
            .compactMap { $0?.value }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.showCancelAlert()
            }
            .store(in: &cancellables)
    }
    
    private func showCancelAlert() {
        let alert = UIAlertController(
            title: "취소할까요?",
            message: "입력한 내용이 저장되지 않아요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "계속 입력", style: .cancel))
        alert.addAction(UIAlertAction(title: "취소", style: .destructive) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
}
