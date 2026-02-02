//
//  DamagoSetupViewController.swift
//  Damago
//
//  Created by 김재영 on 1/26/26.
//

import UIKit
import Combine

final class DamagoSetupViewController: UIViewController {
    private let mainView = DamagoSetupView()
    private let viewModel: DamagoSetupViewModel
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let damagoSelectedPublisher = PassthroughSubject<DamagoType, Never>()
    private let confirmButtonTappedPublisher = PassthroughSubject<String, Never>()
    
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: DamagoSetupViewModel) {
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
        setupCollectionView()
        bind()
        viewDidLoadPublisher.send()
    }
    
    private func setupNavigation() {
        navigationItem.title = "우리의 다마고 선택"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.tintColor = .damagoPrimary
        navigationItem.hidesBackButton = false
    }
    
    private func setupCollectionView() {
        mainView.collectionView.dataSource = self
        mainView.collectionView.delegate = self
    }
    
    private func bind() {
        let input = DamagoSetupViewModel.Input(
            viewDidLoad: viewDidLoadPublisher.eraseToAnyPublisher(),
            damagoSelected: damagoSelectedPublisher.eraseToAnyPublisher(),
            confirmButtonTapped: confirmButtonTappedPublisher.eraseToAnyPublisher()
        )
        
        let output = viewModel.transform(input)
        
        output
            .pulse(\.route)
            .sink { [weak self] route in
                self?.handleRoute(route)
            }
            .store(in: &cancellables)
    }
    
    private func handleRoute(_ route: DamagoSetupViewModel.Route) {
        switch route {
        case .home:
            NotificationCenter.default.post(name: .authenticationStateDidChange, object: nil)
        case .showPopup(let damagoType):
            showNamingPopup(for: damagoType)
        case .error(let title, let message):
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
        }
    }
    
    private func showNamingPopup(for damagoType: DamagoType) {
        let popupView = DamagoNamingPopupView()
        popupView.configure(
            mode: .onboarding,
            damagoType: damagoType,
            initialName: viewModel.prefillName(for: damagoType)
        )
        popupView.translatesAutoresizingMaskIntoConstraints = false
        
        guard let targetView = navigationController?.view ?? view else { return }
        targetView.addSubview(popupView)
        
        NSLayoutConstraint.activate([
            popupView.topAnchor.constraint(equalTo: targetView.topAnchor),
            popupView.leadingAnchor.constraint(equalTo: targetView.leadingAnchor),
            popupView.trailingAnchor.constraint(equalTo: targetView.trailingAnchor),
            popupView.bottomAnchor.constraint(equalTo: targetView.bottomAnchor)
        ])
        
        popupView.confirmButtonTappedSubject
            .sink { [weak self, weak popupView] name in
                self?.viewModel.selectDamago(damagoType)
                self?.confirmButtonTappedPublisher.send(name)
                popupView?.removeFromSuperview()
            }
            .store(in: &cancellables)

        // 선택한 타입의 기존 이름이 있으면 Firestore에서 가져와 prefill
        viewModel.observePrefillName(for: damagoType)
            .receive(on: DispatchQueue.main)
            .prefix(1)
            .sink { [weak popupView] name in
                popupView?.updateInitialName(name)
            }
            .store(in: &cancellables)
            
        popupView.cancelButtonTappedSubject
            .sink { [weak popupView] in
                popupView?.removeFromSuperview()
            }
            .store(in: &cancellables)
            
        popupView.requestCancelConfirmationSubject
            .sink { [weak self, weak popupView] in
                self?.showCancelConfirmationAlert {
                    popupView?.removeFromSuperview()
                }
            }
            .store(in: &cancellables)
            
        popupView.alpha = 0
        UIView.animate(withDuration: 0.2) {
            popupView.alpha = 1
        }
    }
    
    private func showCancelConfirmationAlert(confirmHandler: @escaping () -> Void) {
        let alert = UIAlertController(
            title: "작성 중인 내용이 있습니다",
            message: "정말 나가시겠습니까?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "계속 작성", style: .cancel))
        alert.addAction(UIAlertAction(title: "나가기", style: .destructive) { _ in
            confirmHandler()
        })
        
        present(alert, animated: true)
    }
}

extension DamagoSetupViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        DamagoType.allCases.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: DamagoCell.reuseIdentifier,
            for: indexPath
        ) as? DamagoCell else {
            return UICollectionViewCell()
        }
        let damagoType = DamagoType.allCases[indexPath.item]
        cell.configure(with: damagoType)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let damagoType = DamagoType.allCases[indexPath.item]
        damagoSelectedPublisher.send(damagoType)
    }
}
