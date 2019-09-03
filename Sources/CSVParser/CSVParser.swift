import Foundation
import ParserBuilder

public class CSVParser {
    
    @usableFromInline
    let goToEnd: Matcher = ("\r" || "\n" || "\r\n" || Matcher(" ")).atLeast(0).optimize()
    
    @usableFromInline
    let escapedContent: Matcher
    
    @usableFromInline
    let unescapedContent: Matcher
    
    @inlinable
    public init(parsingOptions: ParsingOptions) {
        self.extractor = Extractor("")
        let optimizedEndOfLine = parsingOptions.endOfLine
        optimizedEndOfLine.optimize()
        let optimizedUnescapedContent = parsingOptions.unescapedContent
        optimizedUnescapedContent.optimize()
        let optimizedSeparator = parsingOptions.separator
        optimizedSeparator.optimize()
        let optimizedQuote = parsingOptions.quote
        optimizedQuote.optimize()
        let optimizedQuotedNewline = parsingOptions.quotedNewlines
        optimizedQuotedNewline.optimize()
        
        
        self.parsingOptions = ParsingOptions(
            endOfLine: optimizedEndOfLine,
            unescapedContent: optimizedUnescapedContent,
            separator: optimizedSeparator,
            quote: optimizedQuote,
            quotedNewlines: optimizedQuotedNewline)
        
        self.escapedContent = (self.parsingOptions.unescapedContent || self.parsingOptions.separator || self.parsingOptions.quotedNewlines || self.parsingOptions.quote.count(2)).atLeast(0).optimize()
        self.unescapedContent = self.parsingOptions.unescapedContent.atLeast(1).optimize()
    }
    
    @usableFromInline
    var extractor: Extractor
    
    @usableFromInline
    var parsingOptions: ParsingOptions
    
    @inlinable
    public func parse(string: String) throws -> [[Substring]] {
        self.extractor = Extractor(string)
        let firstRow = parseLine()
        
        var content: [[Substring]]
        if firstRow.isEmpty {
            content = []
        } else {
            content = [firstRow]
        }

        var index = 1
        while extractor.popCurrent(with: parsingOptions.endOfLine) != nil {
            let line = parseLine()
            guard line.isEmpty == false else {
                break
            }
            guard line.count == firstRow.count else {
                throw ParserError.unevenSize(firstErrorRowIndex: index)
            }
            content.append(line)
            index += 1
        }
        
        // Check that size is correct everywhere
        let firstSize = content.first?.count ?? 0
        for (index, row) in content.enumerated() {
            if row.count == firstSize {
                continue
            } else {
                throw ParserError.unevenSize(firstErrorRowIndex: index)
            }
        }
        
        
        // Get to end of file
        // FIXME: Include this in the parsing options
        extractor.popCurrent(with: goToEnd)
        guard extractor.currentIndex == extractor.string.endIndex else {
            throw ParserError.syntaxError(index: extractor.currentIndex)
        }
        
        return content
    }
    
    @inlinable
    public func parseNamedCells(string: String) throws -> CSVNamedCellsView {
        return try CSVNamedCellsView(wrapped: self.parse(string: string))
    }
    
    @inlinable
    func parseLine() -> [Substring] {
        var all: [Substring]
        var acceptValues = true
        if let firstField = parseField() {
            all = [firstField]
        } else {
            acceptValues = false
            all = [""]
        }
        
        while extractor.popCurrent(with: parsingOptions.separator) != nil {
            acceptValues = true
            if let parsedField = parseField() {
                all.append(parsedField)
            } else {
                all.append("")
            }
        }
        return acceptValues ? all : []
    }
    
    @inlinable
    func parseField() -> Substring? {
        parseNonEscaped() ?? parseEscaped()
    }
    
    @inlinable
    func parseEscaped() -> Substring? {
        
        guard extractor.popCurrent(with: parsingOptions.quote) != nil else {
            return nil
        }
        
        guard let content = extractor.popCurrent(with: escapedContent) else {
            return nil
        }
        
        guard extractor.popCurrent(with: parsingOptions.quote) != nil else {
            return nil
        }
        
        return Substring(content.replacingOccurrences(of: "\"\"", with: "\""))
    }
    
    @inlinable
    func parseNonEscaped() -> Substring? {
        extractor.popCurrent(with: )
    }
        
    public enum ParserError: Error {
        case unevenSize(firstErrorRowIndex: Int)
        case missingColumns(columns: Set<String>)
        case additionalColumns(columns: Set<String>)
        case syntaxError(index: String.Index)
    }
    
    public struct ParsingOptions {
        @inlinable
        init(endOfLine: Matcher, unescapedContent: Matcher, separator: Matcher, quote: Matcher, quotedNewlines: Matcher) {
            self.endOfLine = endOfLine
            self.unescapedContent = unescapedContent
            self.separator = separator
            self.quote = quote
            self.quotedNewlines = quotedNewlines
        }
        
        /// Parse the file according to RFC 4180
        ///
        /// This will not accept any non-ASCII characters in the file
        public static let RFC4180 = ParsingOptions(
            endOfLine: "\r\n",
            unescapedContent: Matcher(" "..."!") || Matcher("#"..."+") || Matcher("-"..."~"),
            separator: ",",
            quote: "\"",
            quotedNewlines: "\n" || "\r"
        )
        
        /// Based on RFC 4180 except it also accepts non-ASCII characters
        public static let unicode = ParsingOptions(
            endOfLine: "\r\n",
            unescapedContent: (Matcher.any() && !("\"" || "," || "\n" || "\r" || "\r\n" )),
            separator: ",",
            quote: "\"",
            quotedNewlines: "\n" || "\r"
        )
        
        @usableFromInline
        var endOfLine: Matcher
        
        @usableFromInline
        var unescapedContent: Matcher
        
        @usableFromInline
        var separator: Matcher
        
        @usableFromInline
        var quote: Matcher
        
        @usableFromInline
        var quotedNewlines: Matcher
    }
    
}

public struct CSVNamedCellsView {
    
    @inlinable
    init(wrapped: [[Substring]]) {
        self.wrapped = wrapped
        self.orderer = [:]
        if let first = wrapped.first {
            for (index,column) in first.enumerated() {
                orderer[String(column)] = index
            }
        }
    }
    
    @usableFromInline
    let wrapped: [[Substring]]
    
    @usableFromInline
    var orderer: [String:Int]
    
    @inlinable
    public subscript(rowIndex: Int, column: String) -> Substring? {
        get {
            precondition(wrapped.isEmpty == false, "The CSV data has no rows")
            if let actualIndex = orderer[column] {
                return wrapped[rowIndex][actualIndex]
            } else {
                return nil
            }
        }
    }
    
    public var rowCount: Int {
        wrapped.count
    }
}
