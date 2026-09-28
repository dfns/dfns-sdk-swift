import XCTest
@testable import DfnsSdk

/// Unit tests for the base64URL helpers in `Utils`. These are the pure, deterministic building
/// blocks the passkey signer relies on to move challenges and credentials in and out of the
/// DFNS API's base64url encoding, so they are worth pinning down precisely.
final class UtilsTests: XCTestCase {
    /// Escaping standard base64 must drop padding and swap the URL-unsafe `+` / `/` characters.
    func testBase64URLEscapeConvertsAndStripsPadding() {
        // `Data([0xFB, 0xF0])` encodes to "+/A=" in standard base64 — it deliberately exercises
        // both the `+` and `/` substitutions as well as padding removal.
        let standard = Data([0xFB, 0xF0]).base64EncodedString()
        XCTAssertEqual(standard, "+/A=")

        let escaped = Utils.base64URLEscape(standard)
        XCTAssertEqual(escaped, "-_A")
        XCTAssertFalse(escaped.contains("="))
        XCTAssertFalse(escaped.contains("+"))
        XCTAssertFalse(escaped.contains("/"))
    }

    /// Unescaping must restore the URL-unsafe characters and re-add the padding that base64url omits.
    func testBase64URLUnescapeRestoresStandardBase64() {
        XCTAssertEqual(Utils.base64URLUnescaped("-_A"), "+/A=")
        // "aGVsbG8" is the unpadded base64url of "hello"; unescaping must re-add one `=`.
        XCTAssertEqual(Utils.base64URLUnescaped("aGVsbG8"), "aGVsbG8=")
    }

    /// Padding is added only when the length is not already a multiple of four.
    func testBase64URLUnescapeLeavesAlignedInputUnpadded() {
        // "YWJj" is the base64 of "abc" and is already 4-aligned — no padding should be appended.
        XCTAssertEqual(Utils.base64URLUnescaped("YWJj"), "YWJj")
    }

    /// Round-tripping arbitrary bytes through escape → unescape must recover the canonical,
    /// padded standard base64, which in turn must decode back to the original bytes.
    func testEscapeUnescapeRoundTripsArbitraryBytes() {
        for length in 1...64 {
            let bytes = (0..<length).map { UInt8(($0 * 37 + 11) & 0xFF) }
            let data = Data(bytes)
            let standard = data.base64EncodedString()

            let escaped = Utils.base64URLEscape(standard)
            XCTAssertFalse(escaped.contains("="), "escaped form must be unpadded")

            let restored = Utils.base64URLUnescaped(escaped)
            XCTAssertEqual(restored, standard, "round trip must recover canonical base64")
            XCTAssertEqual(Data(base64Encoded: restored), data, "restored base64 must decode to the original bytes")
        }
    }
}
