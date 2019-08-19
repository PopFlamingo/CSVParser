import XCTest
@testable import CSVParser

final class CSVParserTests: XCTestCase {
    func testCSV() throws {
        var csv = try String(contentsOfFile: "apath", encoding: .utf8)
        csv.makeContiguousUTF8()
        for _ in 1...5 {
            print(CSVParser(string: csv).parse().count)
        }
    }

    static var allTests = [
        ("testCSV", testCSV),
    ]
}
