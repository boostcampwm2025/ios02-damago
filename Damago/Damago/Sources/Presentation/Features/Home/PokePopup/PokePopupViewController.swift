//
//  PokePopupViewController.swift
//  Damago
//
//  Created by loyH on 1/13/26.
//

import UIKit

final class PokePopupViewController: UIViewController {
    private let popupView = PokePopupView()
    
    var onMessageSelected: ((String) -> Void)?
    var onCancel: (() -> Void)?
    
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
