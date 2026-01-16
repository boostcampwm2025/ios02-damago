//
//  CircularActionButton.swift
//  Damago
//
//  Created by 박현수 on 1/15/26.
//

import UIKit

final class CircularActionButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2
    }

    func configure(
        backgroundColor: UIColor,
        systemName: String,
        tintColor: UIColor
    ) {
        self.backgroundColor = backgroundColor

        let config = UIImage.SymbolConfiguration(font: .title3)
        let image = UIImage(systemName: systemName, withConfiguration: config)
        
        setImage(image, for: .normal)
        self.tintColor = tintColor
        layer.shadowColor = backgroundColor.cgColor
    }

    private func setupUI() {
        layer.shadowOffset = CGSize(width: 0, height: 8)
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 10
        layer.masksToBounds = false
    }
}
