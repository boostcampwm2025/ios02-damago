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
        setupKeyboard()
        let input = ConnectionViewModel.Input(
            viewDidLoad: viewDidLoadPublisher.eraseToAnyPublisher(),
            copyButtonDidTap: mainView.copyButton.tapPublisher,
            textfieldValueDidChange: mainView.opponentCodeTextField.textPublisher,
            shareButtonDidTap: mainView.shareButton.tapPublisher,
            connectButtonDidTap: mainView.connectButton.tapPublisher
        )
        let output = viewModel.transform(input)
        bind(output)
        viewDidLoadPublisher.send()
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
                case .home:
                    replaceRootVC()
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
            .mapForUI { $0.isLoading }
            .sink { [weak self] isLoading in
                guard let self else { return }
                if isLoading {
                    progressView.show(in: view, message: "연결 중...")
                } else {
                    progressView.hide()
                }
            }
            .store(in: &cancellables)
    }

    private func presentAlert(with message: String) {
        let alert = UIAlertController(title: "에러", message: message, preferredStyle: .alert)
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
}
