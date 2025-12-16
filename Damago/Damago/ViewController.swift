//
//  ViewController.swift
//  Damago
//
//  Created by 김재영 on 12/16/25.
//

import UIKit
import Gifu

@MainActor
final class ViewController: UIViewController {
    private let gifImageView: GIFImageView = {
        let imageView = GIFImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        view.addSubview(gifImageView)
        
        NSLayoutConstraint.activate([
            gifImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gifImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            gifImageView.widthAnchor.constraint(equalToConstant: 200),
            gifImageView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        gifImageView.animate(withGIFNamed: "dog")
    }
}
