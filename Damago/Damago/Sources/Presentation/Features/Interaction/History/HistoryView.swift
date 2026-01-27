//
//  HistoryView.swift
//  Damago
//
//  Created by 박현수 on 1/26/26.
//

import UIKit

final class HistoryView: UIView {
    let segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["오늘의 질문", "밸런스 게임"])
        control.tintColor = .damagoPrimary
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    let dailyQuestionView: DailyQuestionHistoryView = {
        let view = DailyQuestionHistoryView()
        view.isHidden = false
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let balanceGameView: BalanceGameHistoryView = {
        let view = BalanceGameHistoryView()
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let progressView = ProgressView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setLoading(_ isLoading: Bool) {
        if isLoading {
            progressView.show(in: self, message: "불러오는 중...")
        } else {
            progressView.hide()
        }
    }
    
    func updateView(for segmentIndex: Int) {
        dailyQuestionView.isHidden = segmentIndex != 0
        balanceGameView.isHidden = segmentIndex != 1
    }
    
    private func setupUI() {
        backgroundColor = .background
        
        addSubview(segmentedControl)
        addSubview(dailyQuestionView)
        addSubview(balanceGameView)
        
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: .spacingM),
            segmentedControl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingM),
            segmentedControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingM),
            
            dailyQuestionView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: .spacingM),
            dailyQuestionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dailyQuestionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dailyQuestionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            balanceGameView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: .spacingM),
            balanceGameView.leadingAnchor.constraint(equalTo: leadingAnchor),
            balanceGameView.trailingAnchor.constraint(equalTo: trailingAnchor),
            balanceGameView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
