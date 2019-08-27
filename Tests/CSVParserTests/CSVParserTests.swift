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
        XCTAssertEqual(try defaultParser.rawParse(string: "\"\",\"\""), [["",""]])
        XCTAssertEqual(try defaultParser.rawParse(string: ","), [["",""]])
        XCTAssertEqual(try defaultParser.rawParse(string: ",,"), [["","",""]])
    }
    
    func testParseEmptyEndline() throws {
        let csv = """
        a,b,c\r
        
        """
        let result = try! defaultParser.rawParse(string: csv)
        XCTAssertEqual(result.count, 1)
        
        let csvMultipleEmptyEndlines = """
        a,b,c\r
        \r
        
        """
        let result2 = try! defaultParser.rawParse(string: csvMultipleEmptyEndlines)
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
        XCTAssertThrowsError(try defaultParser.rawParse(string: csvNewLine))
        
        let csvQuotedNewLine = """
        "a","b","c","
        d","e","f"
        """
        let result2 = try defaultParser.rawParse(string: csvQuotedNewLine)
        XCTAssertEqual(result2, [["a","b","c","\nd","e","f"]])
    }
    
    func testParseBadSyntax() {
        XCTAssertThrowsError(try defaultParser.rawParse(string: "🐞")) { error in
            guard case CSVParser.ParserError.syntaxError(index: let index) = error else {
                return XCTFail("This should be a syntax error")
            }
            XCTAssertEqual(index, "🐞".startIndex)
        }
        
        XCTAssertThrowsError(try defaultParser.rawParse(string: "🐞,🐞")) { error in
            guard case CSVParser.ParserError.syntaxError(index: let index) = error else {
                return XCTFail("This should be a syntax error")
            }
            XCTAssertEqual(index, "🐞,🐞".startIndex)
        }
        
        let validAndInvalid = "a,🐞"
        XCTAssertThrowsError(try defaultParser.rawParse(string: validAndInvalid)) { error in
            guard case CSVParser.ParserError.syntaxError(index: let index) = error else {
                return XCTFail("This should be a syntax error")
            }
            XCTAssertEqual(index, validAndInvalid.index(validAndInvalid.startIndex, offsetBy: 2))
        }
        
        let validAndInvalid2 = "a🐞,🐞"
        XCTAssertThrowsError(try defaultParser.rawParse(string: validAndInvalid2)) { error in
            guard case CSVParser.ParserError.syntaxError(index: let index) = error else {
                return XCTFail("This should be a syntax error")
            }
            XCTAssertEqual(index, validAndInvalid2.index(validAndInvalid2.startIndex, offsetBy: 1))
        }
        
        let quotedInvalid = "\"🐞\",\"🐞\""
        XCTAssertThrowsError(try defaultParser.rawParse(string: quotedInvalid)) { error in
            guard case CSVParser.ParserError.syntaxError(index: let index) = error else {
                return XCTFail("This should be a syntax error")
            }
            XCTAssertEqual(index, quotedInvalid.index(quotedInvalid.startIndex, offsetBy: 1))
        }
    }
    
    static var allTests = [
        ("testDefaultOptions", testDefaultOptions),
        ("testParseEmpty", testParseEmpty),
        ("testParseEmptyEndline", testParseEmptyEndline),
        ("testSingle", testSingle),
        ("testBasic", testBasic),
        ("testParseLinereturns", testParseLinereturns),
        ("testParseBadSyntax", testParseBadSyntax)
    ]
}
