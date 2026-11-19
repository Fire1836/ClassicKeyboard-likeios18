import UIKit

final class KeyboardViewController: UIInputViewController, KeyboardViewDelegate {
    private var kb: KeyboardView!
    private var layoutID: LayoutID = .letters
    private var shiftState: ShiftState = .off
    private var userShiftOverride = false
    private var lastShiftTap: CFTimeInterval = 0
    private var lastSpaceTap: CFTimeInterval = 0
    private var repeatTimer: Timer?
    private let haptic = UIImpactFeedbackGenerator(style: .light)

    // MARK: Lifecycle

    override func loadView() {
        kb = KeyboardView()
        kb.delegate = self
        kb.showGlobe = needsInputModeSwitchKey
        view = kb
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let h = view.heightAnchor.constraint(equalToConstant: Metrics.totalHeight)
        h.priority = UILayoutPriority(999)
        h.isActive = true
        haptic.prepare()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateAutoShift()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        kb.showGlobe = needsInputModeSwitchKey
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        updateAutoShift()
    }

    deinit { repeatTimer?.invalidate() }

    // MARK: KeyboardViewDelegate

    func keyDown(_ def: KeyDef) {
        let proxy = textDocumentProxy
        switch def.kind {
        case .char(let s):
            userShiftOverride = false
            let upper = layoutID == .letters && shiftState != .off
            proxy.insertText(upper ? s.uppercased() : s)     // instant
            feedback()
            if shiftState == .on { setShift(.off) }

        case .space:
            userShiftOverride = false
            let now = CACurrentMediaTime()
            var handled = false
            if now - lastSpaceTap < 0.3, let before = proxy.documentContextBeforeInput,
               before.hasSuffix(" ") {
                let body = before.dropLast()
                if let prev = body.last, !prev.isWhitespace, prev != "." {
                    proxy.deleteBackward()
                    proxy.insertText(". ")
                    handled = true
                }
            }
            if !handled { proxy.insertText(" ") }
            lastSpaceTap = handled ? 0 : now
            feedback()
            updateAutoShift()

        case .returnKey:
            userShiftOverride = false
            proxy.insertText("\n")
            feedback()
            updateAutoShift()

        case .delete:
            userShiftOverride = false
            proxy.deleteBackward()
            feedback()
            startRepeat()

        case .shift:
            let now = CACurrentMediaTime()
            if shiftState == .caps {
                setShift(.off)
            } else if now - lastShiftTap < 0.3 {
                setShift(.caps)
            } else {
                setShift(shiftState == .on ? .off : .on)
            }
            lastShiftTap = now
            userShiftOverride = true
            feedback()

        case .toNumbers: switchLayout(.numbers)
        case .toSymbols: switchLayout(.symbols)
        case .toLetters: switchLayout(.letters)

        case .globe:
            feedback()
        }
    }

    func keyUp(_ def: KeyDef, cancelled: Bool) {
        switch def.kind {
        case .delete:
            stopRepeat()
            updateAutoShift()
        case .globe:
            if !cancelled { advanceToNextInputMode() }
        default: break
        }
    }

    // MARK: Helpers

    private func feedback() {
        UIDevice.current.playInputClick()
        haptic.impactOccurred()
        haptic.prepare()
    }

    private func setShift(_ s: ShiftState) {
        shiftState = s
        kb.shiftState = s
    }

    private func switchLayout(_ id: LayoutID) {
        layoutID = id
        kb.layoutID = id
        feedback()
        if id == .letters { userShiftOverride = false; updateAutoShift() }
    }

    private func updateAutoShift() {
        guard layoutID == .letters, shiftState != .caps, !userShiftOverride else { return }
        let want: ShiftState = shouldAutoCapitalize() ? .on : .off
        if want != shiftState { setShift(want) }
    }

    private func shouldAutoCapitalize() -> Bool {
        let proxy = textDocumentProxy
        guard let type = proxy.autocapitalizationType, type != .none else { return false }
        let before = proxy.documentContextBeforeInput ?? ""
        switch type {
        case .allCharacters:
            return true
        case .words:
            guard let last = before.last else { return true }
            return last.isWhitespace
        case .sentences:
            guard let last = before.last else { return true }
            if last == "\n" { return true }
            guard last == " " else { return false }
            let trimmed = before.trimmingCharacters(in: .whitespaces)
            guard let l = trimmed.last else { return true }
            return l == "." || l == "?" || l == "!" || l == "\n"
        default:
            return false
        }
    }

    // MARK: Hold-to-repeat delete

    private func startRepeat() {
        stopRepeat()
        let t = Timer(timeInterval: 0.4, repeats: false) { [weak self] _ in self?.beginFastRepeat() }
        RunLoop.main.add(t, forMode: .common)
        repeatTimer = t
    }

    private func beginFastRepeat() {
        let t = Timer(timeInterval: 0.07, repeats: true) { [weak self] _ in
            self?.textDocumentProxy.deleteBackward()
            UIDevice.current.playInputClick()
        }
        RunLoop.main.add(t, forMode: .common)
        repeatTimer = t
    }

    private func stopRepeat() {
        repeatTimer?.invalidate()
        repeatTimer = nil
    }
}
