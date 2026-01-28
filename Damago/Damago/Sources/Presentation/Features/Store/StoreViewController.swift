//
//  StoreViewController.swift
//  Damago
//
//  Created by 김재영 on 1/28/26.
//

import Combine
import UIKit
import SwiftUI

final class StoreViewController: UIViewController {
    private let mainView = StoreView()
    private let viewModel: StoreViewModel
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: StoreViewModel) {
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
        
        let input = StoreViewModel.Input(
            drawButtonDidTap: mainView.drawButton.tapPublisher
        )
        let output = viewModel.transform(input)
        
        bind(output)
        setupActions()
    }

    private func bind(_ output: StoreViewModel.Output) {
        output
            .mapForUI { $0.coinAmount }
            .sink { [weak self] coin in
                self?.mainView.configure(coins: coin)
            }
            .store(in: &cancellables)
        
        output
            .compactMapForUI { $0.drawResult }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard let self = self else { return }
                self.triggerGachaAnimation(result: result)
            }
            .store(in: &cancellables)
        
        output
            .compactMapForUI { $0.error }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                self?.showErrorAlert(message: errorMessage)
            }
            .store(in: &cancellables)
    }

    private func setupActions() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleOverlayTap))
        mainView.resultView.addGestureRecognizer(tapGesture)
        
        mainView.exitButton.tapPublisher
            .sink { [weak self] in
                self?.dismiss(animated: true)
            }
            .store(in: &cancellables)
    }
    
    @objc
    private func handleOverlayTap() {
        hideResultOverlay()
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func triggerGachaAnimation(result: StoreViewModel.DrawResult) {
        mainView.machineImageView.isHidden = true
        mainView.drawButton.isEnabled = false
        mainView.exitButton.isHidden = true
        
        var hostingController: UIHostingController<GachaAnimationView>?
        
        let animationView = GachaAnimationView { [weak self] in
            self?.showResultOverlay(result: result)
            
            hostingController?.willMove(toParent: nil)
            hostingController?.view.removeFromSuperview()
            hostingController?.removeFromParent()
            hostingController = nil
            
            self?.mainView.machineImageView.isHidden = false
            self?.mainView.drawButton.isEnabled = true
            self?.mainView.exitButton.isHidden = false
        }
        
        hostingController = UIHostingController(rootView: animationView)
        guard let hostingView = hostingController?.view else { return }
        
        hostingView.backgroundColor = .clear
        hostingView.frame = mainView.bounds
        
        addChild(hostingController!)
        mainView.addSubview(hostingView)
        
        hostingController?.didMove(toParent: self)
    }
    
    private func showResultOverlay(result: StoreViewModel.DrawResult) {
        mainView.resultView.configure(with: result)
        
        UIView.animate(withDuration: 0.3) {
            self.mainView.resultView.alpha = 1.0
        }
    }
    
    private func hideResultOverlay() {
        UIView.animate(withDuration: 0.3) {
            self.mainView.resultView.alpha = 0
        }
    }
}
