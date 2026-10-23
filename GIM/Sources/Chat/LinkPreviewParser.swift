import Foundation

/// Reads a preview out of a page's `<head>`: Open Graph and Twitter tags, then `<title>` and the meta description.
enum LinkPreviewParser {
    /// Callers read at most this many bytes of a page.
    static let maxHTMLBytes = 512 * 1024
    static let maxTitleLength = 200
    static let maxDescriptionLength = 400

    static func parse(html: String, baseURL: URL) -> LinkPreview {
        let head = headPart(of: html)
        let meta = metaValues(in: head)
        let title = clean(meta["og:title"] ?? meta["twitter:title"] ?? titleTag(in: head), limit: maxTitleLength)
        let description = clean(
            meta["og:description"] ?? meta["twitter:description"] ?? meta["description"], limit: maxDescriptionLength)
        let siteName = clean(meta["og:site_name"], limit: maxTitleLength)
        let imageURL = (meta["og:image"] ?? meta["twitter:image"]).flatMap { resolve($0, against: baseURL) }
        return LinkPreview(
            url: baseURL, title: title, description: description, imageURL: imageURL, siteName: siteName,
            fetchedAt: Date())
    }

    /// Everything before `</head>`, or the whole page when there is none.
    private static func headPart(of html: String) -> String {
        guard let end = html.range(of: "</head", options: .caseInsensitive) else { return html }
        return String(html[..<end.lowerBound])
    }

    /// `property`/`name` → `content` for every `<meta>` tag; the first tag for a key wins.
    private static func metaValues(in head: String) -> [String: String] {
        guard let tagPattern = try? NSRegularExpression(pattern: "<meta\\b[^>]*>", options: [.caseInsensitive]),
            let attributePattern = try? NSRegularExpression(
                pattern: "([a-zA-Z_:-]+)\\s*=\\s*(?:\"([^\"]*)\"|'([^']*)'|([^\\s\"'>]+))")
        else { return [:] }
        let nsHead = head as NSString
        var values: [String: String] = [:]
        for tag in tagPattern.matches(in: head, range: NSRange(location: 0, length: nsHead.length)) {
            let tagText = nsHead.substring(with: tag.range)
            let nsTag = tagText as NSString
            var attributes: [String: String] = [:]
            for attribute in attributePattern.matches(in: tagText, range: NSRange(location: 0, length: nsTag.length)) {
                let name = nsTag.substring(with: attribute.range(at: 1)).lowercased()
                let value = (2...4).lazy
                    .map { attribute.range(at: $0) }
                    .first { $0.location != NSNotFound }
                    .map { nsTag.substring(with: $0) } ?? ""
                if attributes[name] == nil {
                    attributes[name] = value
                }
            }
            guard let key = (attributes["property"] ?? attributes["name"])?.lowercased(),
                let content = attributes["content"], values[key] == nil
            else { continue }
            values[key] = content
        }
        return values
    }

    private static func titleTag(in head: String) -> String? {
        guard
            let pattern = try? NSRegularExpression(
                pattern: "<title\\b[^>]*>(.*?)</title\\s*>", options: [.caseInsensitive, .dotMatchesLineSeparators]),
            let match = pattern.firstMatch(in: head, range: NSRange(location: 0, length: (head as NSString).length))
        else { return nil }
        return (head as NSString).substring(with: match.range(at: 1))
    }

    /// Entities decoded, whitespace collapsed, capped at `limit` characters; nil when nothing is left.
    private static func clean(_ raw: String?, limit: Int) -> String? {
        guard let raw else { return nil }
        let collapsed = decodeEntities(raw).split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        return collapsed.isEmpty ? nil : String(collapsed.prefix(limit))
    }

    static func decodeEntities(_ text: String) -> String {
        guard text.contains("&"),
            let pattern = try? NSRegularExpression(
                pattern: "&(#[xX][0-9a-fA-F]+|#[0-9]+|amp|lt|gt|quot|apos);", options: [.caseInsensitive])
        else { return text }
        let nsText = text as NSString
        var result = ""
        var location = 0
        for match in pattern.matches(in: text, range: NSRange(location: 0, length: nsText.length)) {
            result += nsText.substring(with: NSRange(location: location, length: match.range.location - location))
            let entity = nsText.substring(with: match.range(at: 1))
            result += decodeEntity(entity) ?? nsText.substring(with: match.range)
            location = match.range.location + match.range.length
        }
        result += nsText.substring(from: location)
        return result
    }

    private static func decodeEntity(_ entity: String) -> String? {
        switch entity.lowercased() {
        case "amp": return "&"
        case "lt": return "<"
        case "gt": return ">"
        case "quot": return "\""
        case "apos": return "'"
        default:
            let digits = entity.dropFirst()
            let code =
                digits.first == "x" || digits.first == "X"
                ? UInt32(digits.dropFirst(), radix: 16) : UInt32(digits, radix: 10)
            return code.flatMap { Unicode.Scalar($0) }.map { String(Character($0)) }
        }
    }

    /// `value` resolved against `baseURL`; only http(s) results are kept.
    private static func resolve(_ value: String, against baseURL: URL) -> URL? {
        let trimmed = decodeEntities(value).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed, relativeTo: baseURL)?.absoluteURL,
            LinkDetector.isWeb(url)
        else { return nil }
        return url
    }
}
