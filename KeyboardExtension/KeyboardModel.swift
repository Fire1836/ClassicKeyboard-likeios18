import UIKit

enum Metrics {
    static let keyH: CGFloat = 42
    static let gapH: CGFloat = 6
    static let gapV: CGFloat = 11
    static let margin: CGFloat = 3
    static let top: CGFloat = 8
    static let bottom: CGFloat = 7
    static let corner: CGFloat = 5
    // 8 + 4*42 + 3*11 + 7 = 216
    static let totalHeight: CGFloat = top + 4 * keyH + 3 * gapV + bottom
}

enum Theme {
    static let background = dyn(light: 0xD1D3D9, dark: 0x1C1C1E)
    static let key        = dyn(light: 0xFFFFFF, dark: 0x4A4A4C)
    static let fnKey      = dyn(light: 0xACB3BF, dark: 0x2C2C2E)
    static let text       = dyn(light: 0x000000, dark: 0xFFFFFF)

    private static func dyn(light: UInt32, dark: UInt32) -> UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) }
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: 1)
    }
}

enum ShiftState { case off, on, caps }

enum KeyKind: Equatable {
    case char(String)
    case shift, delete, space, returnKey, globe
    case toNumbers, toLetters, toSymbols
}

enum KeyWidth { case std, fn, ret, flex }

struct KeyDef {
    let kind: KeyKind
    let width: KeyWidth
}

enum LayoutID { case letters, numbers, symbols }

enum Layouts {
    private static func chars(_ s: String, _ w: KeyWidth = .std) -> [KeyDef] {
        s.map { KeyDef(kind: .char(String($0)), width: w) }
    }

    private static func bottomRow(first: KeyKind, globe: Bool) -> [KeyDef] {
        var r = [KeyDef(kind: first, width: .fn)]
        if globe { r.append(KeyDef(kind: .globe, width: .fn)) }
        r.append(KeyDef(kind: .space, width: .flex))
        r.append(KeyDef(kind: .returnKey, width: .ret))
        return r
    }

    static func rows(for id: LayoutID, showGlobe: Bool) -> [[KeyDef]] {
        let del = KeyDef(kind: .delete, width: .fn)
        switch id {
        case .letters:
            return [
                chars("qwertyuiop"),
                chars("asdfghjkl"),
                [KeyDef(kind: .shift, width: .fn)] + chars("zxcvbnm") + [del],
                bottomRow(first: .toNumbers, globe: showGlobe)
            ]
        case .numbers:
            return [
                chars("1234567890"),
                chars("-/:;()$&@\""),
                [KeyDef(kind: .toSymbols, width: .fn)] + chars(".,?!'", .flex) + [del],
                bottomRow(first: .toLetters, globe: showGlobe)
            ]
        case .symbols:
            return [
                chars("[]{}#%^*+="),
                chars("_\\|~<>€£¥•"),
                [KeyDef(kind: .toNumbers, width: .fn)] + chars(".,?!'", .flex) + [del],
                bottomRow(first: .toLetters, globe: showGlobe)
            ]
        }
    }
}
