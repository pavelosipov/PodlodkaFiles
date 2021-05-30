import UIKit

final class AuthenticationView: UIView {
  private let titleLabel: UILabel = {
    let label = UILabel()
    label.text = "Podlodka Files"
    label.textAlignment = .center
    label.font = UIFont.systemFont(ofSize: 32)
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  let nameField: UITextField = {
    let field = UITextField()
    field.placeholder = "Name"
    field.autocorrectionType = .no
    field.spellCheckingType = .no
    field.font = UIFont.systemFont(ofSize: 32)
    field.translatesAutoresizingMaskIntoConstraints = false
    return field
  }()

  let passwordField: UITextField = {
    let field = UITextField()
    field.placeholder = "Password"
    field.font = UIFont.systemFont(ofSize: 32)
    field.isSecureTextEntry = true
    field.translatesAutoresizingMaskIntoConstraints = false
    return field
  }()

  let signInButton: UIButton = {
    let button = UIButton()
    button.setTitle("Sign In", for: .normal)
    button.setBackgroundImage(UIColor.blue.pixel, for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 24)
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }()

  private lazy var fieldsStackView: UIStackView = {
    let stackView = UIStackView(
      arrangedSubviews: [titleLabel, nameField, passwordField, signInButton]
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
      signInButton.heightAnchor.constraint(equalToConstant: 80),
      fieldsStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
      fieldsStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
      fieldsStackView.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor, constant: -40)
    ])
  }
}
