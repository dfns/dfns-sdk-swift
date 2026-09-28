import XCTest
@testable import DfnsSdk

/// Unit tests for the `DfnsApi` Codable models. The frontend SDK's job is to faithfully round-trip
/// the challenge/attestation/assertion payloads exchanged with the DFNS API, so these tests lock in
/// that the JSON keys and nesting match the wire shapes and survive a decode → encode → decode trip.
final class DfnsApiTests: XCTestCase {
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    /// A representative User Action Challenge decodes into the expected nested structure.
    func testDecodeUserActionChallenge() throws {
        let json = """
        {
          "attestation": "none",
          "userVerification": "required",
          "externalAuthenticationUrl": "https://example.com/auth",
          "challenge": "aGVsbG8",
          "challengeIdentifier": "chal-123",
          "supportedCredentialKinds": [
            { "kind": "Fido2", "factor": "first", "requiresSecondFactor": false }
          ],
          "allowCredentials": {
            "webauthn": [ { "type": "public-key", "id": "cred-1" } ],
            "key": []
          }
        }
        """
        let challenge = try decoder.decode(DfnsApi.UserActionChallenge.self, from: Data(json.utf8))

        XCTAssertEqual(challenge.userVerification, "required")
        XCTAssertEqual(challenge.challenge, "aGVsbG8")
        XCTAssertEqual(challenge.challengeIdentifier, "chal-123")
        XCTAssertEqual(challenge.supportedCredentialKinds.count, 1)
        XCTAssertEqual(challenge.supportedCredentialKinds.first?.kind, "Fido2")
        XCTAssertFalse(challenge.supportedCredentialKinds.first?.requiresSecondFactor ?? true)
        XCTAssertEqual(challenge.allowCredentials.webauthn.first?.id, "cred-1")
        XCTAssertEqual(challenge.allowCredentials.webauthn.first?.type, "public-key")
        XCTAssertTrue(challenge.allowCredentials.key.isEmpty)
    }

    /// A Fido2 assertion (what the signer returns to the backend) survives an encode → decode trip
    /// unchanged, including the optional `userHandle`.
    func testFido2AssertionRoundTrip() throws {
        let assertion = DfnsApi.Fido2Assertion(
            kind: "Fido2",
            credentialAssertion: DfnsApi.Fido2AssertionData(
                clientData: "client-data",
                credId: "cred-id",
                signature: "sig",
                authenticatorData: "auth-data",
                userHandle: "user-handle"
            )
        )

        let data = try encoder.encode(assertion)
        let decoded = try decoder.decode(DfnsApi.Fido2Assertion.self, from: data)

        XCTAssertEqual(decoded.kind, "Fido2")
        XCTAssertEqual(decoded.credentialAssertion.clientData, "client-data")
        XCTAssertEqual(decoded.credentialAssertion.credId, "cred-id")
        XCTAssertEqual(decoded.credentialAssertion.signature, "sig")
        XCTAssertEqual(decoded.credentialAssertion.authenticatorData, "auth-data")
        XCTAssertEqual(decoded.credentialAssertion.userHandle, "user-handle")
    }

    /// The optional `userHandle` must be omittable and decode back to nil.
    func testFido2AssertionOmitsNilUserHandle() throws {
        let assertion = DfnsApi.Fido2Assertion(
            kind: "Fido2",
            credentialAssertion: DfnsApi.Fido2AssertionData(
                clientData: "client-data",
                credId: "cred-id",
                signature: "sig",
                authenticatorData: "auth-data"
            )
        )

        let data = try encoder.encode(assertion)
        let decoded = try decoder.decode(DfnsApi.Fido2Assertion.self, from: data)
        XCTAssertNil(decoded.credentialAssertion.userHandle)
    }

    /// A Fido2 attestation (what the signer returns after registration) round-trips through JSON.
    func testFido2AttestationRoundTrip() throws {
        let attestation = DfnsApi.Fido2Attestation(
            credentialInfo: DfnsApi.Fido2AttestationData(
                attestationData: "att-data",
                clientData: "client-data",
                credId: "cred-id"
            ),
            credentialKind: "Fido2"
        )

        let data = try encoder.encode(attestation)
        let decoded = try decoder.decode(DfnsApi.Fido2Attestation.self, from: data)

        XCTAssertEqual(decoded.credentialKind, "Fido2")
        XCTAssertEqual(decoded.credentialInfo.attestationData, "att-data")
        XCTAssertEqual(decoded.credentialInfo.clientData, "client-data")
        XCTAssertEqual(decoded.credentialInfo.credId, "cred-id")
    }
}
