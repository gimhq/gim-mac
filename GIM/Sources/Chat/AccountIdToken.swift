import Foundation

/// Finds a gim-core user id (an Account ID) in scanned or pasted text (contract C8).
enum AccountIdToken {
    /// `u`, then 55 base32 characters whose last one only carries the final 1 bit of a 32-byte key.
    static let pattern = "^u[a-z2-7]{54}[aiqy]$"

    /// The first run of ASCII letters and digits in `text` that is a valid Account ID; any other character separates
    /// runs, so ids inside URLs or punctuation are found.
    static func extract(from text: String) -> String? {
        text.split { !($0.isASCII && ($0.isLetter || $0.isNumber)) }
            .map(String.init)
            .first(where: isValid)
    }

    static func isValid(_ token: String) -> Bool {
        token.range(of: pattern, options: .regularExpression) != nil
    }
}
