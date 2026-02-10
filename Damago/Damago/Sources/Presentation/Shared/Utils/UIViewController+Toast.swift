//
//  UIViewController+Toast.swift
//  Damago
//
//  Created by 김재영 on 2/5/26.
//

import UIKit

extension UIViewController {
    func showToast(message: String) {
        let toastContainer = UIView()
        toastContainer.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toastContainer.alpha = 0.0
        toastContainer.layer.cornerRadius = 20
        toastContainer.clipsToBounds = true
        toastContainer.translatesAutoresizingMaskIntoConstraints = false

        let toastLabel = UILabel()
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.font = .body3
        toastLabel.text = message
        toastLabel.numberOfLines = 0
        toastLabel.translatesAutoresizingMaskIntoConstraints = false

        toastContainer.addSubview(toastLabel)
        view.addSubview(toastContainer)

        NSLayoutConstraint.activate([
            toastLabel.topAnchor.constraint(equalTo: toastContainer.topAnchor, constant: 10),
            toastLabel.bottomAnchor.constraint(equalTo: toastContainer.bottomAnchor, constant: -10),
            toastLabel.leadingAnchor.constraint(equalTo: toastContainer.leadingAnchor, constant: 16),
            toastLabel.trailingAnchor.constraint(equalTo: toastContainer.trailingAnchor, constant: -16),

            toastContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100),
            toastContainer.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.8)
        ])

        Task { @MainActor in
            // Fade In
            await UIView.animate(withDuration: 0.3) {
                toastContainer.alpha = 1.0
            }
            
            // Display
            try? await Task.sleep(for: .seconds(1))
            
            // Fade Out
            await UIView.animate(withDuration: 0.3) {
                toastContainer.alpha = 0.0
            }
            
            toastContainer.removeFromSuperview()
        }
    }
}
