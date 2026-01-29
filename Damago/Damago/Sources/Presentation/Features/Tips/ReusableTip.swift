//
//  ReusableTip.swift
//  Damago
//
//  Created by 김재영 on 1/29/26.
//

import TipKit
import UIKit

struct ReusableTip: Tip {
    let id: String
    let title: Text
    let message: Text?
    
    var options: [TipOption] {
        [Tips.MaxDisplayCount(1)]
    }
    
    var rules: [Rule]

    init(id: String, title: String, message: String, rules: [Rule] = []) {
        self.id = id
        self.title = Text(title)
        self.message = Text(message)
        self.rules = rules
    }
    
    @MainActor
    func present(on viewController: UIViewController, sourceItem: Any) {
        if viewController.presentedViewController is TipUIPopoverViewController {
            return
        }

        let popoverController: TipUIPopoverViewController
        
        if let view = sourceItem as? UIView {
            popoverController = TipUIPopoverViewController(self, sourceItem: view)
        } else if let barButtonItem = sourceItem as? UIBarButtonItem {
            popoverController = TipUIPopoverViewController(self, sourceItem: barButtonItem)
        } else {
            return
        }
        
        viewController.present(popoverController, animated: true)
    }

    @MainActor
    func monitor(
        on viewController: UIViewController,
        sourceItem: Any,
        onDismiss: (@Sendable () async -> Void)? = nil
    ) async {
        var isShowing = false
        
        for await shouldDisplay in self.shouldDisplayUpdates {
            if shouldDisplay {
                if !isShowing {
                    // 다른 팝업이 있다면 완전히 사라질 때까지 대기
                    while viewController.presentedViewController != nil {
                        try? await Task.sleep(for: .seconds(0.1))
                    }
                    self.present(on: viewController, sourceItem: sourceItem)
                    isShowing = true
                }
            } else if isShowing {
                isShowing = false
                if viewController.presentedViewController is TipUIPopoverViewController {
                    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                        viewController.dismiss(animated: true) {
                            continuation.resume()
                        }
                    }
                }
                await onDismiss?()
            }
        }
    }
}
