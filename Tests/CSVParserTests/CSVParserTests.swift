import XCTest
@testable import CSVParser

final class CSVParserTests: XCTestCase {
    
    let defaultOptions = CSVParser.ValidationOptions()
    let defaultParser = CSVParser(validationOptions: CSVParser.ValidationOptions())
    
    /// Ensures that default options values stay the same
    func testDefaultOptions() {
        XCTAssertEqual(defaultOptions.allowsNonExhaustiveRows, true)
        XCTAssertEqual(defaultOptions.expectedRows, nil)
    }
    
    func testParseEmpty() throws {
        XCTAssertEqual(try defaultParser.rawParse(string: ""), [[Substring]]())
    }
    
    func testParseEmptyEndline() throws {
        let csv = """
        a,b,c\r
        
        """
        let result = try defaultParser.rawParse(string: csv)
        XCTAssertEqual(result.count, 1)
        
        let csvMultipleEmptyEndlines = """
        a,b,c\r
        \r
        
        """
        let result2 = try defaultParser.rawParse(string: csvMultipleEmptyEndlines)
        XCTAssertEqual(result2.count, 1)
        
        let csvNoEndlineCr = """
        a,b,c
        
        """
        let result3 = try defaultParser.rawParse(string: csvNoEndlineCr)
        XCTAssertEqual(result3.count, 1)
        //FIXME: This is a rather special case so it should be tested further
        XCTAssertEqual(result3.first, ["a","b","c"])
    }
    
    func testSingle() throws {
        let result = try defaultParser.rawParse(string: "a")
        XCTAssertEqual(result, [["a"]])
        
        let quotedResult = try defaultParser.rawParse(string: "\"a\"")
        XCTAssertEqual(quotedResult, [["a"]])
    }
    
    func testBasic() throws {
        let nonQuoted = """
        a,b,c
        """
        let result = try defaultParser.rawParse(string: nonQuoted)
        XCTAssertEqual(result, [["a","b","c"]])
        
        let quoted = """
        "a","b","c"
        """
        let result2 = try defaultParser.rawParse(string: quoted)
        XCTAssertEqual(result2, [["a","b","c"]])
    }
    
    func testParseLinereturns() throws {
        let csvNewLine = """
        a,b,c,
        d,e,f
        """
        let result = try defaultParser.rawParse(string: csvNewLine)
        XCTAssertNotEqual(result, [["a","b","c","\nd","e","f"]])
        
        let csvQuotedNewLine = """
        "a","b","c","
        d","e","f"
        """
        let result2 = try defaultParser.rawParse(string: csvQuotedNewLine)
        XCTAssertEqual(result2, [["a","b","c","\nd","e","f"]])
    }
    
    func testParseMalformed() {
        
    }

    static var allTests = [
        ("testDefaultOptions", testDefaultOptions),
        ("testParseEmpty", testParseEmpty),
        ("testParseEmptyEndline", testParseEmptyEndline),
        ("testSingle", testSingle),
        ("testBasic", testBasic),
        ("testParseDoesntConfuseNewLines", testParseLinereturns)
    ]
}
