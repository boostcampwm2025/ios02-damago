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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 뷰를 나갈 때 작성 중인 답변 저장
        viewModel.saveDraftAnswer()
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
            mainView.submitButton.setTitle("답변 제출")
            
            if mainView.textView.text != state.currentText {
                mainView.textView.text = state.currentText
            }
            mainView.placeholderLabel.isHidden = !state.currentText.isEmpty
            mainView.updateSubmitButton(state: .init(
                isEnabled: state.isSubmitButtonEnabled,
                isLoading: state.isLoading
            ))
            
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

extension DailyQuestionInputViewController: UITextViewDelegate {}
