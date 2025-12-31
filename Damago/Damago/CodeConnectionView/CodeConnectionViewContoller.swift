//
//  CodeConnectionViewContoller.swift
//  Damago
//
//  Created by Eden Landelyse on 12/17/25.
//

import UIKit

final class CodeConnectionViewController: UIViewController {
    private let viewModel: CodeConnectionViewModel
    private let codeConnectionView = CodeConnectionView()

    init(viewModel: CodeConnectionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("미지원 초기화 경로")
    }

    override func loadView() {
        view = codeConnectionView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.onConnected = { [weak self] isSuccessed in
            guard let self else { return }
            if isSuccessed {
                let homeViewController = ViewController()
                self.navigationController?
                    .setViewControllers([homeViewController], animated: true)
            } else {
                codeConnectionView.errorMessageLabel.text = "커플 연결에 실패했습니다."
            }
        }

        codeConnectionView.codeTextField.delegate = self
        codeConnectionView.onConnectTap = { [weak self] targetCode in
            guard let self else { return }
            Task {
                do {
                    try await self.viewModel.connectCouple(targetCode: targetCode)
                } catch {
                    self.codeConnectionView.errorMessageLabel.text = "연결 오류가 발생했습니다."
                }
            }
        }

        Task { [weak self] in
            guard let self else { return }

            do {
                guard let code = try await self.viewModel.resolveMyCode() else { return }
                await MainActor.run { self.codeConnectionView.setMyCode(code) }
            } catch {
                // Code를 발급 받지 못했을 때 처리
            }
        }
    }
}

extension CodeConnectionViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
