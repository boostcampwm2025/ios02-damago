//
//  DamagoTextField.swift
//  Damago
//
//  Created by loyH on 2/4/26.
//

import UIKit

final class DamagoTextField: UITextField {
    // 입력 최대 길이. `nil`이면 제한 없음
    var maxLength: Int? {
        didSet {
            handleTextChange()
        }
    }
    
    private let counterLabel = UILabel()
    private var counterWidth: CGFloat = 0
    private var isEnforcing = false
    
    override var font: UIFont? {
        didSet { counterLabel.font = font }
    }
    
    override var text: String? {
        didSet { handleTextChange() }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        counterLabel.font = font
        counterLabel.textColor = .textTertiary
        counterLabel.textAlignment = .right
        counterLabel.setContentHuggingPriority(.required, for: .horizontal)
        counterLabel.isHidden = true
        addSubview(counterLabel)
        
        addTarget(self, action: #selector(textDidChange), for: .editingChanged)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutCounterIfNeeded()
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: contentInsets())
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: contentInsets())
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: contentInsets())
    }
    
    @objc
    private func textDidChange() {
        handleTextChange()
    }
    
    private func handleTextChange() {
        guard maxLength != nil else {
            counterLabel.isHidden = true
            counterWidth = 0
            setNeedsLayout()
            return
        }
        enforceMaxLengthIfNeeded()
        updateCounterLabel()
    }
    
    private func enforceMaxLengthIfNeeded() {
        guard let maxLength, maxLength >= 0 else { return }
        guard let text, text.count > maxLength else { return }
        guard !isEnforcing else { return }
        isEnforcing = true
        self.text = String(text.prefix(maxLength))
        isEnforcing = false
        sendActions(for: .editingChanged)
    }
    
    private func updateCounterLabel() {
        guard let maxLength, maxLength >= 0 else { return }
        let current = text?.count ?? 0
        let newText = "\(current) / \(maxLength)"
        guard counterLabel.text != newText || counterLabel.isHidden else { return }
        counterLabel.text = newText
        counterLabel.isHidden = false
        updateCounterMetrics()
        setNeedsLayout()
    }
    
    private func updateCounterMetrics() {
        let size = counterLabel.intrinsicContentSize
        counterWidth = size.width + .spacingS
    }
    
    private func layoutCounterIfNeeded() {
        guard maxLength != nil, !counterLabel.isHidden, bounds.height > 0 else { return }
        let size = counterLabel.intrinsicContentSize
        let x = bounds.width - .spacingM - size.width
        let y = (bounds.height - size.height) / 2
        counterLabel.frame = CGRect(x: x, y: y, width: size.width, height: size.height)
    }
    
    private func contentInsets() -> UIEdgeInsets {
        let rightInset = .spacingM + (maxLength == nil ? 0 : counterWidth)
        return UIEdgeInsets(top: 0, left: .spacingM, bottom: 0, right: rightInset)
    }
}
