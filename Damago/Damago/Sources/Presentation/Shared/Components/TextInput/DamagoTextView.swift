//
//  DamagoTextView.swift
//  Damago
//
//  Created by loyH on 2/4/26.
//

import UIKit

final class DamagoTextView: UITextView {
    // 입력 최대 길이. `nil`이면 제한 없음
    var maxLength: Int? {
        didSet {
            configureObserver()
            handleTextChange()
        }
    }
    
    private let counterLabel = UILabel()
    private var textDidChangeObserver: NSObjectProtocol?
    private var isEnforcing = false
    
    override var text: String! {
        didSet { handleTextChange() }
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    deinit {
        if let observer = textDidChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func setup() {
        counterLabel.font = .caption
        counterLabel.textColor = .textTertiary
        counterLabel.textAlignment = .right
        counterLabel.isUserInteractionEnabled = false
        counterLabel.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        updateCounterAttachment()
    }
    
    private func configureObserver() {
        if let observer = textDidChangeObserver {
            NotificationCenter.default.removeObserver(observer)
            textDidChangeObserver = nil
        }
        
        guard maxLength != nil else { return }
        textDidChangeObserver = NotificationCenter.default.addObserver(
            forName: UITextView.textDidChangeNotification,
            object: self,
            queue: .main
        ) { [weak self] _ in
            self?.handleTextChange()
        }
    }
    
    private func handleTextChange() {
        guard maxLength != nil else {
            counterLabel.removeFromSuperview()
            return
        }
        enforceMaxLengthIfNeeded()
        updateCounterLabel()
        updateCounterAttachment()
    }
    
    private func enforceMaxLengthIfNeeded() {
        guard let maxLength, maxLength >= 0 else { return }
        guard let text, text.count > maxLength else { return }
        guard !isEnforcing else { return }
        isEnforcing = true
        self.text = String(text.prefix(maxLength))
        selectedRange = NSRange(location: maxLength, length: 0)
        isEnforcing = false
    }
    
    private func updateCounterLabel() {
        guard let maxLength, maxLength >= 0 else { return }
        let current = text?.count ?? 0
        let newText = "\(current) / \(maxLength)"
        if counterLabel.text != newText {
            counterLabel.text = newText
        }
    }
    
    private func updateCounterAttachment() {
        guard maxLength != nil, let parent = superview else { return }
        
        if counterLabel.superview == nil {
            parent.addSubview(counterLabel)
            NSLayoutConstraint.activate([
                counterLabel.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -.spacingM),
                counterLabel.bottomAnchor.constraint(equalTo: parent.bottomAnchor, constant: -.spacingM)
            ])
        }
        parent.bringSubviewToFront(counterLabel)
    }
}
