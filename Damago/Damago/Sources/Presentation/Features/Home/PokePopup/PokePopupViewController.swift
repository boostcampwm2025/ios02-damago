//
//  PokePopupViewController.swift
//  Damago
//
//  Created by loyH on 1/13/26.
//

import UIKit

final class PokePopupViewController: UIViewController {
    private let popupView: PokePopupView
    private let shortcutRepository: PokeShortcutRepositoryProtocol
    
    var onMessageSelected: ((String) -> Void)?
    var onCancel: (() -> Void)?
    
    init(shortcutRepository: PokeShortcutRepositoryProtocol) {
        self.shortcutRepository = shortcutRepository
        self.popupView = PokePopupView(shortcutRepository: shortcutRepository)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = popupView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        popupView.onMessageSelected = { [weak self] message in
            self?.dismiss(animated: true) {
                self?.onMessageSelected?(message)
            }
        }
        
        popupView.onCancel = { [weak self] in
            self?.dismiss(animated: true) {
                self?.onCancel?()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = .clear
    }
}
