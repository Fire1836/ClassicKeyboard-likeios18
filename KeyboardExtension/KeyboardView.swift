import UIKit

protocol KeyboardViewDelegate: AnyObject {
    /// Fired on touch-down for zero-latency input.
    func keyDown(_ def: KeyDef)
    func keyUp(_ def: KeyDef, cancelled: Bool)
}

final class KeyboardView: UIInputView, UIInputViewAudioFeedback {
    weak var delegate: KeyboardViewDelegate?

    // Required for UIDevice.current.playInputClick()
    var enableInputClicksWhenVisible: Bool { true }

    var layoutID: LayoutID = .letters {
        didSet { if oldValue != layoutID { rebuild() } }
    }
    var showGlobe = false {
        didSet { if oldValue != showGlobe { rebuild() } }
    }
    var shiftState: ShiftState = .off {
        didSet { if oldValue != shiftState { applyShiftState() } }
    }

    private var keyRows: [[KeyView]] = []
    private var active: [ObjectIdentifier: KeyView] = [:]
    private var popupOwner: ObjectIdentifier?
    private let popup = PopupView()

    init() {
        super.init(frame: .zero, inputViewStyle: .default)
        allowsSelfSizing = true
        backgroundColor = Theme.background
        isMultipleTouchEnabled = true
        addSubview(popup)
        rebuild()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    // MARK: Building

    private func rebuild() {
        keyRows.forEach { $0.forEach { $0.removeFromSuperview() } }
        popup.isHidden = true
        popupOwner = nil
        keyRows = Layouts.rows(for: layoutID, showGlobe: showGlobe).map { row in
            row.map { def in
                let kv = KeyView(def: def)
                addSubview(kv)
                return kv
            }
        }
        bringSubviewToFront(popup)
        applyShiftState()
        setNeedsLayout()
    }

    private func applyShiftState() {
        let upper = layoutID == .letters && shiftState != .off
        for row in keyRows {
            for kv in row {
                switch kv.def.kind {
                case .char: kv.setUppercase(upper)
                case .shift:
                    kv.latched = shiftState != .off
                    kv.iconName = shiftState == .caps ? "capslock.fill" : (shiftState == .on ? "shift.fill" : "shift")
                default: break
                }
            }
        }
    }

    // MARK: Layout

    private func snap(_ v: CGFloat) -> CGFloat {
        let s = max(traitCollection.displayScale, 1)
        return (v * s).rounded() / s
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let W = bounds.width
        guard W > 0 else { return }
        let m = Metrics.margin, gh = Metrics.gapH
        let avail = W - 2 * m
        let k = (avail - 9 * gh) / 10                    // standard key width
        let fn = (avail - 7 * k - 8 * gh) / 2            // shift / delete / mode keys
        let retW = k * 2.4

        for (r, row) in keyRows.enumerated() {
            let y = Metrics.top + CGFloat(r) * (Metrics.keyH + Metrics.gapV)
            var fixed: CGFloat = 0
            var flexCount = 0
            for kv in row {
                switch kv.def.width {
                case .std: fixed += k
                case .fn: fixed += fn
                case .ret: fixed += retW
                case .flex: flexCount += 1
                }
            }
            let gaps = CGFloat(row.count - 1) * gh
            let flexW = flexCount > 0 ? (avail - fixed - gaps) / CGFloat(flexCount) : 0
            let used = flexCount > 0 ? avail : fixed + gaps
            var x = (W - used) / 2                      // centres the 9-key middle row
            for kv in row {
                let w: CGFloat
                switch kv.def.width {
                case .std: w = k
                case .fn: w = fn
                case .ret: w = retW
                case .flex: w = flexW
                }
                kv.frame = CGRect(x: snap(x), y: y, width: snap(w), height: Metrics.keyH)
                x += w + gh
            }
        }
    }

    // MARK: Hit testing (no dead zones: gaps are split at the midpoint, margins clamp to nearest key)

    private func key(at p: CGPoint) -> KeyView? {
        guard !keyRows.isEmpty else { return nil }
        let pitch = Metrics.keyH + Metrics.gapV
        var r = Int(floor((p.y - Metrics.top + Metrics.gapV / 2) / pitch))
        r = min(max(r, 0), keyRows.count - 1)
        var best: KeyView?
        var bestD = CGFloat.greatestFiniteMagnitude
        for kv in keyRows[r] {
            let f = kv.frame
            let d = p.x < f.minX ? f.minX - p.x : (p.x > f.maxX ? p.x - f.maxX : 0)
            if d < bestD { bestD = d; best = kv }
        }
        return best
    }

    // MARK: Touches

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            guard let kv = key(at: t.location(in: self)) else { continue }
            let id = ObjectIdentifier(t)
            active[id] = kv
            delegate?.keyDown(kv.def)           // input first, visuals second
            kv.isPressed = true
            if case .char = kv.def.kind, let text = kv.text {
                popup.show(text: text, over: kv.frame, containerWidth: bounds.width)
                popupOwner = id
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        finish(touches, cancelled: false)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        finish(touches, cancelled: true)
    }

    private func finish(_ touches: Set<UITouch>, cancelled: Bool) {
        for t in touches {
            let id = ObjectIdentifier(t)
            guard let kv = active.removeValue(forKey: id) else { continue }
            kv.isPressed = false
            if popupOwner == id { popup.isHidden = true; popupOwner = nil }
            delegate?.keyUp(kv.def, cancelled: cancelled)
        }
    }
}
