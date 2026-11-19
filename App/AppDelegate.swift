import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let w = UIWindow(frame: UIScreen.main.bounds)
        w.rootViewController = InstructionViewController()
        w.makeKeyAndVisible()
        window = w
        return true
    }
}

final class InstructionViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let title = UILabel()
        title.text = "Classic Keyboard"
        title.font = .systemFont(ofSize: 28, weight: .bold)

        let steps = UILabel()
        steps.numberOfLines = 0
        steps.font = .systemFont(ofSize: 17)
        steps.text = """
        To enable the keyboard:

        1. Open Settings > General > Keyboard > Keyboards.
        2. Tap "Add New Keyboard…".
        3. Choose "Classic Keyboard" under Third-Party Keyboards.

        It works fully offline and does not need "Allow Full Access".

        Switch to it with the globe key, then try it below.
        """

        let button = UIButton(type: .system)
        button.setTitle("Open Settings", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.addTarget(self, action: #selector(openSettings), for: .touchUpInside)

        let field = UITextView()
        field.font = .systemFont(ofSize: 17)
        field.layer.cornerRadius = 8
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.separator.cgColor
        field.heightAnchor.constraint(equalToConstant: 100).isActive = true

        let stack = UIStackView(arrangedSubviews: [title, steps, button, field])
        stack.axis = .vertical
        stack.spacing = 18
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
        ])

        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
