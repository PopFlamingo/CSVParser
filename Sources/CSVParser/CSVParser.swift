import ParserBuilder

public class CSVParser {
    
    @inlinable
    public init(string: String) {
        self.extractor = Extractor(string)
    }
    
    @usableFromInline
    var extractor: Extractor
    
    @inlinable
    public func parse() -> [[Substring]] {
        var content = [parseLine()]
        while extractor.popCurrent(with: Token.clrf) != nil {
            content.append(parseLine())
        }
        return content
    }
    
    @inlinable
    func parseLine() -> [Substring] {
        var all = [parseField()]
        while extractor.popCurrent(with: Token.comma) != nil {
            all.append(parseField())
        }
        return all
    }
    
    @inlinable
    func parseField() -> Substring {
        parseNonEscaped() ?? parseEscaped() ?? ""
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
        static let textDataChar = Matcher(" "..."!") || Matcher("#"..."+") || Matcher("-"..."~") || Matcher("é") || Matcher("è") || Matcher("ô")
    }
    
}
