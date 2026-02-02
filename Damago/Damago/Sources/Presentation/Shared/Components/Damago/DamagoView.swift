//
//  DamagoView.swift
//  Damago
//
//  Created by 김재영 on 1/26/26.
//

import UIKit

final class DamagoView: UIView {
    private var contentView: UIView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBaseUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupBaseUI() {
        backgroundColor = UIColor(red: 239 / 255, green: 236 / 255, blue: 224 / 255, alpha: 1)
        layer.cornerRadius = .largeCard
        clipsToBounds = true
    }
    
    func configure(with damagoType: DamagoType) {
        contentView?.removeFromSuperview()
        
        let newContentView = setupSpriteView(sheetName: damagoType.imageName, showTemplete: !damagoType.isAvailable)
        
        addSubview(newContentView)
        self.contentView = newContentView
        
        NSLayoutConstraint.activate([
            newContentView.centerXAnchor.constraint(equalTo: centerXAnchor),
            newContentView.centerYAnchor.constraint(equalTo: centerYAnchor),
            newContentView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.7),
            newContentView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.7)
        ])
    }
    
    private func setupSpriteView(sheetName: String, showTemplete: Bool = false) -> SpriteAnimationView {
        let spriteView = SpriteAnimationView(spriteSheetName: sheetName)
        spriteView.backgroundColor = .clear
        spriteView.translatesAutoresizingMaskIntoConstraints = false
        
        if showTemplete {
            spriteView.tintColor = .black
            spriteView.renderingMode = .alwaysTemplate
        }
        
        return spriteView
    }
}
