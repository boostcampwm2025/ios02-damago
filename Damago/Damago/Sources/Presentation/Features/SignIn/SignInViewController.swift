//
//  SignInViewController.swift
//  Damago
//
//  Created by 박현수 on 1/13/26.
//

import Combine
import UIKit

final class SignInViewController: UIViewController {
    private let mainView = SignInView()
    private let viewModel: SignInViewModel

    private let alertActionSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: SignInViewModel) {
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
        let output = viewModel.transform(SignInViewModel.Input(
            signInButtonDidTap: mainView.signInButton.tapPublisher,
            alertButtonDidTap: alertActionSubject.eraseToAnyPublisher()
        ))
        bind(output)
    }

    func bind(_ output: SignInViewModel.Output) {
        output
            .pulse(\.errorMessage)
            .sink { [weak self] errorMessage in
                guard let self else { return }
                presentAlert(message: errorMessage)
            }
            .store(in: &cancellables)
    }

    func presentAlert(message: String) {
        let alert = UIAlertController(title: "로그인에 실패했습니다.", message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            guard let self else { return }
            self.alertActionSubject.send(())
        }
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
}
