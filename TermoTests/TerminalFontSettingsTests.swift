import XCTest
@testable import Termo

final class TerminalFontSettingsTests: XCTestCase {
    func testCustomFontTogglePreservesBothSelections() {
        let settings = AppSettings.shared
        let keys = ["termFont", "customTermFont", "customTermFontEnabled"]
        let savedDefaults = keys.map { UserDefaults.standard.object(forKey: $0) }
        let original = (settings.termFont, settings.customTermFont, settings.customTermFontEnabled)
        defer {
            settings.termFont = original.0
            settings.customTermFont = original.1
            settings.customTermFontEnabled = original.2
            for (key, value) in zip(keys, savedDefaults) {
                if let value { UserDefaults.standard.set(value, forKey: key) }
                else { UserDefaults.standard.removeObject(forKey: key) }
            }
        }

        settings.termFont = "Menlo"
        settings.customTermFont = "Helvetica"
        settings.customTermFontEnabled = true
        XCTAssertEqual(settings.effectiveTermFont, "Helvetica")
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "customTermFontEnabled"))
        XCTAssertEqual(UserDefaults.standard.string(forKey: "customTermFont"), "Helvetica")
        settings.customTermFontEnabled = false
        XCTAssertEqual(settings.effectiveTermFont, "Menlo")
        XCTAssertEqual(settings.customTermFont, "Helvetica")
        settings.customTermFontEnabled = true
        XCTAssertEqual(settings.effectiveTermFont, "Helvetica")
        settings.customTermFont = ""
        XCTAssertEqual(settings.effectiveTermFont, "")
    }
}
