//
//  InteractionViewController.swift
//  Damago
//
//  Created by 김재영 on 1/15/26.
//

import UIKit
import Combine

final class InteractionViewController: UIViewController {
    private let mainView = InteractionView()
    private let viewModel: InteractionViewModel
    
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: InteractionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        
        let output = viewModel.transform(
            InteractionViewModel.Input(
                historyButtonDidTap: mainView.historyButton.tapPublisher
            )
        )
        
        bind(output)
    }
    
    private func setupNavigation() {
        navigationItem.title = "커플 활동"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
    }
    
    private func bind(_ output: InteractionViewModel.Output) {
        output
            .sink { state in
                //
            }
            .store(in: &cancellables)
    }
}
