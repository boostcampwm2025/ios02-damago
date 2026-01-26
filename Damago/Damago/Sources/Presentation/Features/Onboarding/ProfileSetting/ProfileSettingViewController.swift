//
//  ProfileSettingViewController.swift
//  Damago
//
//  Created by 김재영 on 1/26/26.
//

import Combine
import UIKit

final class ProfileSettingViewController: UIViewController {
    private let mainView = EditProfileView()
    private let viewModel: ProfileSettingViewModel
    private let confirmNextPublisher = PassthroughSubject<Void, Never>()
    
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: ProfileSettingViewModel) {
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
        setupUI()
        bind()
    }
    
    private func setupNavigation() {
        navigationItem.title = "프로필 설정"
        navigationItem.hidesBackButton = true
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    private func setupUI() {
        updateButtonStyle(false)
    }
    
    private func bind() {
        let input = ProfileSettingViewModel.Input(
            nicknameChanged: mainView.nicknameTextField.textPublisher,
            dateChanged: mainView.datePicker.datePublisher,
            nextButtonDidTap: confirmNextPublisher.eraseToAnyPublisher()
        )
        
        mainView.saveButton.tapPublisher
            .sink { [weak self] in
                self?.showConfirmAlert()
            }
            .store(in: &cancellables)
        
        let output = viewModel.transform(input)
        
        output
            .mapForUI { $0.nickname }
            .sink { [weak self] nickname in
                if self?.mainView.nicknameTextField.text != nickname {
                    self?.mainView.nicknameTextField.text = nickname
                }
            }
            .store(in: &cancellables)
            
        output
            .compactMapForUI { $0.anniversaryDate }
            .sink { [weak self] date in
                if self?.mainView.datePicker.date != date {
                    self?.mainView.datePicker.date = date
                }
            }
            .store(in: &cancellables)
        
        output
            .mapForUI { $0.isNextEnabled }
            .sink { [weak self] isEnabled in
                self?.updateButtonStyle(isEnabled)
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
                case .petSetup:
                    self?.navigateToPetSetup()
                case .partnerAlreadySelected:
                    self?.showPartnerSelectedAlert()
                case .error(let message):
                    self?.presentAlert(message: message)
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateButtonStyle(_ isEnabled: Bool) {
        mainView.updateSaveButton(isEnabled: isEnabled)
        mainView.saveButton.setTitle("다음") 
    }
    
    private func navigateToPetSetup() {
        let updateUserUseCase = AppDIContainer.shared.resolve(UpdateUserUseCase.self)
        let vm = PetSetupViewModel(updateUserUseCase: updateUserUseCase)
        let vc = PetSetupViewController(viewModel: vm)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func showPartnerSelectedAlert() {
        let alert = UIAlertController(
            title: "다마고 탄생!",
            message: "상대방이 이미 다마고를 결정했습니다.\n함께 다마고를 키워보세요!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "시작하기", style: .default) { _ in
            UserDefaults.standard.set(true, forKey: "isOnboardingCompleted")
            NotificationCenter.default.post(name: .authenticationStateDidChange, object: nil)
        })
        present(alert, animated: true)
    }
    
    private func showConfirmAlert() {
        let nickname = mainView.nicknameTextField.text ?? ""
        let alert = UIAlertController(
            title: "닉네임 결정",
            message: "\"\(nickname)\"으로 결정하시겠습니까?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            self?.confirmNextPublisher.send(())
        })
        present(alert, animated: true)
    }
    
    private func presentAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
