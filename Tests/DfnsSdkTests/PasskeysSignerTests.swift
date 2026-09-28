import XCTest
@testable import DfnsSdk

/// Tests for `PasskeysSigner` construction. The register/sign operations themselves drive the
/// platform passkey UI and can't run headless, but the initializer's validation (which mirrors the
/// other DFNS frontend SDKs) is pure and worth pinning down.
final class PasskeysSignerTests: XCTestCase {
    func testInitSucceedsWithValidRelyingParty() throws {
        XCTAssertNoThrow(
            try PasskeysSigner(relyingParty: DfnsApi.RelyingParty(id: "acme.com", name: "Acme"))
        )
    }

    func testInitThrowsWhenRelyingPartyIdIsEmpty() {
        XCTAssertThrowsError(
            try PasskeysSigner(relyingParty: DfnsApi.RelyingParty(id: "", name: "Acme"))
        )
    }

    func testInitThrowsWhenRelyingPartyNameIsEmpty() {
        XCTAssertThrowsError(
            try PasskeysSigner(relyingParty: DfnsApi.RelyingParty(id: "acme.com", name: ""))
        )
    }

    func testDefaultWaitTimeoutMatchesOtherSdks() {
        XCTAssertEqual(PasskeysSigner.defaultWaitTimeout, 60000)
    }
}
