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

    private var ownedDamagos: [DamagoType: Int]?

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
                guard let self else { return }
                self.triggerGachaAnimation(result: result)
            }
            .store(in: &cancellables)

        output
            .map { $0.ownedDamagos }
            .assign(to: \.ownedDamagos, on: self)
            .store(in: &cancellables)
        
        output
            .pulse(\.error)
            .sink { [weak self] error in
                self?.showErrorAlert(message: error.localizedDescription)
            }
            .store(in: &cancellables)
            
        output
            .mapForUI { $0.isDrawButtonEnabled }
            .sink { [weak self] isEnabled in
                self?.mainView.drawButton.isEnabled = isEnabled
            }
            .store(in: &cancellables)
            
        output
            .mapForUI { $0.drawButtonTitle }
            .sink { [weak self] title in
                self?.mainView.drawButton.setTitle(title)
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
    
    private func triggerGachaAnimation(result: DrawResult) {
        mainView.machineImageView.isHidden = true
        mainView.drawButton.isEnabled = false
        mainView.exitButton.isHidden = true
        
        let animationView = GachaAnimationView()
        animationView.onFinish = { [weak self] in
            guard let self else { return }
            
            self.showResultOverlay(result: result)
            
            animationView.removeFromSuperview()
            
            self.mainView.machineImageView.isHidden = false
            self.mainView.drawButton.isEnabled = self.viewModel.state.isDrawButtonEnabled
            self.mainView.exitButton.isHidden = false
        }
        
        mainView.addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            animationView.topAnchor.constraint(equalTo: mainView.topAnchor),
            animationView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor),
            animationView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor)
        ])
        
        animationView.startAnimation()
    }
    
    private func showResultOverlay(result: DrawResult) {
        mainView.resultView.configure(with: result)
        
        UIView.animate(withDuration: 0.3) {
            self.mainView.resultView.alpha = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.hideResultOverlay()
        }
    }
    
    private func hideResultOverlay() {
        UIView.animate(withDuration: 0.3) {
            self.mainView.resultView.alpha = 0
        }
    }
}
