//
//  ViewController.swift
//  Damago
//
//  Created by 김재영 on 12/16/25.
//

import UIKit

@MainActor
final class ViewController: UIViewController {
    private var hasStartedAnimation = false
    
    private let spriteAnimationView: SpriteAnimationView = {
        let view = SpriteAnimationView(defaultDamagoName: "PuppyBark")
        view.translatesAutoresizingMaskIntoConstraints = false
        view.animationDuration = 1.0
        return view
    }()

    private lazy var pokeButton: UIButton = {
        let action = UIAction { [weak self] _ in self?.sendNotification() }
        let button = UIButton(type: .system, primaryAction: action)
        button.setTitle("찌르기", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var interactrionButton: UIButton = {
        let action = UIAction { [weak self] _ in
            self?.spriteAnimationView.animate(damagoName: "PuppySneak", repeatCount: 3)
        }
        let button = UIButton(type: .system, primaryAction: action)
        button.setTitle("상호작용", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        view.addSubview(spriteAnimationView)
        view.addSubview(pokeButton)
        view.addSubview(interactrionButton)

        NSLayoutConstraint.activate([
            pokeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            pokeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            interactrionButton.topAnchor.constraint(equalTo: pokeButton.bottomAnchor, constant: 16),
            interactrionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            spriteAnimationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spriteAnimationView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            spriteAnimationView.widthAnchor.constraint(equalToConstant: 300),
            spriteAnimationView.heightAnchor.constraint(equalToConstant: 300)
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !hasStartedAnimation {
            hasStartedAnimation = true
            spriteAnimationView.animate(damagoName: "PuppyBark")
        }
    }
}

extension ViewController {
    var udid: String? { UIDevice.current.identifierForVendor?.uuidString }

    private func sendNotification() {
        Task {
            guard let url = URL(string: "https://poke-wrjwddcv2q-uc.a.run.app") else { return }

            var request = URLRequest(url: url)
            let body = ["udid": udid]

            request.httpMethod = "POST"
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
            guard (200..<300).contains(httpResponse.statusCode) else {
                throw NetworkError.invalidStatusCode(
                    httpResponse.statusCode,
                    String(data: data, encoding: .utf8) ?? "invalid data"
                )
            }
        }
    }
}
