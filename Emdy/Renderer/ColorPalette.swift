import AppKit
import SwiftUI

struct ColorPalette {
    // Backgrounds
    let background: NSColor
    let secondaryBackground: NSColor
    let sidebarBackground: NSColor

    // Borders
    let border: NSColor
    let subtleBorder: NSColor

    // Text
    let headline: NSColor
    let body: NSColor
    let medium: NSColor
    let muted: NSColor

    // Accents
    let accent: NSColor
    let link: NSColor
    let success: NSColor
    let successBackground: NSColor
    let error: NSColor

    // Code
    let codeBackground: NSColor
    let codeText: NSColor

    // Syntax highlighting
    let syntaxKeyword: NSColor
    let syntaxString: NSColor
    let syntaxComment: NSColor
    let syntaxNumber: NSColor

    // Blockquote
    let blockquoteBorder: NSColor
    let blockquoteText: NSColor

    // Selection highlight in sidebar
    let sidebarSelection: NSColor

    // MARK: - Resolvers

    static func current(dark: Bool) -> ColorPalette {
        dark ? .dark : .light
    }

    static func current(for colorScheme: ColorScheme) -> ColorPalette {
        colorScheme == .dark ? .dark : .light
    }
}

// MARK: - Palettes

extension ColorPalette {
    static let light = makeLight()
    static let dark = makeDark()

    private static func makeLight() -> ColorPalette {
        let bg: NSColor = NSColor(hex: "#F5F2ED")
        let secBg: NSColor = NSColor(hex: "#EDEAE4")
        let sbarBg: NSColor = NSColor(hex: "#E3DDD5")
        let brd: NSColor = NSColor(hex: "#D9D2C6")
        let sBrd: NSColor = NSColor(hex: "#CCC4B8")
        let hdl: NSColor = NSColor(hex: "#2B2622")
        let bdy: NSColor = NSColor(hex: "#4A433B")
        let med: NSColor = NSColor(hex: "#7A7268")
        let mut: NSColor = NSColor(hex: "#9C9488")
        let acc: NSColor = NSColor(hex: "#ED8008")
        let lnk: NSColor = NSColor(hex: "#5A6D7A")
        let suc: NSColor = NSColor(hex: "#5F6B2D")
        let sucBg: NSColor = NSColor(hex: "#F0F2EA")
        let err: NSColor = NSColor(hex: "#BF1B1B")
        return ColorPalette(
            background: bg, secondaryBackground: secBg, sidebarBackground: sbarBg,
            border: brd, subtleBorder: sBrd,
            headline: hdl, body: bdy, medium: med, muted: mut,
            accent: acc, link: lnk,
            success: suc, successBackground: sucBg, error: err,
            codeBackground: secBg, codeText: bdy,
            syntaxKeyword: NSColor(hex: "#8B5A3C"),
            syntaxString: NSColor(hex: "#5F6B2D"),
            syntaxComment: mut,
            syntaxNumber: lnk,
            blockquoteBorder: brd, blockquoteText: med,
            sidebarSelection: brd
        )
    }

    private static func makeDark() -> ColorPalette {
        let bg: NSColor = NSColor(hex: "#1E1C19")
        let secBg: NSColor = NSColor(hex: "#28251F")
        let sbarBg: NSColor = NSColor(hex: "#232019")
        let brd: NSColor = NSColor(hex: "#3D382F")
        let sBrd: NSColor = NSColor(hex: "#33302A")
        let hdl: NSColor = NSColor(hex: "#E8E3DB")
        let bdy: NSColor = NSColor(hex: "#C4BCB0")
        let med: NSColor = NSColor(hex: "#8A8278")
        let mut: NSColor = NSColor(hex: "#6B6359")
        let acc: NSColor = NSColor(hex: "#F09830")
        let lnk: NSColor = NSColor(hex: "#8AAAB8")
        let suc: NSColor = NSColor(hex: "#8A9B50")
        let sucBg: NSColor = NSColor(hex: "#2A2C1E")
        let err: NSColor = NSColor(hex: "#D94040")
        return ColorPalette(
            background: bg, secondaryBackground: secBg, sidebarBackground: sbarBg,
            border: brd, subtleBorder: sBrd,
            headline: hdl, body: bdy, medium: med, muted: mut,
            accent: acc, link: lnk,
            success: suc, successBackground: sucBg, error: err,
            codeBackground: secBg, codeText: bdy,
            syntaxKeyword: NSColor(hex: "#D4A574"),
            syntaxString: NSColor(hex: "#8A9B50"),
            syntaxComment: mut,
            syntaxNumber: lnk,
            blockquoteBorder: brd, blockquoteText: med,
            sidebarSelection: brd
        )
    }
}
