//
//  UIControl+.swift
//  Damago
//
//  Created by 박현수 on 1/8/26.
//

import Combine
import UIKit

extension UIControl {
    struct EventPublisher: Publisher {
        typealias Output = UIControl
        typealias Failure = Never

        let control: UIControl
        let event: UIControl.Event

        func receive<S>(subscriber: S) where S: Subscriber, Never == S.Failure, UIControl == S.Input {
            let subscription = EventSubscription(control: control, subscriber: subscriber, event: event)
            subscriber.receive(subscription: subscription)
        }
    }

    func publisher(for event: UIControl.Event) -> AnyPublisher<UIControl, Never> {
        EventPublisher(control: self, event: event).eraseToAnyPublisher()
    }

    private final class EventSubscription<S: Subscriber>: Subscription where S.Input == UIControl {
        private var subscriber: S?
        private weak var control: UIControl?

        init(control: UIControl, subscriber: S, event: UIControl.Event) {
            self.control = control
            self.subscriber = subscriber
            control.addTarget(self, action: #selector(eventHandler), for: event)
        }

        func request(_ demand: Subscribers.Demand) {}

        func cancel() {
            subscriber = nil
            control?.removeTarget(self, action: #selector(eventHandler), for: .allEvents)
        }

        @objc
        private func eventHandler() {
            guard let control else { return }
            _ = subscriber?.receive(control)
        }
    }
}
