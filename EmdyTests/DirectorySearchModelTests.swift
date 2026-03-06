import XCTest
@testable import Emdy

final class DirectorySearchModelTests: XCTestCase {

    private func sampleNodes() -> [FileNode] {
        let file1 = FileNode(url: URL(fileURLWithPath: "/tmp/test/README.md"), isDirectory: false, children: nil)
        let file2 = FileNode(url: URL(fileURLWithPath: "/tmp/test/notes.md"), isDirectory: false, children: nil)
        let file3 = FileNode(url: URL(fileURLWithPath: "/tmp/test/docs/guide.md"), isDirectory: false, children: nil)
        let folder = FileNode(url: URL(fileURLWithPath: "/tmp/test/docs"), isDirectory: true, children: [file3])
        return [folder, file1, file2]
    }

    func testFileNameMatchIsCaseInsensitive() {
        let model = DirectorySearchModel()
        let nodes = sampleNodes()

        model.search(in: nodes, query: "readme")

        XCTAssertTrue(model.matchingFiles.contains(URL(fileURLWithPath: "/tmp/test/README.md")))
    }

    func testFileNameMatchPartialString() {
        let model = DirectorySearchModel()
        let nodes = sampleNodes()

        model.search(in: nodes, query: "note")

        XCTAssertTrue(model.matchingFiles.contains(URL(fileURLWithPath: "/tmp/test/notes.md")))
    }

    func testEmptyQueryReturnsNoResults() {
        let model = DirectorySearchModel()
        let nodes = sampleNodes()

        model.search(in: nodes, query: "")

        XCTAssertTrue(model.matchingFiles.isEmpty)
    }

    func testClearResetsState() {
        let model = DirectorySearchModel()
        let nodes = sampleNodes()

        model.search(in: nodes, query: "readme")
        XCTAssertFalse(model.matchingFiles.isEmpty)

        model.clear()

        XCTAssertTrue(model.query.isEmpty)
        XCTAssertTrue(model.matchingFiles.isEmpty)
        XCTAssertFalse(model.isSearching)
    }

    func testNoMatchReturnsEmpty() {
        let model = DirectorySearchModel()
        let nodes = sampleNodes()

        model.search(in: nodes, query: "zzzznonexistent")

        XCTAssertTrue(model.matchingFiles.isEmpty)
    }

    func testMatchInSubfolder() {
        let model = DirectorySearchModel()
        let nodes = sampleNodes()

        model.search(in: nodes, query: "guide")

        XCTAssertTrue(model.matchingFiles.contains(URL(fileURLWithPath: "/tmp/test/docs/guide.md")))
    }

    func testIsSearchingReflectsQuery() {
        let model = DirectorySearchModel()

        XCTAssertFalse(model.isSearching)

        model.query = "test"
        XCTAssertTrue(model.isSearching)

        model.query = ""
        XCTAssertFalse(model.isSearching)
    }
}
