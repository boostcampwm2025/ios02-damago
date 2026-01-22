//
//  SettingsDataSource.swift
//  Damago
//
//  Created by 박현수 on 1/20/26.
//

import UIKit

final class SettingsDataSource: UITableViewDiffableDataSource<SettingsSection, SettingsItem> {
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionIdentifier = sectionIdentifier(for: section)
        return sectionIdentifier?.headerTitle
    }
}

nonisolated enum SettingsSection: Int, CaseIterable, Hashable {
    case profile
    case relationship
    case preferences
    case legal
    case account

    var headerTitle: String? {
        switch self {
        case .profile: return nil
        case .relationship: return "관계"
        case .preferences: return "환경 설정"
        case .legal: return "정보"
        case .account: return "계정"
        }
    }
}

nonisolated enum SettingsItem: Hashable {
    case profile(name: String, dDay: Int, anniversaryDate: String)
    case relationship(opponentName: String)
    case toggle(type: ToggleType, isOn: Bool)
    case link(title: String, url: URL?)
    case action(type: AlertActionType)
}

nonisolated enum AlertActionType: String, Hashable {
    case logout = "로그아웃"
    case deleteAccount = "회원 탈퇴"
    case openSettings = "설정으로 이동"
    
    var title: String { rawValue }
    var message: String {
        switch self {
        case .logout: "정말 로그아웃 하시겠습니까?"
        case .deleteAccount: "정말 탈퇴 하시겠습니까?\n모든 데이터가 삭제됩니다."
        case .openSettings: "권한이 필요합니다.\n앱 설정 화면으로 이동하시겠습니까?"
        }
    }
    var isDestructive: Bool { self == .deleteAccount }
}

nonisolated enum ToggleType: String, Hashable {
    case notification = "알림"
    case liveActivity = "다이내믹 아일랜드"

    var subtitle: String? {
        switch self {
        case .notification: return "상대방이 보내는\n알림을 받을 수 있어요"
        case .liveActivity: return "펫 상태 업데이트를\n실시간으로 확인할 수 있어요"
        }
    }

    var iconName: String {
        switch self {
        case .notification: return "bell.fill"
        case .liveActivity: return "sensor.tag.radiowaves.forward.fill"
        }
    }
}
