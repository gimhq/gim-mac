import Foundation
import XCTest

/// Every String Catalog table is complete in every app language.
///
/// The test parses the `.xcstrings` sources next to this file (the test host only carries compiled tables), then checks
/// that the compiled tables load from each language's `.lproj` in the app bundle.
final class LanguageTablesTests: XCTestCase {
    static let tables = ["App", "Chat", "Explainer", "Onboarding", "Settings"]
    static let languages = ["en", "zh-Hans", "zh-Hant", "es"]
    static let resourcesURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Resources")

    private struct Catalog: Decodable {
        let sourceLanguage: String
        let strings: [String: Entry]
    }

    private struct Entry: Decodable {
        let localizations: [String: Localization]?
    }

    private struct Localization: Decodable {
        let stringUnit: StringUnit?
        let variations: Variations?
    }

    private struct Variations: Decodable {
        let plural: [String: Variant]?
    }

    private struct Variant: Decodable {
        let stringUnit: StringUnit?
    }

    private struct StringUnit: Decodable {
        let state: String
        let value: String
    }

    func testTableFilesMatchExpectedList() throws {
        let path = Self.resourcesURL.path
        let files: [String]
        do {
            files = try FileManager.default.contentsOfDirectory(atPath: path)
        } catch {
            XCTFail("Cannot read String Catalogs in \(path): \(error)")
            throw error
        }
        let found = Set(files.filter { $0.hasSuffix(".xcstrings") }.map { String($0.dropLast(".xcstrings".count)) })
        for table in Self.tables where !found.contains(table) {
            XCTFail("Missing \(table).xcstrings in \(path)")
        }
        for table in found.subtracting(Self.tables).sorted() {
            XCTFail("Unexpected \(table).xcstrings in \(path); add it to LanguageTablesTests.tables")
        }
    }

    func testEveryKeyIsTranslatedInEveryLanguage() throws {
        for (table, catalog) in try loadCatalogs().sorted(by: { $0.key < $1.key }) {
            XCTAssertEqual(catalog.sourceLanguage, "en", "\(table): sourceLanguage")
            // language -> problem -> keys, so one missing language is one failure per table.
            var problems: [String: [String: [String]]] = [:]
            for (key, entry) in catalog.strings.sorted(by: { $0.key < $1.key }) {
                let localizations = entry.localizations ?? [:]
                guard let english = localizations["en"] else {
                    problems["en", default: [:]]["missing", default: []].append(key)
                    continue
                }
                for language in Self.languages {
                    if let problem = Self.problem(localizations[language], english: english) {
                        problems[language, default: [:]][problem, default: []].append(key)
                    }
                }
            }
            for (language, byProblem) in problems.sorted(by: { $0.key < $1.key }) {
                let lines = byProblem.sorted(by: { $0.key < $1.key }).map { problem, keys in
                    "\(problem) (\(keys.count)): \(keys.joined(separator: ", "))"
                }
                XCTFail("\(table) [\(language)]:\n" + lines.joined(separator: "\n"))
            }
        }
    }

    func testCompiledTablesLoadInEveryLanguage() throws {
        let catalogs = try loadCatalogs()
        for language in Self.languages where language != "en" {
            guard let path = Bundle.main.path(forResource: language, ofType: "lproj"), let bundle = Bundle(path: path)
            else {
                XCTFail("\(language).lproj is not in the app bundle")
                continue
            }
            for (table, catalog) in catalogs.sorted(by: { $0.key < $1.key }) {
                // Plural keys compile into a stringsdict, so probe the first key with a plain English value.
                guard
                    let key = catalog.strings.keys.sorted().first(where: {
                        catalog.strings[$0]?.localizations?["en"]?.stringUnit != nil
                    })
                else {
                    XCTFail("\(table) has no plain key to probe")
                    continue
                }
                let expected = catalog.strings[key]?.localizations?[language]?.stringUnit?.value
                let actual = bundle.localizedString(forKey: key, value: nil, table: table)
                XCTAssertEqual(actual, expected, "\(table) [\(language)]: \(key) does not load from \(language).lproj")
            }
        }
    }

    /// The expected tables that exist on disk, decoded; missing files are reported by `testTableFilesMatchExpectedList`.
    private func loadCatalogs() throws -> [String: Catalog] {
        var catalogs: [String: Catalog] = [:]
        for table in Self.tables {
            let url = Self.resourcesURL.appendingPathComponent("\(table).xcstrings")
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            do {
                catalogs[table] = try JSONDecoder().decode(Catalog.self, from: Data(contentsOf: url))
            } catch {
                XCTFail("Cannot decode \(url.path): \(error)")
                throw error
            }
        }
        XCTAssertFalse(catalogs.isEmpty, "No String Catalogs found in \(Self.resourcesURL.path)")
        return catalogs
    }

    /// Why `localization` is incomplete against `english`, or `nil` when it is complete.
    private static func problem(_ localization: Localization?, english: Localization) -> String? {
        guard let localization else { return "missing" }
        guard let englishPlural = english.variations?.plural else {
            return problem(localization.stringUnit, reference: placeholders(english.stringUnit?.value ?? ""))
        }
        // Languages keep their own CLDR categories; only "other" is required everywhere.
        guard let plural = localization.variations?.plural else { return "missing plural" }
        guard plural["other"] != nil else { return "missing plural \"other\"" }
        let reference = placeholders(englishPlural["other"]?.stringUnit?.value ?? "")
        for (category, variant) in plural.sorted(by: { $0.key < $1.key }) {
            if let problem = problem(variant.stringUnit, reference: reference) {
                return "plural \(category): \(problem)"
            }
        }
        return nil
    }

    private static func problem(_ unit: StringUnit?, reference: [String]) -> String? {
        guard let unit else { return "no stringUnit" }
        if unit.state != "translated" { return "state \(unit.state)" }
        if unit.value.isEmpty { return "empty value" }
        let found = placeholders(unit.value)
        if found != reference {
            return "placeholders [\(found.joined(separator: " "))] != English [\(reference.joined(separator: " "))]"
        }
        return nil
    }

    /// Format specifiers as sorted "%index$type"; non-positional ones are numbered 1, 2, 3… in order, "%%" is skipped.
    static func placeholders(_ value: String) -> [String] {
        var next = 0
        var result: [String] = []
        for match in value.matches(of: #/%%|%(?:(\d+)\$)?(lld|ld|d|@|f|s)/#) {
            guard let type = match.output.2 else { continue }
            let index: Int
            if let position = match.output.1, let number = Int(position) {
                index = number
            } else {
                next += 1
                index = next
            }
            result.append("%\(index)$\(type)")
        }
        return result.sorted()
    }
}
