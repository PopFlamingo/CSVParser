import XCTest
@testable import CSVParser

final class CSVParserTests: XCTestCase {
    
    let defaultParser = CSVParser(parsingOptions: .RFC4180)
    
    func testParseEmpty() throws {
        XCTAssertEqual(try defaultParser.parse(string: ""), [[Substring]]())
        XCTAssertEqual(try defaultParser.parse(string: "\"\",\"\""), [["",""]])
        XCTAssertEqual(try defaultParser.parse(string: ","), [["",""]])
        XCTAssertEqual(try defaultParser.parse(string: ",,"), [["","",""]])
    }
    
    func testParseEmptyEndline() throws {
        let csv = """
        a,b,c\r
        
        """
        let result = try! defaultParser.parse(string: csv)
        XCTAssertEqual(result.count, 1)
        
        let csvMultipleEmptyEndlines = """
        a,b,c\r
        \r
        
        """
        let result2 = try! defaultParser.parse(string: csvMultipleEmptyEndlines)
        XCTAssertEqual(result2.count, 1)
        
        let csvNoEndlineCr = """
        a,b,c
        
        """
        let result3 = try defaultParser.parse(string: csvNoEndlineCr)
        XCTAssertEqual(result3.count, 1)
        //FIXME: This is a rather special case so it should be tested further
        XCTAssertEqual(result3.first, ["a","b","c"])
    }
    
    func testSingle() throws {
        let result = try defaultParser.parse(string: "a")
        XCTAssertEqual(result, [["a"]])
        
        let quotedResult = try defaultParser.parse(string: "\"a\"")
        XCTAssertEqual(quotedResult, [["a"]])
    }
    
    func testBasic() throws {
        let nonQuoted = """
        a,b,c
        """
        let result = try defaultParser.parse(string: nonQuoted)
        XCTAssertEqual(result, [["a","b","c"]])
        
        let quoted = """
        "a","b","c"
        """
        let result2 = try defaultParser.parse(string: quoted)
        XCTAssertEqual(result2, [["a","b","c"]])
    }
    
    func testParseLinereturns() throws {
        let csvNewLine = """
        a,b,c,
        d,e,f
        """
        XCTAssertThrowsError(try defaultParser.parse(string: csvNewLine))
        
        let csvQuotedNewLine = """
        "a","b","c","
        d","e","f"
        """
        let result2 = try defaultParser.parse(string: csvQuotedNewLine)
        XCTAssertEqual(result2, [["a","b","c","\nd","e","f"]])
    }
    
    func testParseBadSyntax() {
        XCTAssertThrowsError(try defaultParser.parse(string: "🐞")) { error in
            guard case CSVParser.ParserError.syntaxError(index: let index) = error else {
                return XCTFail("This should be a syntax error")
            }
            XCTAssertEqual(index, "🐞".startIndex)
        }
        
        XCTAssertThrowsError(try defaultParser.parse(string: "🐞,🐞")) { error in
            guard case CSVParser.ParserError.syntaxError(index: let index) = error else {
                return XCTFail("This should be a syntax error")
            }
            XCTAssertEqual(index, "🐞,🐞".startIndex)
        }
        
        let validAndInvalid = "a,🐞"
        XCTAssertThrowsError(try defaultParser.parse(string: validAndInvalid)) { error in
            guard case CSVParser.ParserError.syntaxError(index: let index) = error else {
                return XCTFail("This should be a syntax error")
            }
            XCTAssertEqual(index, validAndInvalid.index(validAndInvalid.startIndex, offsetBy: 2))
        }
        
        let validAndInvalid2 = "a🐞,🐞"
        XCTAssertThrowsError(try defaultParser.parse(string: validAndInvalid2)) { error in
            guard case CSVParser.ParserError.syntaxError(index: let index) = error else {
                return XCTFail("This should be a syntax error")
            }
            XCTAssertEqual(index, validAndInvalid2.index(validAndInvalid2.startIndex, offsetBy: 1))
        }
        
        let quotedInvalid = "\"🐞\",\"🐞\""
        XCTAssertThrowsError(try defaultParser.parse(string: quotedInvalid)) { error in
            guard case CSVParser.ParserError.syntaxError(index: let index) = error else {
                return XCTFail("This should be a syntax error")
            }
            XCTAssertEqual(index, quotedInvalid.index(quotedInvalid.startIndex, offsetBy: 1))
        }
    }
    
    func testParseEmptyNonEmptyMix() throws  {
        let example = """
        a,b,\r
        ,,\r
        c,d,e
        """
        XCTAssertEqual(try defaultParser.parse(string: example), [["a", "b", ""], ["","",""], ["c","d","e"]])
    }
    
    func testParseUnicodeCSV() throws {
        let emojis = """
        🍨,🥮,🍳\r
        🥨,a🌽,🌶\r
        🥑,🍅,"🥭"\r
        ,"🥗🍕\n🚄",🗽
        """
        let unicodeParser = CSVParser(parsingOptions: .unicode)
        XCTAssertEqual(try unicodeParser.parse(string: emojis), [["🍨","🥮","🍳"],["🥨","a🌽","🌶"],["🥑","🍅","🥭"], ["", "🥗🍕\n🚄", "🗽"]])
    }
    
    static var allTests = [
        ("testParseEmpty", testParseEmpty),
        ("testParseEmptyEndline", testParseEmptyEndline),
        ("testSingle", testSingle),
        ("testBasic", testBasic),
        ("testParseLinereturns", testParseLinereturns),
        ("testParseBadSyntax", testParseBadSyntax),
        ("testParseEmptyNonEmptyMix", testParseEmptyNonEmptyMix),
        ("testParseUnicodeCSV", testParseUnicodeCSV),
    ]
}
