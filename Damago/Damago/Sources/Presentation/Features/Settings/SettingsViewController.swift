//
//  SettingsViewController.swift
//  Damago
//
//  Created by 박현수 on 1/20/26.
//

import UIKit
import Combine
import SafariServices

final class SettingsViewController: UIViewController {
    private let mainView = SettingsView()
    private let viewModel: SettingsViewModel
    private var cancellables = Set<AnyCancellable>()

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let toggleSubject = PassthroughSubject<(ToggleType, Bool), Never>()
    private let itemSelectedSubject = PassthroughSubject<SettingsItem, Never>()
    private let alertConfirmSubject = PassthroughSubject<AlertActionType, Never>()

    private lazy var dataSource: SettingsDataSource = createDataSource()

    init(viewModel: SettingsViewModel) {
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
        setupNavigationBar()
        setupDelegate()
        bind()
        viewDidLoadSubject.send()
    }

    private func setupNavigationBar() {
        navigationItem.title = "설정"
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    private func setupDelegate() {
        mainView.tableView.delegate = self
    }

    private func bind() {
        let input = SettingsViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            toggleChanged: toggleSubject.eraseToAnyPublisher(),
            itemSelected: itemSelectedSubject.eraseToAnyPublisher(),
            alertActionDidConfirm: alertConfirmSubject.eraseToAnyPublisher()
        )

        let output = viewModel.transform(input)

        output
            .mapForUI { $0.sectionState }
            .sink { [weak self] state in
                self?.applyDatasource(state: state)
            }
            .store(in: &cancellables)

        output
            .pulse(\.route)
            .sink { [weak self] route in
                self?.handleRoute(route)
            }
            .store(in: &cancellables)
    }

    private func applyDatasource(state: SettingsViewModel.SectionState) {
        var snapshot = NSDiffableDataSourceSnapshot<SettingsSection, SettingsItem>()
        snapshot.appendSections(SettingsSection.allCases)
        snapshot.appendItems(
            [.profile(name: state.userName, dDay: state.dDay, anniversaryDate: state.anniversaryDate)],
            toSection: .profile
        )
        snapshot.appendItems(
            [.relationship(opponentName: state.opponentName)],
            toSection: .relationship
        )
        snapshot.appendItems(
            [
                .toggle(type: .liveActivity, isOn: state.isLiveActivityEnabled),
                .toggle(type: .notification, isOn: state.isNotificationEnabled)
            ],
            toSection: .preferences
        )
        snapshot.appendItems(
            [
                .link(title: "개인정보 처리방침", url: state.privacyPolicyURL),
                .link(title: "이용약관", url: state.termsURL)
            ],
            toSection: .legal
        )
        snapshot.appendItems(
            [
                .action(type: .logout),
                .action(type: .deleteAccount)
            ],
            toSection: .account
        )
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func handleRoute(_ route: SettingsViewModel.Route) {
        switch route {
        case .editProfile:
            let globalStore = AppDIContainer.shared.resolve(GlobalStoreProtocol.self)
            let updateUserUseCase = AppDIContainer.shared.resolve(UpdateUserUseCase.self)
            let viewModel = EditProfileViewModel(
                globalStore: globalStore,
                updateUserUseCase: updateUserUseCase
            )
            let vc = EditProfileViewController(viewModel: viewModel)
            navigationController?.pushViewController(vc, animated: true)

        case .connection:
            let fetchCodeUseCase = AppDIContainer.shared.resolve(FetchCodeUseCase.self)
            let connectCoupleUseCase = AppDIContainer.shared.resolve(ConnectCoupleUseCase.self)
            let viewModel = ConnectionViewModel(
                fetchCodeUseCase: fetchCodeUseCase,
                connectCoupleUseCase: connectCoupleUseCase
            )
            let vc = ConnectionViewController(viewModel: viewModel)
            navigationController?.pushViewController(vc, animated: true)

        case .webLink(let url):
            guard let url else { return }
            UIApplication.shared.open(url)

        case .alert(let type):
            let alert = UIAlertController(title: type.title, message: type.message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "취소", style: .cancel))
            alert.addAction(UIAlertAction(title: "확인", style: .destructive) { [weak self] _ in
                self?.alertConfirmSubject.send(type)
            })
            present(alert, animated: true)

        case .error(let message):
            let alert = UIAlertController(title: "에러", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
            
        case .openSettings:
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
}

extension SettingsViewController: UITableViewDelegate {
    private func createDataSource() -> SettingsDataSource {
        SettingsDataSource(
            tableView: mainView.tableView
        ) { [weak self] tableView, indexPath, item in
            guard let self = self else { return UITableViewCell() }

            switch item {
            case .profile(let name, let dDay, let date):
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: SettingsProfileCell.reuseIdentifier,
                    for: indexPath
                ) as? SettingsProfileCell else {
                    return UITableViewCell()
                }
                cell.configure(name: name, dDay: dDay, date: date)
                cell.selectionStyle = .none
                return cell

            case .relationship(let opponentName):
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: UITableViewCell.reuseIdentifier,
                    for: indexPath
                )
                var content = cell.defaultContentConfiguration()

                content.image = UIImage(systemName: "heart.fill")
                content.imageProperties.tintColor = .systemPink
                content.text = "커플 연결 다시하기"
                content.textProperties.color = .textPrimary
                content.secondaryText = opponentName.isEmpty ? "상대방의 닉네임이 없어요!" : "\(opponentName)님과 연결됨"
                content.secondaryTextProperties.color = .textSecondary

                cell.contentConfiguration = content
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
                return cell

            case .toggle(let type, let isOn):
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: SettingsToggleCell.reuseIdentifier,
                    for: indexPath
                ) as? SettingsToggleCell else {
                    return UITableViewCell()
                }

                cell.configure(type: type, isOn: isOn)

                cell.valueChanged
                    .sink { [weak self] isOn in
                        self?.toggleSubject.send((type, isOn))
                    }
                    .store(in: &cell.cancellables)
                return cell

            case .link(let title, _):
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: UITableViewCell.reuseIdentifier,
                    for: indexPath
                )
                var content = cell.defaultContentConfiguration()
                content.text = title
                content.textProperties.color = .textPrimary
                cell.contentConfiguration = content
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
                return cell

            case .action(let type):
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: UITableViewCell.reuseIdentifier,
                    for: indexPath
                )
                var content = cell.defaultContentConfiguration()
                content.text = type.title
                content.textProperties.color = type.isDestructive ? .systemRed : .textPrimary
                cell.contentConfiguration = content
                cell.selectionStyle = .default
                return cell
            }
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        itemSelectedSubject.send(item)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = SettingsSection(rawValue: indexPath.section)
        if section == .profile { return 100 }
        return UITableView.automaticDimension
    }
}
