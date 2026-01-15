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
    
    private var isNavigationBarHidden = true
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
        setupDelegate()
        
        let output = viewModel.transform(
            InteractionViewModel.Input(
                historyButtonDidTap: mainView.historyButton.tapPublisher
            )
        )
        
        bind(output)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    private func setupNavigation() {
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.title = ""
    }
    
    private func setupDelegate() {
        mainView.scrollView.delegate = self
    }
    
    private func bind(_ output: InteractionViewModel.Output) {
        output
            .sink { state in
                //
            }
            .store(in: &cancellables)
    }
}

// MARK: - UIScrollViewDelegate
extension InteractionViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let threshold: CGFloat = 40
        let scrollY = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        
        if scrollY > threshold {
            if isNavigationBarHidden {
                navigationController?.setNavigationBarHidden(false, animated: true)
                navigationItem.title = "커플 활동"
                isNavigationBarHidden = false
            }
        } else {
            if !isNavigationBarHidden {
                navigationController?.setNavigationBarHidden(true, animated: true)
                navigationItem.title = ""
                isNavigationBarHidden = true
            }
        }
        
        let fadeThreshold: CGFloat = 50
        let alpha = max(0, min(1, 1 - (scrollY / fadeThreshold)))
        mainView.setSubtitleAlpha(alpha)
    }
}
