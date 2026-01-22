//
//  SettingsCell.swift
//  Damago
//
//  Created by 박현수 on 1/20/26.
//

import Combine
import UIKit

final class SettingsProfileCell: UITableViewCell {
    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "person.crop.circle.fill")
        iv.tintColor = .damagoPrimary
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .title2
        label.textColor = .textPrimary
        return label
    }()

    private let dDayLabel: UILabel = {
        let label = UILabel()
        label.font = .body1
        label.textColor = .damagoPrimary
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .caption
        label.textColor = .textSecondary
        return label
    }()

    private lazy var textStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [nameLabel, dDayLabel, dateLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        contentView.addSubview(profileImageView)
        contentView.addSubview(textStack)

        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 60),
            profileImageView.heightAnchor.constraint(equalToConstant: 60),

            textStack.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 16),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            textStack.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 16),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -16)
        ])

        accessoryType = .disclosureIndicator
    }

    func configure(name: String, dDay: Int, date: String) {
        nameLabel.text = name.isEmpty ? "닉네임이 필요해요!" : name
        dDayLabel.text = "D+\(dDay)"
        dateLabel.text = date.isEmpty ? "처음 만난 날을 등록해 보세요!" : "\(date) 처음 만남"
    }
}

// MARK: - Toggle Cell
final class SettingsToggleCell: UITableViewCell {
    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.tintColor = .damagoPrimary
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let toggleSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = .damagoPrimary
        return toggle
    }()

    var cancellables = Set<AnyCancellable>()

    var valueChanged: AnyPublisher<Bool, Never> {
        toggleSwitch.valueChangedPublisher
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .white
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        cancellables.removeAll()
        toggleSwitch.isOn = false
    }

    func configure(type: ToggleType, isOn: Bool) {
        var content = defaultContentConfiguration()
        content.image = UIImage(systemName: type.iconName)
        content.imageProperties.tintColor = type == .notification ? .systemYellow : .black
        content.text = type.rawValue
        content.secondaryText = type.subtitle
        content.secondaryTextProperties.color = .gray
        contentConfiguration = content

        toggleSwitch.isOn = isOn
        accessoryView = toggleSwitch
    }
}
