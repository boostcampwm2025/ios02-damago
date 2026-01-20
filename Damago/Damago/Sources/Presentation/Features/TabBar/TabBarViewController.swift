//
//  TabBarViewController.swift
//  Damago
//
//  Created by loyH on 1/6/26.
//

import UIKit
import DamagoNetwork

enum TabItem: String, CaseIterable {
    case home = "홈"
    case collection = "컬렉션"
    case interaction = "상호작용"
    case game = "미니게임"
    case setting = "설정"

    var title: String { rawValue }

    var image: UIImage? {
        switch self {
        case .home:
            return UIImage(systemName: "house")
        case .collection:
            return UIImage(systemName: "square.grid.2x2")
        case .interaction:
            return UIImage(systemName: "heart")
        case .game:
            return UIImage(systemName: "gamecontroller")
        case .setting:
            return UIImage(systemName: "gearshape")
        }
    }

    var tag: Int {
        switch self {
        case .home:
            return 0
        case .collection:
            return 1
        case .interaction:
            return 2
        case .game:
            return 3
        case .setting:
            return 4
        }
    }
}

final class TabBarViewController: UITabBarController {
    private var tabItems: [TabItem] = TabItem.allCases

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        setupTabBar()
    }

    private func setupTabBar() {
        tabBar.tintColor = .damagoPrimary
        tabBar.unselectedItemTintColor = .textTertiary
    }

    /// 각 탭 아이템에 대한 ViewController를 생성하고 탭바에 설정
    private func setupViewControllers() {
        let viewControllers = tabItems.map { tabItem -> UIViewController in
            var viewController = getViewController(for: tabItem)
            if tabItem != .home { viewController = UINavigationController(rootViewController: viewController) }

            // 탭바 아이템 설정
            let tabBarItem = UITabBarItem(
                title: nil,
                image: tabItem.image?.withRenderingMode(.alwaysTemplate),
                selectedImage: tabItem.image?.withRenderingMode(.alwaysTemplate)
            )
            tabBarItem.tag = tabItem.tag

            // NavigationController에 탭바 아이템 할당
            viewController.tabBarItem = tabBarItem
            return viewController
        }

        // 생성된 ViewController들을 탭바에 설정
        setViewControllers(viewControllers, animated: false)
        selectedIndex = 0
    }

    private func getViewController(for tabItem: TabItem) -> UIViewController {
        switch tabItem {
        case .collection:
            return UIViewController()
        case .home:
            let globalStore = AppDIContainer.shared.resolve(GlobalStoreProtocol.self)
            let userRepository = AppDIContainer.shared.resolve(UserRepositoryProtocol.self)
            let petRepository = AppDIContainer.shared.resolve(PetRepositoryProtocol.self)
            let pushRepository = AppDIContainer.shared.resolve(PushRepositoryProtocol.self)

            let vm = HomeViewModel(
                globalStore: globalStore,
                userRepository: userRepository,
                petRepository: petRepository,
                pushRepository: pushRepository
            )
            let vc = HomeViewController(viewModel: vm)
            return vc
        case .interaction:
            let useCase = AppDIContainer.shared.resolve(FetchDailyQuestionUseCase.self)
            
            let vm = InteractionViewModel(fetchDailyQuestionUseCase: useCase)
            let vc = InteractionViewController(viewModel: vm)
            return vc
        case .game:
            return UIViewController()
        case .setting:
            return UIViewController()
        }
    }
}
