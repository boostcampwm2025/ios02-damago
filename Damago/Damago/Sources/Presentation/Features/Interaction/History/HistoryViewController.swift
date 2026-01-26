//
//  HistoryViewController.swift
//  Damago
//
//  Created by 박현수 on 1/26/26.
//

import Combine
import UIKit

final class HistoryViewController: UIViewController {
    private let mainView = HistoryView()
    
    private let viewModel: HistoryViewModel
    private var cancellables = Set<AnyCancellable>()

    private lazy var dailyDataSource = DailyQuestionHistoryDataSource(
        collectionView: mainView.dailyQuestionView.collectionView
    )
    
    private lazy var balanceDataSource = BalanceGameHistoryDataSource(
        collectionView: mainView.balanceGameView.collectionView
    )
    
    init(viewModel: HistoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
    }
    
    private func setupUI() {
        title = "지난 활동"
    }
    
    private func bind() {
        let input = HistoryViewModel.Input(
            viewDidLoad: Just(()).eraseToAnyPublisher(),
            segmentDidChange: mainView.segmentedControl.selectedSegmentIndexPublisher
        )
        
        let output = viewModel.transform(input)
        
        output
            .mapForUI { $0.isLoading }
            .sink { [weak self] isLoading in
                self?.mainView.setLoading(isLoading)
            }
            .store(in: &cancellables)
            
        output
            .mapForUI { $0.selectedSegmentIndex }
            .sink { [weak self] index in
                self?.mainView.updateView(for: index)
            }
            .store(in: &cancellables)
            
        output
            .mapForUI { $0.dailyQuestions }
            .sink { [weak self] items in
                self?.applyDailySnapshot(items: items)
            }
            .store(in: &cancellables)
            
        output
            .mapForUI { BalanceGamesHistoryState(histories: $0.balanceGames, matchRate: $0.matchRate) }
            .sink { [weak self] state in
                self?.mainView.balanceGameView.updateMatchRate(state.matchRate)
                self?.applyBalanceSnapshot(items: state.histories)
            }
            .store(in: &cancellables)
            
        output
            .pulse(\.route)
            .sink { [weak self] route in
                switch route {
                case let .alert(title, message):
                    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "확인", style: .default))
                    self?.present(alert, animated: true)
                }
            }
            .store(in: &cancellables)
    }
    
    private func applyDailySnapshot(items: [DailyQuestionHistory]) {
        var snapshot = NSDiffableDataSourceSnapshot<HistorySection, DailyQuestionHistory>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)
        dailyDataSource.apply(snapshot, animatingDifferences: true)
    }
    
    private func applyBalanceSnapshot(items: [BalanceGameHistory]) {
        var snapshot = NSDiffableDataSourceSnapshot<HistorySection, BalanceGameHistory>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)
        balanceDataSource.apply(snapshot, animatingDifferences: true)
    }
}

extension HistoryViewController {
    struct BalanceGamesHistoryState: Equatable {
        let histories: [BalanceGameHistory]
        let matchRate: Int
    }
}
