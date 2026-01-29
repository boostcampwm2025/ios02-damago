//
//  UIBarButtonItem+Publisher.swift
//  Damago
//
//  Created by 박현수 on 1/29/26.
//

import Combine
import UIKit

extension UIBarButtonItem {
    var tapPublisher: AnyPublisher<Void, Never> {
        UIBarButtonItemTapPublisher(barButtonItem: self).eraseToAnyPublisher()
    }
}

struct UIBarButtonItemTapPublisher: Publisher {
    typealias Output = Void
    typealias Failure = Never
    
    private let barButtonItem: UIBarButtonItem
    
    init(barButtonItem: UIBarButtonItem) {
        self.barButtonItem = barButtonItem
    }
    
    func receive<S>(subscriber: S) where S: Subscriber, Never == S.Failure, Void == S.Input {
        let subscription = UIBarButtonItemTapSubscription(subscriber: subscriber, barButtonItem: barButtonItem)
        subscriber.receive(subscription: subscription)
    }
}

final class UIBarButtonItemTapSubscription<S: Subscriber>: Subscription where S.Input == Void {
    private var subscriber: S?
    private weak var barButtonItem: UIBarButtonItem?
    
    init(subscriber: S, barButtonItem: UIBarButtonItem) {
        self.subscriber = subscriber
        self.barButtonItem = barButtonItem
        
        barButtonItem.target = self
        barButtonItem.action = #selector(didTap)
    }
    
    func request(_ demand: Subscribers.Demand) {}
    
    func cancel() {
        subscriber = nil
        barButtonItem?.target = nil
        barButtonItem?.action = nil
    }
    
    @objc
    private func didTap() {
        _ = subscriber?.receive(( ))
    }
}
