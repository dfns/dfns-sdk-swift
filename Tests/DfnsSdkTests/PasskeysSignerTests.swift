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

    func testAllowedCredentialIdsDecodesWebauthnCredentials() {
        let challenge = makeChallenge(
            webauthn: [
                DfnsApi.PublicKeyCredentialDescriptor(type: "public-key", id: "aGVsbG8"),
                DfnsApi.PublicKeyCredentialDescriptor(type: "public-key", id: "-_8"),
            ],
            key: [DfnsApi.PublicKeyCredentialDescriptor(type: "public-key", id: "a2V5")]
        )

        XCTAssertEqual(
            PasskeysSigner.allowedCredentialIds(challenge),
            [Data("hello".utf8), Data([0xFB, 0xFF])]
        )
    }

    func testAllowedCredentialIdsIsEmptyWhenChallengeAllowsNone() {
        let challenge = makeChallenge(webauthn: [], key: [])

        XCTAssertEqual(PasskeysSigner.allowedCredentialIds(challenge), [])
    }

    private func makeChallenge(
        webauthn: [DfnsApi.PublicKeyCredentialDescriptor],
        key: [DfnsApi.PublicKeyCredentialDescriptor]
    ) -> DfnsApi.UserActionChallenge {
        DfnsApi.UserActionChallenge(
            attestation: "none",
            userVerification: "required",
            externalAuthenticationUrl: "",
            challenge: "aGVsbG8",
            challengeIdentifier: "chal-123",
            supportedCredentialKinds: [],
            allowCredentials: DfnsApi.AllowCredentials(webauthn: webauthn, key: key)
        )
    }
}
