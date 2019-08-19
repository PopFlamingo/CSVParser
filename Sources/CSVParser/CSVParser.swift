import ParserBuilder

class CSVParser {
    init(string: String) {
        self.extractor = Extractor(string)
    }
    private var extractor: Extractor
    
    func parse() -> [[Substring]] {
        var content = [parseLine()]
        while extractor.popCurrent(with: Token.clrf) != nil {
            content.append(parseLine())
        }
        return content
    }
    
    func parseLine() -> [Substring] {
        var all = [parseField()]
        while extractor.popCurrent(with: Token.comma) != nil {
            all.append(parseField())
        }
        return all
    }
    
    func parseField() -> Substring {
        parseNonEscaped() ?? parseEscaped() ?? ""
    }
    
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
    
    func parseNonEscaped() -> Substring? {
        extractor.popCurrent(with: Token.textDataChar.atLeast(1))
    }
    
    private struct Token {
        static let comma = Matcher(",")
        static let clrf = Matcher("\r\n")
        static let cr = Matcher("\r")
        static let newLine = Matcher("\n")
        static let quote = Matcher("\"")
        static let doubleQuote = Matcher("\"\"")
        static let textDataChar = Matcher(" "..."!") || Matcher("#"..."+") || Matcher("-"..."~") || Matcher("é") || Matcher("è") || Matcher("ô")
    }
    
}
