import ParserBuilder

public class CSVParser {
    
    @inlinable
    public init(parsingOptions: ParsingOptions, validationOptions: ValidationOptions = .init()) {
        self.extractor = Extractor("")
        self.parsingOptions = parsingOptions
        self.validationOptions = validationOptions
    }
    
    @usableFromInline
    var extractor: Extractor
    
    @usableFromInline
    var parsingOptions: ParsingOptions
    
    @usableFromInline
    var validationOptions: ValidationOptions
    
    @inlinable public func parseColumns(string: String) throws -> [ReorderedCollection<[Substring]>] {
        self.extractor = Extractor(string)
        guard let expectedRows = validationOptions.expectedRows else {
            fatalError("The parseColumn method requires expectedRows to be non-nil")
        }
        guard expectedRows.isEmpty == false else {
            fatalError("The parseColumn method requires expectedRows to be non-empty")
        }
        
        let rawParsed = try rawParse(string: string)
        
        let indexes = expectedRows.map { row in
            rawParsed.first!.firstIndex(where: { $0 == row })!
        }
        
        return rawParsed.map { ReorderedCollection($0, order: indexes) }
    }
    
    @inlinable
    public func rawParse(string: String) throws -> [[Substring]] {
        self.extractor = Extractor(string)
        let firstRow = parseLine()
        
        var content: [[Substring]]
        if firstRow.isEmpty {
            content = []
        } else {
            content = [firstRow]
        }
        
        // If there are expected rows, validate them
        if let expectedRows = validationOptions.expectedRows {
            if validationOptions.allowsNonExhaustiveRows {
                guard expectedRows.count <= firstRow.count  else {
                    throw ParserError.missingColumns(columns: Set(expectedRows).subtracting(firstRow.map(String.init)))
                }
            } else {
                guard expectedRows.count == firstRow.count else {
                    if expectedRows.count > firstRow.count {
                        throw ParserError.missingColumns(columns: Set(expectedRows).subtracting(firstRow.map(String.init)))
                    } else {
                        throw ParserError.additionalColumns(columns: Set(firstRow.map(String.init)).subtracting(expectedRows))
                    }
                }
            }
            guard Set(firstRow.map(String.init)).isSuperset(of: expectedRows) else {
                throw ParserError.missingColumns(columns: Set(expectedRows).subtracting(firstRow.map(String.init)))
            }
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
        extractor.popCurrent(with: ("\r" || "\n" || "\r\n" || Matcher(" ")).atLeast(0))
        guard extractor.currentIndex == extractor.string.endIndex else {
            throw ParserError.syntaxError(index: extractor.currentIndex)
        }
        
        return content
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
        let escapedContent = (parsingOptions.unescapedContent || parsingOptions.separator || parsingOptions.quotedNewlines || parsingOptions.quote.count(2)).atLeast(0)
        
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
        extractor.popCurrent(with: parsingOptions.unescapedContent.atLeast(1))
    }
        
    public enum ParserError: Error {
        case unevenSize(firstErrorRowIndex: Int)
        case missingColumns(columns: Set<String>)
        case additionalColumns(columns: Set<String>)
        case syntaxError(index: String.Index)
    }
    
    public struct ParsingOptions {
        
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
            unescapedContent: (Matcher.anyCharacter && !"\"" && !"," && !"\n" && !"\r" && !"\r\n" ),
            separator: ",",
            quote: "\"",
            quotedNewlines: "\n" || "\r"
        )
        
       
        
        public static let special = ParsingOptions(
            endOfLine: "\r\n",
            unescapedContent:  Matcher(" "..."!") || Matcher("#"..."+") || Matcher("-"..."~") || Matcher("é") || Matcher("è") || Matcher("ô"),
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
    
    public struct ValidationOptions {
        
        public init() {
            self.expectedRows = nil
            self.allowsNonExhaustiveRows = true
        }
        
        /// This allows defining rows that are expected to be present
        public var expectedRows: [String]?
        
        /// Defines wether or not it is accepted that the file contains more
        /// rows than what's present in the `rows` array
        public var allowsNonExhaustiveRows: Bool
    }
    
    public struct RowView {
        
        subscript(columnName: String) -> Substring {
            fatalError()
        }
    }
    
}
