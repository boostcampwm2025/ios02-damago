//
//  SignInViewController.swift
//  Damago
//
//  Created by 박현수 on 1/13/26.
//

import UIKit

final class SignInViewController: UIViewController {
    private let mainView = SignInView()
    private let viewModel: SignInViewModel

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
        let output = viewModel.transform(SignInViewModel.Input(signInButtonDidTap: mainView.signInButton.tapPublisher))
        bind(output)
    }

    func bind(_ output: SignInViewModel.Output) {
        
    }
}
