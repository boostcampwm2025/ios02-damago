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

    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: ConnectionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let input = ConnectionViewModel.Input(
            viewDidLoad: viewDidLoadPublisher.eraseToAnyPublisher(),
            copyButtonDidTap: mainView.copyButton.tapPublisher,
            textfieldValueDidChange: mainView.opponentCodeTextField.textPublisher,
            shareButtonDidTap: mainView.shareButton.tapPublisher
        )
        let output = viewModel.transform(input)
        bind(output)
        viewDidLoadPublisher.send()
    }

    private func bind(_ output: ConnectionViewModel.Output) {

    }
}
