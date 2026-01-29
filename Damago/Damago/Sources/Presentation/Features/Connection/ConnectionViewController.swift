//
//  ConnectionViewController.swift
//  Damago
//
//  Created by 박현수 on 1/15/26.
//

import Combine
import UIKit

final class ConnectionViewController: UIViewController {
    private let mainView = ConnectionView()
    private let viewModel: ConnectionViewModel
    private let progressView = ProgressView()

    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: ConnectionViewModel) {
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
        setupKeyboard()
        
        let shareButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: nil,
            action: nil
        )
        navigationItem.rightBarButtonItem = shareButton

        let input = ConnectionViewModel.Input(
            viewDidLoad: viewDidLoadPublisher.eraseToAnyPublisher(),
            copyButtonDidTap: mainView.copyButton.tapPublisher,
            textfieldValueDidChange: mainView.opponentCodeTextField.textPublisher,
            shareButtonDidTap: shareButton.tapPublisher,
            connectButtonDidTap: mainView.connectButton.tapPublisher
        )
        let output = viewModel.transform(input)
        bind(output)
        viewDidLoadPublisher.send()
    }
    
    private func setupNavigationBar() {
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationItem.hidesBackButton = true
        navigationController?.navigationBar.tintColor = .damagoPrimary
    }
    
    private func setupKeyboard() {
        mainView.setupKeyboardDismissOnTap()
        mainView.opponentCodeTextField.delegate = self
    }

    private func bind(_ output: ConnectionViewModel.Output) {
        output
            .mapForUI { $0.myCode }
            .sink { [weak self] code in
                guard let self else { return }
                mainView.myCodeLabel.text = code
            }
            .store(in: &cancellables)

        output
            .mapForUI { $0.opponentCode }
            .sink { [weak self] code in
                guard let self else { return }
                mainView.opponentCodeTextField.text = code
            }
            .store(in: &cancellables)

        output
            .mapForUI { $0.isConnectButtonEnabled }
            .sink { [weak self] isEnabled in
                guard let self else { return }
                mainView.updateConnectButton(isEnabled: isEnabled)
            }
            .store(in: &cancellables)

        output
            .pulse(\.route)
            .sink { [weak self] route in
                guard let self else { return }
                switch route {
                case let .alert(message):
                    presentAlert(with: message)
                case let .activity(url):
                    presentActivity(with: url)
                case .editProfile:
                    let userRepository = AppDIContainer.shared.resolve(UserRepositoryProtocol.self)
                    let updateUserUseCase = AppDIContainer.shared.resolve(UpdateUserUseCase.self)
                    let vm = ProfileSettingViewModel(
                        updateUserUseCase: updateUserUseCase,
                        userRepository: userRepository
                    )
                    let vc = ProfileSettingViewController(viewModel: vm)
                    let navigationController = UINavigationController(rootViewController: vc)
                    self.view.window?.replaceRootViewController(with: navigationController)
                }
            }
            .store(in: &cancellables)

        output
            .pulse(\.pasteboardCode)
            .sink { [weak self] code in
                guard let self else { return }
                copyCodeToPasteboard(with: code)
            }
            .store(in: &cancellables)

        output
            .mapForUI { LoadingState(isLoading: $0.isLoading, message: $0.loadingMessage) }
            .sink { [weak self] state in
                guard let self else { return }
                if state.isLoading {
                    progressView.show(in: view, message: state.message)
                } else {
                    progressView.hide()
                }
            }
            .store(in: &cancellables)
    }

    private func presentAlert(with message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "확인", style: .default)
        alert.addAction(confirmAction)
        present(alert, animated: true)
    }

    private func presentActivity(with url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(activityVC, animated: true)
    }

    private func replaceRootVC() {
        NotificationCenter.default.post(name: .authenticationStateDidChange, object: nil)
    }

    private func copyCodeToPasteboard(with code: String) {
        UIPasteboard.general.string = code
    }
}

extension ConnectionViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        // 연결하기 버튼이 활성화되어 있으면 버튼 액션 실행
        if mainView.connectButton.isEnabled {
            mainView.connectButton.sendActions(for: .touchUpInside)
        }
        
        return true
    }
    
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        // 삭제 허용
        guard !string.isEmpty else { return true }
        
        // 영어와 숫자만 허용 (한글, 특수문자 차단)
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        let typed = CharacterSet(charactersIn: string.uppercased())
        guard allowed.isSuperset(of: typed) else { return false }
        
        // 대문자로 변환하여 적용
        guard let text = textField.text,
              let textRange = Range(range, in: text) else { return false }
        
        textField.text = text.replacingCharacters(in: textRange, with: string.uppercased())
        
        // 커서 위치 조정
        let cursorPosition = range.location + string.count
        if let position = textField.position(from: textField.beginningOfDocument, offset: cursorPosition) {
            textField.selectedTextRange = textField.textRange(from: position, to: position)
        }
        
        // 값 변경 이벤트 발생
        textField.sendActions(for: .editingChanged)
        
        return false
    }
}

private extension ConnectionViewController {
    struct LoadingState: Equatable {
        let isLoading: Bool
        let message: String
    }
}
