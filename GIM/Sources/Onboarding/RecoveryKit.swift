// The recovery kit: the user ID and recovery code written together, so one copy or file restores the account.
// Formats from gim-core docs/identity.md ("Identifiers", "Recovery backup"); ported from the Android client.

import Foundation

/// The localized words of the kit text; the app passes them from its String Catalog.
struct RecoveryKitLabels: Sendable, Hashable {
    var title: String
    var accountId: String
    var recoveryKey: String
    var note: String
}

/// What `RecoveryKit.parse` found: the normalized valid user ID and the recovery code symbols (39, no
/// separators), or nil for each.
struct ParsedRecoveryKit: Sendable, Hashable {
    var userId: String?
    var recoveryCode: String?
}

enum RecoveryKit {
    /// 24 bytes in Crockford base32.
    static let recoveryCodeSymbols = 39
    static let groupSize = 4
    static let endingSymbols = 4
    static let crockfordAlphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"

    /// What the user pasted or typed, trimmed and lowercased (ids are canonical lowercase).
    static func normalizeUserId(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// `"u"` + base32 (RFC 4648, lowercase, unpadded) of 34 bytes: 55 symbols, the last carrying 3 zero bits.
    static func isValidUserId(_ value: String) -> Bool {
        value.wholeMatch(of: /u[a-z2-7]{54}[aiqy]/) != nil
    }

    /// The recovery code's symbols as gim-core parses them: `-` and whitespace dropped, uppercased, `I`/`L` -> `1`
    /// and `O` -> `0`. Other characters are kept so they can be flagged.
    static func normalizeRecoveryCode(_ value: String) -> String {
        let kept = value.filter { $0 != "-" && !$0.isWhitespace }.uppercased()
        return String(
            kept.map { character -> Character in
                switch character {
                case "I", "L": "1"
                case "O": "0"
                default: character
                }
            })
    }

    /// `symbols` (from `normalizeRecoveryCode`) is a whole code: 39 symbols, the last one's 3 padding bits zero.
    static func isValidRecoveryCode(_ symbols: String) -> Bool {
        guard symbols.count == recoveryCodeSymbols, symbols.allSatisfy({ crockfordAlphabet.contains($0) }),
            let last = symbols.last, let index = crockfordAlphabet.firstIndex(of: last)
        else { return false }
        return crockfordAlphabet.distance(from: crockfordAlphabet.startIndex, to: index) % 8 == 0
    }

    /// `symbols` cannot become a valid code by typing more: a foreign character, too long, or bad padding.
    static func isBrokenRecoveryCode(_ symbols: String) -> Bool {
        symbols.contains { !crockfordAlphabet.contains($0) } || symbols.count > recoveryCodeSymbols
            || (symbols.count == recoveryCodeSymbols && !isValidRecoveryCode(symbols))
    }

    /// Groups `symbols` in blocks of four separated by `-`, as gim-core displays the code.
    static func formatRecoveryCode(_ symbols: String) -> String {
        let characters = Array(symbols)
        return stride(from: 0, to: characters.count, by: groupSize)
            .map { String(characters[$0..<min($0 + groupSize, characters.count)]) }
            .joined(separator: "-")
    }

    /// The kit text: title, user ID line, recovery code line (grouped), a blank line and the note.
    static func format(userId: String, recoveryCode: String, labels: RecoveryKitLabels) -> String {
        [
            labels.title,
            "\(labels.accountId): \(normalizeUserId(userId))",
            "\(labels.recoveryKey): \(formatRecoveryCode(normalizeRecoveryCode(recoveryCode)))",
            "",
            labels.note,
        ].map { $0 + "\n" }.joined()
    }

    /// Finds the user ID and recovery code in `text` without relying on the labels, so a kit in any language or
    /// copied by hand still parses. Tokens are runs of letters and digits; the code may be one token or tokens
    /// joined by single `-` or spaces. The user ID token is never part of the code.
    static func parse(_ text: String) -> ParsedRecoveryKit {
        let tokens = text.matches(of: /[\p{L}\p{Nd}]+/)
        let isUserId = tokens.map { isValidUserId($0.output.lowercased()) }
        let userId = isUserId.firstIndex(of: true).map { tokens[$0].output.lowercased() }

        // Chains of tokens joined by a single '-' or space, split at the user ID.
        var chains: [[Substring]] = []
        for (i, token) in tokens.enumerated() {
            if isUserId[i] {
                chains.append([])
                continue
            }
            let separator = i == 0 ? nil : text[tokens[i - 1].range.upperBound..<token.range.lowerBound]
            if chains.isEmpty || isUserId[i - 1] || (separator != "-" && separator != " ") {
                chains.append([])
            }
            chains[chains.count - 1].append(token.output)
        }
        var recoveryCode: String?
        search: for chain in chains {
            for start in chain.indices {
                if let code = code(in: chain, from: start) {
                    recoveryCode = code
                    break search
                }
            }
        }
        return ParsedRecoveryKit(userId: userId, recoveryCode: recoveryCode)
    }

    /// The valid code made of `chain`'s tokens from `start` holding exactly `recoveryCodeSymbols` characters, if any.
    private static func code(in chain: [Substring], from start: Int) -> String? {
        var length = 0
        for end in start..<chain.count {
            length += chain[end].count
            if length > recoveryCodeSymbols { return nil }
            if length == recoveryCodeSymbols {
                let symbols = normalizeRecoveryCode(chain[start...end].joined())
                return isValidRecoveryCode(symbols) ? symbols : nil
            }
        }
        return nil
    }

    /// The last four symbols of the recovery code, which the user types back to show they saved the kit.
    static func recoveryKeyEnding(_ recoveryCode: String) -> String {
        String(normalizeRecoveryCode(recoveryCode).suffix(endingSymbols))
    }

    /// `typed` is the code's ending: four symbols, ignoring case, `-` and whitespace like `normalizeRecoveryCode`.
    static func matchesRecoveryKeyEnding(_ recoveryCode: String, typed: String) -> Bool {
        let symbols = normalizeRecoveryCode(typed)
        return symbols.count == endingSymbols && symbols == recoveryKeyEnding(recoveryCode)
    }
}
