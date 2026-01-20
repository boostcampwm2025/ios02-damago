//
//  DailyQuestionInputViewController.swift
//  Damago
//
//  Created by 김재영 on 1/19/26.
//

import UIKit
import Combine

final class DailyQuestionInputViewController: UIViewController {
    private let mainView = DailyQuestionInputView()
    private let viewModel: DailyQuestionInputViewModel
    
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: DailyQuestionInputViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupTextView()
        setupKeyboard()
        
        let output = viewModel.transform(
            DailyQuestionInputViewModel.Input(
                textDidChange: mainView.textView.textPublisher,
                submitButtonDidTap: mainView.submitButton.tapPublisher
            )
        )
        
        bind(output)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func setupNavigation() {
        title = "오늘의 질문"
        navigationItem.largeTitleDisplayMode = .never
    }
    
    private func setupTextView() {
        mainView.textView.delegate = self
    }
    
    private func setupKeyboard() {
        mainView.setupKeyboardDismissOnTap()
        mainView.scrollView.adjustContentInsetForKeyboard()
            .store(in: &cancellables)
    }
    
    private func bind(_ output: DailyQuestionInputViewModel.Output) {
        output
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.render(state)
            }
            .store(in: &cancellables)
    }
    
    private func render(_ state: DailyQuestionInputViewModel.State) {
        // 질문 내용 업데이트
        let questionContent: String
        switch state.uiModel {
        case .input(let inputState):
            questionContent = inputState.questionContent
            mainView.updateLayoutMode(.input)
            mainView.submitButton.setTitle("답변 제출", for: .normal)
            
            if mainView.textView.text != state.currentText {
                mainView.textView.text = state.currentText
            }
            mainView.placeholderLabel.isHidden = !state.currentText.isEmpty
            mainView.textLimitLabel.text = state.textCount
            mainView.submitButton.isEnabled = state.isSubmitButtonEnabled
            
        case .result(let resultState):
            questionContent = resultState.questionContent
            mainView.updateLayoutMode(.result)
            mainView.myAnswerResultCardView.configure(with: resultState.myAnswer)
            mainView.opponentAnswerResultCardView.configure(with: resultState.opponentAnswer)
            
            view.endEditing(true)
        }
        
        mainView.configure(title: questionContent)
    }
}

extension DailyQuestionInputViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let currentText = textView.text else { return true }
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: text)
        return updatedText.count <= 200
    }
}
