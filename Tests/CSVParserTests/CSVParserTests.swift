import XCTest
@testable import CSVParser

final class CSVParserTests: XCTestCase {
    
    let defaultOptions = CSVParser.ParsingOptions()
    
    /// Ensures that default options values stay the same
    func testDefaultOptions() {
        XCTAssertEqual(defaultOptions.allowsNonExhaustiveRows, true)
        XCTAssertEqual(defaultOptions.expectedRows, nil)
    }
    
    func testParseEmpty() throws {
        let result = try CSVParser(string: "").rawParse(options: defaultOptions)
        XCTAssertEqual(result, [[Substring]]())
    }
    
    func testParseEmptyEndline() throws {
        let csv = """
        a,b,c\r
        
        """
        let result = try CSVParser(string: csv).rawParse(options: defaultOptions)
        XCTAssertEqual(result.count, 1)
        
        let csvMultipleEmptyEndlines = """
        a,b,c\r
        \r
        
        """
        let result2 = try CSVParser(string: csvMultipleEmptyEndlines).rawParse(options: defaultOptions)
        XCTAssertEqual(result2.count, 1)
        
        let csvNoEndlineCr = """
        a,b,c
        
        """
        let result3 = try CSVParser(string: csvNoEndlineCr).rawParse(options: defaultOptions)
        XCTAssertEqual(result3.count, 1)
        //FIXME: This is a rather special case so it should be tested further
        XCTAssertEqual(result3.first, ["a","b","c"])
    }
    
    func testSingle() throws {
        let result = try CSVParser(string: "a").rawParse(options: defaultOptions)
        XCTAssertEqual(result, [["a"]])
        
        let quotedResult = try CSVParser(string: "\"a\"").rawParse(options: defaultOptions)
        XCTAssertEqual(quotedResult, [["a"]])
    }
    
    func testBasic() throws {
        let nonQuoted = """
        a,b,c
        """
        let result = try CSVParser(string: nonQuoted).rawParse(options: defaultOptions)
        XCTAssertEqual(result, [["a","b","c"]])
        
        let quoted = """
        "a","b","c"
        """
        let result2 = try CSVParser(string: quoted).rawParse(options: defaultOptions)
        XCTAssertEqual(result2, [["a","b","c"]])
    }
    
    func testParseLinereturns() throws {
        let csvNewLine = """
        a,b,c,
        d,e,f
        """
        let result = try CSVParser(string: csvNewLine).rawParse(options: defaultOptions)
        XCTAssertNotEqual(result, [["a","b","c","\nd","e","f"]])
        
        let csvQuotedNewLine = """
        "a","b","c","
        d","e","f"
        """
        let result2 = try CSVParser(string: csvQuotedNewLine).rawParse(options: defaultOptions)
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
