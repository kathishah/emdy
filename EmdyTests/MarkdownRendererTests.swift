import XCTest
@testable import Emdy

final class MarkdownRendererTests: XCTestCase {

    private func render(_ markdown: String) -> NSAttributedString {
        let renderer = MarkdownRenderer(fontFamily: .sansSerif, zoomLevel: 1.0)
        return renderer.render(markdown)
    }

    func testHeadingRendering() {
        let result = render("# Hello World")
        XCTAssertTrue(result.string.contains("Hello World"))

        // Check that heading uses the correct font
        var range = NSRange()
        let font = result.attribute(.font, at: 0, effectiveRange: &range) as? NSFont
        XCTAssertNotNil(font)
        XCTAssertEqual(font?.pointSize, 28) // H1 = 28pt at 1.0x zoom
    }

    func testBoldRendering() {
        let result = render("**bold text**")
        XCTAssertTrue(result.string.contains("bold text"))
    }

    func testItalicRendering() {
        let result = render("*italic text*")
        XCTAssertTrue(result.string.contains("italic text"))
    }

    func testLinkRendering() {
        let result = render("[Click here](https://example.com)")
        XCTAssertTrue(result.string.contains("Click here"))

        var range = NSRange()
        let link = result.attribute(.link, at: 0, effectiveRange: &range)
        XCTAssertNotNil(link)
    }

    func testCodeInlineRendering() {
        let result = render("Use `code` here")
        XCTAssertTrue(result.string.contains("code"))
    }

    func testCodeBlockRendering() {
        let result = render("```\nlet x = 1\n```")
        XCTAssertTrue(result.string.contains("let x = 1"))
    }

    func testListRendering() {
        let result = render("- Item 1\n- Item 2\n- Item 3")
        XCTAssertTrue(result.string.contains("Item 1"))
        XCTAssertTrue(result.string.contains("Item 2"))
        XCTAssertTrue(result.string.contains("\u{2022}")) // bullet character
    }

    func testOrderedListRendering() {
        let result = render("1. First\n2. Second\n3. Third")
        XCTAssertTrue(result.string.contains("First"))
        XCTAssertTrue(result.string.contains("1."))
    }

    func testBlockquoteRendering() {
        let result = render("> This is a quote")
        XCTAssertTrue(result.string.contains("This is a quote"))
    }

    func testStrikethroughRendering() {
        let result = render("~~deleted~~")
        XCTAssertTrue(result.string.contains("deleted"))
    }

    func testTableRendering() {
        let md = """
        | Name | Age |
        |------|-----|
        | Alice | 30 |
        """
        let result = render(md)
        XCTAssertTrue(result.string.contains("Name"))
        XCTAssertTrue(result.string.contains("Alice"))
    }

    func testZoomScaling() {
        let renderer2x = MarkdownRenderer(fontFamily: .sansSerif, zoomLevel: 2.0)
        let result = renderer2x.render("# Big")

        var range = NSRange()
        let font = result.attribute(.font, at: 0, effectiveRange: &range) as? NSFont
        XCTAssertNotNil(font)
        XCTAssertEqual(font?.pointSize, 56) // 28 * 2.0
    }

    func testEmptyDocument() {
        let result = render("")
        XCTAssertEqual(result.length, 0)
    }

    func testFontFamilySwitch() {
        for family in FontFamily.allCases {
            let renderer = MarkdownRenderer(fontFamily: family, zoomLevel: 1.0)
            let result = renderer.render("Hello")
            XCTAssertTrue(result.length > 0)
        }
    }

    func testDarkModeRendering() {
        let renderer = MarkdownRenderer(fontFamily: .sansSerif, zoomLevel: 1.0, isDark: true)
        let result = renderer.render("# Dark heading\n\nSome body text")
        XCTAssertTrue(result.string.contains("Dark heading"))

        let darkPalette = ColorPalette.current(dark: true)
        var range = NSRange()
        let color = result.attribute(.foregroundColor, at: 0, effectiveRange: &range) as? NSColor
        XCTAssertNotNil(color)
        XCTAssertEqual(color, darkPalette.headline)
    }
}
