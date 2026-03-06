import AppKit

struct SyntaxHighlighter {
    let keyword: NSColor
    let string: NSColor
    let comment: NSColor
    let number: NSColor
    let baseColor: NSColor
    let font: NSFont

    func highlight(_ code: String, language: String?) -> NSAttributedString {
        let base: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: baseColor,
        ]
        let result = NSMutableAttributedString(string: code, attributes: base)

        guard let lang = normalizeLanguage(language) else { return result }

        var painted = IndexSet()

        for pattern in commentPatterns(for: lang) {
            applyPattern(pattern, color: comment, to: result, code: code, painted: &painted)
        }

        for pattern in stringPatterns(for: lang) {
            applyPattern(pattern, color: string, to: result, code: code, painted: &painted)
        }

        if let kw = keywords(for: lang) {
            let escaped = kw.map { NSRegularExpression.escapedPattern(for: $0) }
            let pattern = "\\b(" + escaped.joined(separator: "|") + ")\\b"
            let options: NSRegularExpression.Options = (lang == "sql") ? .caseInsensitive : []
            applyPattern(pattern, color: keyword, to: result, code: code, painted: &painted, options: options)
        }

        applyPattern("\\b\\d+(\\.\\d+)?\\b", color: number, to: result, code: code, painted: &painted)

        return result
    }

    // MARK: - Pattern application

    private func applyPattern(
        _ pattern: String,
        color: NSColor,
        to result: NSMutableAttributedString,
        code: String,
        painted: inout IndexSet,
        options: NSRegularExpression.Options = [.anchorsMatchLines]
    ) {
        var opts = options
        opts.insert(.anchorsMatchLines)
        guard let regex = try? NSRegularExpression(pattern: pattern, options: opts) else { return }
        let nsRange = NSRange(code.startIndex..., in: code)

        for match in regex.matches(in: code, range: nsRange) {
            let range = match.range
            let matchSet = IndexSet(integersIn: range.location..<(range.location + range.length))
            if !painted.intersection(matchSet).isEmpty { continue }
            result.addAttribute(.foregroundColor, value: color, range: range)
            painted.formUnion(matchSet)
        }
    }

    // MARK: - Language normalization

    private func normalizeLanguage(_ lang: String?) -> String? {
        guard let l = lang?.lowercased().trimmingCharacters(in: .whitespaces), !l.isEmpty else { return nil }
        let aliases: [String: String] = [
            "js": "javascript", "jsx": "javascript",
            "ts": "typescript", "tsx": "typescript",
            "py": "python", "rb": "ruby", "rs": "rust",
            "cs": "csharp", "c#": "csharp",
            "sh": "bash", "shell": "bash", "zsh": "bash",
            "yml": "yaml", "c++": "cpp",
            "objc": "objectivec", "objective-c": "objectivec",
        ]
        return aliases[l] ?? l
    }

    // MARK: - Comment patterns

    private func commentPatterns(for lang: String) -> [String] {
        switch lang {
        case "python", "ruby", "bash", "yaml", "r":
            return ["#[^\n]*"]
        case "html", "xml":
            return ["<!--[\\s\\S]*?-->"]
        case "css":
            return ["/\\*[\\s\\S]*?\\*/"]
        case "sql":
            return ["--[^\n]*", "/\\*[\\s\\S]*?\\*/"]
        default:
            return ["//[^\n]*", "/\\*[\\s\\S]*?\\*/"]
        }
    }

    // MARK: - String patterns

    private func stringPatterns(for lang: String) -> [String] {
        switch lang {
        case "python":
            return [
                "\"\"\"[\\s\\S]*?\"\"\"", "'''[\\s\\S]*?'''",
                "\"(?:[^\"\\\\]|\\\\.)*\"", "'(?:[^'\\\\]|\\\\.)*'",
            ]
        default:
            return [
                "\"(?:[^\"\\\\]|\\\\.)*\"",
                "'(?:[^'\\\\]|\\\\.)*'",
                "`(?:[^`\\\\]|\\\\.)*`",
            ]
        }
    }

    // MARK: - Keywords

    private func keywords(for lang: String) -> [String]? {
        switch lang {
        case "swift":
            return [
                "import", "class", "struct", "enum", "protocol", "extension",
                "func", "var", "let", "typealias", "associatedtype",
                "if", "else", "guard", "switch", "case", "default", "for", "while", "repeat",
                "return", "throw", "throws", "try", "catch", "defer", "do",
                "private", "public", "internal", "fileprivate", "open", "static", "final",
                "self", "Self", "super", "nil", "true", "false",
                "init", "deinit", "override", "mutating", "async", "await",
                "some", "any", "where", "in", "is", "as",
            ]
        case "python":
            return [
                "import", "from", "class", "def", "if", "elif", "else",
                "for", "while", "return", "yield", "try", "except", "finally", "raise",
                "with", "as", "pass", "break", "continue",
                "and", "or", "not", "in", "is", "lambda",
                "True", "False", "None", "self", "async", "await",
            ]
        case "javascript", "typescript":
            return [
                "import", "export", "from", "default", "class", "extends", "function",
                "const", "let", "var", "if", "else", "for", "while", "do",
                "return", "throw", "try", "catch", "finally", "new", "delete", "typeof",
                "switch", "case", "break", "continue", "this", "super",
                "true", "false", "null", "undefined", "async", "await",
                "interface", "type", "enum", "as", "is",
            ]
        case "go":
            return [
                "package", "import", "func", "var", "const", "type",
                "struct", "interface", "if", "else", "for", "range",
                "switch", "case", "default", "return", "break", "continue",
                "defer", "go", "chan", "map", "select",
                "true", "false", "nil",
            ]
        case "rust":
            return [
                "use", "mod", "pub", "fn", "let", "mut", "const", "static",
                "struct", "enum", "trait", "impl", "type", "where",
                "if", "else", "match", "for", "while", "loop",
                "return", "break", "continue", "move", "ref",
                "self", "Self", "super", "crate", "as", "in", "unsafe",
                "async", "await", "dyn", "true", "false",
            ]
        case "java", "kotlin":
            return [
                "import", "package", "class", "interface", "extends", "implements",
                "public", "private", "protected", "static", "final", "abstract",
                "if", "else", "for", "while", "do", "switch", "case", "default",
                "return", "throw", "try", "catch", "finally", "new",
                "void", "this", "super", "true", "false", "null",
                "fun", "val", "var", "when", "object", "override",
            ]
        case "c", "cpp":
            return [
                "if", "else", "for", "while", "do", "switch", "case", "default",
                "return", "break", "continue", "goto",
                "int", "float", "double", "char", "void", "long", "short", "unsigned",
                "struct", "union", "enum", "typedef", "sizeof",
                "static", "extern", "const",
                "class", "public", "private", "protected", "virtual", "override",
                "template", "typename", "namespace", "using", "new", "delete",
                "this", "throw", "try", "catch", "nullptr", "auto", "constexpr",
                "true", "false", "NULL", "include", "define",
            ]
        case "ruby":
            return [
                "require", "include", "class", "module", "def", "end",
                "if", "elsif", "else", "unless", "while", "until", "for", "do",
                "return", "yield", "begin", "rescue", "ensure", "raise",
                "true", "false", "nil", "self", "super",
                "and", "or", "not", "in", "then", "case", "when",
            ]
        case "bash":
            return [
                "if", "then", "elif", "else", "fi", "for", "while", "do", "done",
                "case", "esac", "in", "function", "return", "exit",
                "echo", "read", "export", "source", "local",
                "true", "false",
            ]
        case "sql":
            return [
                "select", "from", "where", "insert", "into", "values",
                "update", "set", "delete", "create", "drop", "alter",
                "table", "index", "view", "join", "left", "right", "inner", "outer", "on",
                "and", "or", "not", "in", "is", "null", "as",
                "order", "by", "group", "having", "limit", "offset",
                "union", "distinct", "exists", "between", "like",
                "count", "sum", "avg", "min", "max",
                "primary", "key", "foreign", "references",
                "begin", "commit", "rollback",
            ]
        default:
            return [
                "if", "else", "for", "while", "return", "function", "class",
                "import", "from", "var", "let", "const", "true", "false", "null", "nil",
            ]
        }
    }
}
