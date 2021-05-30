import UIKit

class ProfileView: UIView {
  let nameLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 32)
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  let signOutButton: UIButton = {
    let button = UIButton()
    button.setTitle("Sign Out", for: .normal)
    button.setBackgroundImage(UIColor.red.pixel, for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 24)
    button.titleLabel?.textColor = .white
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }()

  private lazy var fieldsStackView: UIStackView = {
    let stackView = UIStackView(
      arrangedSubviews: [nameLabel, signOutButton]
    )
    stackView.axis = .vertical
    stackView.spacing = 8
    stackView.isLayoutMarginsRelativeArrangement = true
    stackView.directionalLayoutMargins = .init(top: 0, leading: 32, bottom: 0, trailing: 32)
    stackView.translatesAutoresizingMaskIntoConstraints = false
    return stackView
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }

  private func setup() {
    addSubview(fieldsStackView)
    NSLayoutConstraint.activate([
      signOutButton.heightAnchor.constraint(equalToConstant: 80),
      fieldsStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
      fieldsStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
      fieldsStackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor)
    ])
  }
}
