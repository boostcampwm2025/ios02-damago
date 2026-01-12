//
//  ASAuthorizationAppleIDButton+Publisher.swift
//  Damago
//
//  Created by 박현수 on 1/13/26.
//

import AuthenticationServices
import Combine
import UIKit

extension ASAuthorizationAppleIDButton {
    var tapPublisher: AnyPublisher<Void, Never> {
        EventPublisher(control: self, event: .touchUpInside)
            .map { _ in }
            .eraseToAnyPublisher()
    }
}
