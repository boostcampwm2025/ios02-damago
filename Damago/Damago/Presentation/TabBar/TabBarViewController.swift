//
//  TabBarViewController.swift
//  Damago
//
//  Created by loyH on 1/6/26.
//

import UIKit

enum TabItem: String, CaseIterable {
    case collection = "컬렉션"
    case home = "홈"
    case interaction = "상호작용"
    case game = "미니게임"
    case setting = "설정"
    
    var title: String { rawValue }
    
    var image: UIImage? {
        switch self {
        case .collection:
            return UIImage(systemName: "square.grid.2x2")
        case .home:
            return UIImage(systemName: "house")
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
        case .collection:
            return 0
        case .home:
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

@MainActor
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
            let viewController = getViewController(for: tabItem)
            let navigationController = UINavigationController(rootViewController: viewController)
            
            // 탭바 아이템 설정
            let tabBarItem = UITabBarItem(
                title: nil,
                image: tabItem.image?.withRenderingMode(.alwaysTemplate),
                selectedImage: tabItem.image?.withRenderingMode(.alwaysTemplate)
            )
            tabBarItem.tag = tabItem.tag
            
            // NavigationController에 탭바 아이템 할당
            navigationController.tabBarItem = tabBarItem
            return navigationController
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
            return UIViewController()
        case .interaction:
            return UIViewController()
        case .game:
            return UIViewController()
        case .setting:
            return UIViewController()
        }
    }
}
