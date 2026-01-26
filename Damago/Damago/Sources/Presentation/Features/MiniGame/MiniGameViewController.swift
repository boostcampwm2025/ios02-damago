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
}
