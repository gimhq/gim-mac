import Foundation

enum AppDirectories {
    /// `~/Library/Application Support/gim`, created on demand.
    static var dataDirectory: URL {
        get throws {
            let fileManager = FileManager.default
            let base = try fileManager.url(
                for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let url = base.appendingPathComponent("gim", isDirectory: true)
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
            return url
        }
    }
}
