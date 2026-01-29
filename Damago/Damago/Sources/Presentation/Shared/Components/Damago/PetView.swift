//
//  PetView.swift
//  Damago
//
//  Created by 김재영 on 1/26/26.
//

import UIKit

final class PetView: UIView {
    private var contentView: UIView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with petType: DamagoType) {
        contentView?.removeFromSuperview()
        
        let newContentView: UIView
        if petType.isAvailable {
            newContentView = setupSpriteView(sheetName: petType.imageName)
        } else {
            newContentView = setupPlaceholderView()
        }
        
        addSubview(newContentView)
        self.contentView = newContentView
        
        NSLayoutConstraint.activate([
            newContentView.topAnchor.constraint(equalTo: topAnchor),
            newContentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            newContentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            newContentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func setupSpriteView(sheetName: String) -> SpriteAnimationView {
        let spriteView = SpriteAnimationView(spriteSheetName: sheetName)
        spriteView.backgroundColor = UIColor(red: 239 / 255, green: 236 / 255, blue: 224 / 255, alpha: 1)
        spriteView.layer.cornerRadius = .largeCard
        spriteView.translatesAutoresizingMaskIntoConstraints = false
        return spriteView
    }
    
    private func setupPlaceholderView() -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(red: 239 / 255, green: 236 / 255, blue: 224 / 255, alpha: 1)
        container.layer.cornerRadius = .largeCard
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .bold)
        let imageView = UIImageView(image: UIImage(systemName: "questionmark", withConfiguration: config))
        imageView.tintColor = .systemGray2
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            container.widthAnchor.constraint(equalTo: container.heightAnchor)
        ])
        
        return container
    }
}
