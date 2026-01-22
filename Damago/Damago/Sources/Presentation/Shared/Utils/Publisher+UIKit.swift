//
//  Publisher+UIKit.swift
//  Damago
//
//  Created by loyH on 1/22/26.
//

import Combine
import UIKit

extension Publisher where Failure == Never {
    // swiftlint:disable trailing_closure

    /// Publisher가 이벤트를 발행할 때 지정된 뷰의 키보드를 내립니다.
    func dismissKeyboard(from view: UIView) -> AnyPublisher<Output, Failure> {
        self
            .handleEvents(receiveOutput: { _ in
                view.endEditing(true)
            })
            .eraseToAnyPublisher()
    }
    // swiftlint:enable trailing_closure
}
