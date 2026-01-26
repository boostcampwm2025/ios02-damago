//
//  EditProfileViewController.swift
//  Damago
//
//  Created by 박현수 on 1/21/26.
//

import Combine
import UIKit

final class EditProfileViewController: UIViewController {
    private let mainView = EditProfileView()
    private let viewModel: EditProfileViewModel
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: EditProfileViewModel) {
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
        setupNavigationBar()
        bind()
    }
    
    private func setupNavigationBar() {
        navigationItem.title = "프로필 수정"
        navigationController?.navigationBar.tintColor = .damagoPrimary
    }
    
    private func bind() {
        let input = EditProfileViewModel.Input(
            viewDidLoad: Just(()).eraseToAnyPublisher(),
            nicknameChanged: mainView.nicknameTextField.textPublisher,
            dateChanged: mainView.datePicker.datePublisher,
            saveButtonDidTap: mainView.saveButton.tapPublisher
        )
        
        let output = viewModel.transform(input)
        
        output
            .mapForUI { $0.nickname }
            .sink { [weak self] nickname in
                self?.mainView.nicknameTextField.text = nickname
            }
            .store(in: &cancellables)
            
        output
            .compactMapForUI { $0.anniversaryDate }
            .sink { [weak self] date in
                self?.mainView.datePicker.date = date
            }
            .store(in: &cancellables)
            
        output
            .mapForUI { $0.isSaveEnabled }
            .sink { [weak self] isEnabled in
                self?.mainView.updateSaveButton(isEnabled: isEnabled)
            }
            .store(in: &cancellables)

        output
            .mapForUI { $0.isUpdating }
            .sink { [weak self] isUpdating in
                self?.mainView.setIsUpdating(isUpdating)
            }
            .store(in: &cancellables)

        output
            .pulse(\.route)
            .sink { [weak self] route in
                switch route {
                case .back:
                    self?.navigationController?.popViewController(animated: true)
                case .error(let message):
                    self?.presentAlert(message: message)
                }
            }
            .store(in: &cancellables)
    }

    private func presentAlert(message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
