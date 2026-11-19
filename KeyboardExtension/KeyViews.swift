import UIKit

/// A flat, non-interactive key tile. All touches are handled by KeyboardView.
final class KeyView: UIView {
    let def: KeyDef
    let isFunctional: Bool

    private let label = UILabel()
    private let icon = UIImageView()
    private static let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)

    var isPressed = false {
        didSet {
            guard oldValue != isPressed else { return }
            refreshColors()
            if def.kind == .delete { iconName = isPressed ? "delete.left.fill" : "delete.left" }
        }
    }
    /// Shift active (on / caps lock): drawn with the standard key colour.
    var latched = false { didSet { if oldValue != latched { refreshColors() } } }
    var iconName: String? {
        didSet { icon.image = iconName.flatMap { UIImage(systemName: $0, withConfiguration: Self.symbolConfig) } }
    }

    var text: String? { label.text }

    init(def: KeyDef) {
        self.def = def
        switch def.kind {
        case .char, .space: isFunctional = false
        default: isFunctional = true
        }
        super.init(frame: .zero)
        isUserInteractionEnabled = false

        layer.cornerRadius = Metrics.corner
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.25
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 0

        label.textAlignment = .center
        label.textColor = Theme.text
        label.font = .systemFont(ofSize: 22)
        icon.contentMode = .center
        icon.tintColor = Theme.text
        addSubview(label)
        addSubview(icon)

        switch def.kind {
        case .char(let s): label.text = s
        case .space: label.text = "space"; label.font = .systemFont(ofSize: 16)
        case .returnKey: label.text = "return"; label.font = .systemFont(ofSize: 16)
        case .toNumbers: label.text = "123"; label.font = .systemFont(ofSize: 16)
        case .toLetters: label.text = "ABC"; label.font = .systemFont(ofSize: 16)
        case .toSymbols: label.text = "#+="; label.font = .systemFont(ofSize: 16)
        case .shift: iconName = "shift"
        case .delete: iconName = "delete.left"
        case .globe: iconName = "globe"
        }
        refreshColors()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    func setUppercase(_ upper: Bool) {
        if case .char(let s) = def.kind { label.text = upper ? s.uppercased() : s }
    }

    private func refreshColors() {
        let flip = isPressed != latched
        backgroundColor = (isFunctional != flip) ? Theme.fnKey : Theme.key
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds
        icon.frame = bounds
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: Metrics.corner).cgPath
    }
}

/// Classic key-pop preview: a wide "head" above the key joined to a key-sized "neck".
final class PopupView: UIView {
    private let shape = CAShapeLayer()
    private let label = UILabel()

    init() {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        isHidden = true
        shape.shadowColor = UIColor.black.cgColor
        shape.shadowOpacity = 0.3
        shape.shadowOffset = CGSize(width: 0, height: 1)
        shape.shadowRadius = 1.5
        layer.addSublayer(shape)
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 34)
        label.textColor = Theme.text
        addSubview(label)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    func show(text: String, over key: CGRect, containerWidth: CGFloat) {
        let bodyW = key.width + 20
        let up = min(40, key.minY)                 // clamp so the popup never leaves the view
        var x = key.minX - 10
        x = min(max(x, 0), containerWidth - bodyW)
        let h = up + key.height
        frame = CGRect(x: x, y: key.minY - up, width: bodyW, height: h)

        let bodyH = up + 12
        let body = CGRect(x: 0, y: 0, width: bodyW, height: bodyH)
        let neck = CGRect(x: key.minX - x, y: up, width: key.width, height: key.height)
        let path = UIBezierPath(roundedRect: body, cornerRadius: 8)
        path.append(UIBezierPath(roundedRect: neck, cornerRadius: Metrics.corner))

        shape.fillColor = Theme.key.resolvedColor(with: traitCollection).cgColor
        shape.path = path.cgPath
        shape.shadowPath = path.cgPath
        label.text = text
        label.frame = CGRect(x: 0, y: 0, width: bodyW, height: up >= 40 ? 52 : h)
        label.textColor = Theme.text
        isHidden = false
    }
}
