//
//  MiniGameViewController.swift
//  Damago
//
//  Created by loyH on 1/26/26.
//

import UIKit

final class MiniGameViewController: UIViewController {
    private let mainView = MiniGameView()
    
    override func loadView() {
        view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupGestures()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    private func setupNavigation() {
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.title = ""
        navigationItem.backButtonDisplayMode = .minimal
    }

    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(cardGameDidTap))
        mainView.cardGameCardView.addGestureRecognizer(tap)
    }

    @objc
    private func cardGameDidTap() {
        let vm = CardGameConfigViewModel()
        let vc = CardGameConfigViewController(viewModel: vm)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}
