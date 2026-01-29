//
//  ReusableTip.swift
//  Damago
//
//  Created by 김재영 on 1/29/26.
//

import TipKit
import UIKit

struct ReusableTip: Tip {
    enum SourceItem {
        case view(UIView)
        case barButtonItem(UIBarButtonItem)
    }
    
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
    func monitor(
        on viewController: UIViewController,
        sourceItem: SourceItem,
        onDismiss: (@Sendable () async -> Void)? = nil
    ) async {
        var session: TipSession?
        
        // Task가 취소되거나 함수가 종료될 때 제스처 등 리소스 정리
        defer { session?.cleanup() }
        
        for await shouldDisplay in self.shouldDisplayUpdates {
            if Task.isCancelled { return }
            
            if shouldDisplay {
                if session == nil {
                    // 다른 팝업이 있다면 완전히 사라질 때까지 대기
                    while viewController.presentedViewController != nil {
                        if Task.isCancelled { return }
                        try? await Task.sleep(for: .seconds(0.1))
                    }
                    
                    let newSession = TipSession(viewController: viewController)
                    if newSession.present(tip: self, sourceItem: sourceItem) {
                        session = newSession
                    }
                }
            } else {
                if let currentSession = session {
                    await currentSession.dismiss()
                    session = nil
                    await onDismiss?()
                }
            }
        }
    }
}

// MARK: - Private Helper

private final class TipSession: NSObject {
    private weak var viewController: UIViewController?
    private var gesture: UILongPressGestureRecognizer?
    
    init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    @MainActor
    func present(tip: any Tip, sourceItem: ReusableTip.SourceItem) -> Bool {
        guard let viewController = viewController,
              viewController.presentedViewController == nil else { return false }
        
        let popoverController: TipUIPopoverViewController
        
        switch sourceItem {
        case .view(let view):
            popoverController = TipUIPopoverViewController(tip, sourceItem: view)
        case .barButtonItem(let item):
            popoverController = TipUIPopoverViewController(tip, sourceItem: item)
        }
        
        popoverController.modalPresentationStyle = .popover
        if let presentationController = popoverController.popoverPresentationController {
            presentationController.delegate = viewController as? UIPopoverPresentationControllerDelegate
            presentationController.passthroughViews = [viewController.view]
            presentationController.permittedArrowDirections = .any
        }
        
        setupGesture(on: viewController.view)
        viewController.present(popoverController, animated: true)
        
        return true
    }
    
    @MainActor
    func dismiss() async {
        cleanup()
        guard let viewController = viewController,
              viewController.presentedViewController is TipUIPopoverViewController else { return }
        
        await withCheckedContinuation { continuation in
            viewController.dismiss(animated: true) {
                continuation.resume()
            }
        }
    }
    
    func cleanup() {
        if let gesture, let view = viewController?.view {
            view.removeGestureRecognizer(gesture)
        }
        gesture = nil
    }
    
    private func setupGesture(on view: UIView) {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        gesture.minimumPressDuration = 0.1
        gesture.cancelsTouchesInView = false
        view.addGestureRecognizer(gesture)
        self.gesture = gesture
    }
    
    @objc
    private func handleLongPress(_ sender: UILongPressGestureRecognizer) {
        guard let presentedVC = viewController?.presentedViewController,
              presentedVC is TipUIPopoverViewController,
              let containerView = presentedVC.presentationController?.containerView else { return }
        
        switch sender.state {
        case .began:
            UIView.animate(withDuration: 0.2) { containerView.alpha = 0 }
        case .ended, .cancelled, .failed:
            UIView.animate(withDuration: 0.2) { containerView.alpha = 1 }
        default:
            break
        }
    }
}
