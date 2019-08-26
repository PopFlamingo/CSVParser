import ParserBuilder

public class CSVParser {
    
    @inlinable
    public init(string: String) {
        self.extractor = Extractor(string)
    }
    
    @usableFromInline
    var extractor: Extractor
    
    @inlinable func parseColumns(options: ParsingOptions) throws -> [ReorderedCollection<[Substring]>] {
        guard let expectedRows = options.expectedRows else {
            fatalError("The parseColumn method requires expectedRows to be non-nil")
        }
        guard expectedRows.isEmpty == false else {
            fatalError("The parseColumn method requires expectedRows to be non-empty")
        }
        
        let rawParsed = try rawParse(options: options)
        
        let indexes = expectedRows.map { row in
            rawParsed.first!.firstIndex(where: { $0 == row })!
        }
        
        return rawParsed.map { ReorderedCollection($0, order: indexes) }
    }
    
    @inlinable
    public func rawParse(options: ParsingOptions) throws -> [[Substring]] {
        let firstRow = parseLine()
        
        var content: [[Substring]]
        if firstRow.isEmpty {
            content = []
        } else {
            content = [firstRow]
        }
        
        // If there are expected rows, validate them
        if let expectedRows = options.expectedRows {
            if options.allowsNonExhaustiveRows {
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
        while extractor.popCurrent(with: Token.clrf) != nil {
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
        
        return content
    }
    
    @inlinable
    func parseLine() -> [Substring] {
        var all: [Substring]
        if let firstField = parseField() {
            all = [firstField]
        } else {
            all = []
        }
        while extractor.popCurrent(with: Token.comma) != nil {
            if let parsedField = parseField() {
                all.append(parsedField)
            }
        }
        return all
    }
    
    @inlinable
    func parseField() -> Substring? {
        parseNonEscaped() ?? parseEscaped()
    }
    
    @inlinable
    func parseEscaped() -> Substring? {
        let escapedContent = (Token.textDataChar || Token.comma || Token.cr || Token.newLine || Token.doubleQuote).atLeast(0)
        if let escaped = extractor.popCurrent(with: Token.quote + escapedContent + Token.quote) {
            let second = escaped.index(after: escaped.startIndex)
            let beforeLast = escaped.index(before: escaped.endIndex)
            return Substring(escaped[second..<beforeLast].replacingOccurrences(of: "\"\"", with: "\""))
        } else {
            return nil
        }
    }
    
    @inlinable
    func parseNonEscaped() -> Substring? {
        extractor.popCurrent(with: Token.textDataChar.atLeast(1))
    }
    
    @usableFromInline
    struct Token {
        @usableFromInline
        static let comma = Matcher(",")
        
        @usableFromInline
        static let clrf = Matcher("\r\n")
        
        @usableFromInline
        static let cr = Matcher("\r")
        
        @usableFromInline
        static let newLine = Matcher("\n")
        
        @usableFromInline
        static let quote = Matcher("\"")
        
        @usableFromInline
        static let doubleQuote = Matcher("\"\"")
        
        @usableFromInline
        static let textDataChar = Matcher(" "..."!") || Matcher("#"..."+") || Matcher("-"..."~")
    }
        
    public enum ParserError: Error {
        case unevenSize(firstErrorRowIndex: Int)
        case missingColumns(columns: Set<String>)
        case additionalColumns(columns: Set<String>)
    }
    
    public struct ParsingOptions {
        /// This allows defining rows that are expected to be present
        public var expectedRows: [String]? = nil
        
        /// Defines wether or not it is accepted that the file contains more
        /// rows than what's present in the `rows` array
        public var allowsNonExhaustiveRows = true
    }
    
    public struct RowView {
        
        subscript(columnName: String) -> Substring {
            fatalError()
        }
    }
    
}
