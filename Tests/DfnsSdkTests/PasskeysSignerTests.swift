import XCTest
@testable import DfnsSdk

/// Tests for `PasskeysSigner`. Register and sign drive the platform passkey UI and can't run
/// headless, so these tests cover the initializer and the pure parsing helpers.
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

    func testAllowedCredentialIdsDecodesWebauthnCredentials() throws {
        let challenge = makeChallenge(
            webauthn: [
                DfnsApi.PublicKeyCredentialDescriptor(type: "public-key", id: "aGVsbG8"),
                DfnsApi.PublicKeyCredentialDescriptor(type: "public-key", id: "-_8"),
            ],
            key: [DfnsApi.PublicKeyCredentialDescriptor(type: "public-key", id: "a2V5")]
        )

        XCTAssertEqual(
            try PasskeysSigner.allowedCredentialIds(challenge),
            [Data("hello".utf8), Data([0xFB, 0xFF])]
        )
    }

    func testAllowedCredentialIdsIsEmptyWhenChallengeAllowsNone() throws {
        let challenge = makeChallenge(webauthn: [], key: [])

        XCTAssertEqual(try PasskeysSigner.allowedCredentialIds(challenge), [])
    }

    func testEmptyUserIDProducesNilUserHandle() {
        let authResult: NSDictionary = ["userID": ""]

        XCTAssertNil(PasskeysSigner.userHandle(from: authResult))
    }

    func testPresentUserIDIsBase64UrlEncoded() {
        let authResult: NSDictionary = ["userID": "abc"]

        XCTAssertEqual(PasskeysSigner.userHandle(from: authResult), "YWJj")
    }

    func testAllowedCredentialIdsThrowsWhenNoneDecode() {
        let challenge = makeChallenge(
            webauthn: [DfnsApi.PublicKeyCredentialDescriptor(type: "public-key", id: "****")],
            key: [DfnsApi.PublicKeyCredentialDescriptor(type: "public-key", id: "a2V5")]
        )

        XCTAssertThrowsError(try PasskeysSigner.allowedCredentialIds(challenge)) { error in
            guard case PasskeysSignerError.unexpected = error else {
                XCTFail("expected PasskeysSignerError.unexpected")
                return
            }
        }
    }

    func testAllowedCredentialIdsKeepsIdsThatDecode() throws {
        let challenge = makeChallenge(
            webauthn: [
                DfnsApi.PublicKeyCredentialDescriptor(type: "public-key", id: "aGVsbG8"),
                DfnsApi.PublicKeyCredentialDescriptor(type: "public-key", id: "****"),
            ],
            key: []
        )

        XCTAssertEqual(try PasskeysSigner.allowedCredentialIds(challenge), [Data("hello".utf8)])
    }

    func testMissingUserIDProducesNilUserHandle() {
        let authResult: NSDictionary = [
            "credentialID": "Y3JlZA",
            "response": [
                "rawClientDataJSON": "e30",
                "signature": "c2ln",
                "rawAuthenticatorData": "YXV0aA",
            ] as NSDictionary,
        ]

        XCTAssertNil(PasskeysSigner.userHandle(from: authResult))
    }

    func testWrongTypeAtRawClientDataJSONThrows() throws {
        let signer = try PasskeysSigner(relyingParty: DfnsApi.RelyingParty(id: "acme.com", name: "Acme"))
        let authResult: NSDictionary = [
            "response": ["rawClientDataJSON": 1] as NSDictionary,
        ]

        XCTAssertThrowsError(
            try signer.extractFromAuthResultValue(authResult, path: ["response", "rawClientDataJSON"])
        ) { error in
            guard case PasskeysSignerError.unexpected = error else {
                XCTFail("expected PasskeysSignerError.unexpected")
                return
            }
        }
    }

    func testAllowedCredentialIdsReturnsOneIDForOneWebauthnDescriptor() throws {
        let challenge = makeChallenge(
            webauthn: [DfnsApi.PublicKeyCredentialDescriptor(type: "public-key", id: "aGVsbG8")],
            key: []
        )

        XCTAssertEqual(try PasskeysSigner.allowedCredentialIds(challenge), [Data("hello".utf8)])
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
