import Foundation
import XCTest
import DfnsSdk

/// Swift 6 compatibility checks for the SDK's public API, used the way an app uses it: a plain
/// `import` (no `@testable`) compiled in the Swift 6 language mode. Most checks are compile-time: if
/// a public type loses its `Sendable` conformance, or the signer can no longer be used across
/// actors, this target stops compiling and CI fails.
final class SendableConformanceTests: XCTestCase {
    private func assertSendable<T: Sendable>(_: T.Type) {}

    func testPublicTypesAreSendable() {
        assertSendable(DfnsApi.UserActionChallenge.self)
        assertSendable(DfnsApi.UserRegistrationChallenge.self)
        assertSendable(DfnsApi.RelyingParty.self)
        assertSendable(DfnsApi.SupportedCredentialKind.self)
        assertSendable(DfnsApi.AllowCredentials.self)
        assertSendable(DfnsApi.PublicKeyCredentialDescriptor.self)
        assertSendable(DfnsApi.Fido2Assertion.self)
        assertSendable(DfnsApi.UserActionAssertion.self)
        assertSendable(DfnsApi.ClientData.self)
        assertSendable(DfnsApi.Fido2AssertionData.self)
        assertSendable(DfnsApi.PublicKeyCredentialParameters.self)
        assertSendable(DfnsApi.SupportedCredentialKinds.self)
        assertSendable(DfnsApi.UserInformation.self)
        assertSendable(DfnsApi.AuthenticatorSelectionCriteria.self)
        assertSendable(DfnsApi.Fido2Attestation.self)
        assertSendable(DfnsApi.Fido2AttestationData.self)
        assertSendable(PasskeysSigner.self)
        assertSendable(PasskeysSignerError.self)
    }
}

/// Stand-in for an app's backend client, which fetches challenges off the main actor.
private actor ChallengeStore {
    private var challenge: DfnsApi.UserActionChallenge?

    func store(_ challenge: DfnsApi.UserActionChallenge) {
        self.challenge = challenge
    }

    func load() -> DfnsApi.UserActionChallenge? {
        challenge
    }

    /// Never called: only has to compile. Signing from a custom actor.
    func sign(with signer: PasskeysSigner) async throws -> DfnsApi.Fido2Assertion? {
        guard let challenge else { return nil }
        return try await signer.sign(challenge: challenge)
    }
}

/// Stand-in for an app's view model, which holds the signer on the main actor.
@MainActor
private final class WalletViewModel {
    let signer: PasskeysSigner
    var challenge: DfnsApi.UserActionChallenge?

    init(signer: PasskeysSigner) {
        self.signer = signer
    }

    /// Never called: only has to compile. Signing from the main actor.
    func sign() async throws -> DfnsApi.Fido2Assertion? {
        guard let challenge else { return nil }
        return try await signer.sign(challenge: challenge)
    }

    /// Never called: only has to compile. Registering from the main actor.
    func create(challenge: DfnsApi.UserRegistrationChallenge) async throws -> DfnsApi.Fido2Attestation {
        try await signer.create(challenge: challenge)
    }
}

/// Never called: only has to compile. Signing from a nonisolated context.
private func signFromNonisolatedContext(signer: PasskeysSigner, challenge: DfnsApi.UserActionChallenge) async throws -> DfnsApi.Fido2Assertion {
    try await signer.sign(challenge: challenge)
}

final class CrossActorUsageTests: XCTestCase {
    private let challengeJson = """
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

    func testChallengeCrossesActorBoundaries() async throws {
        let json = Data(challengeJson.utf8)
        let decoded = try await Task.detached {
            try JSONDecoder().decode(DfnsApi.UserActionChallenge.self, from: json)
        }.value

        let store = ChallengeStore()
        await store.store(decoded)
        let stored = await store.load()
        let loaded = try XCTUnwrap(stored)

        let signer = try PasskeysSigner(relyingParty: DfnsApi.RelyingParty(id: "acme.com", name: "Acme"))
        let viewModel = await WalletViewModel(signer: signer)
        await MainActor.run { viewModel.challenge = loaded }

        let identifier = await MainActor.run { viewModel.challenge?.challengeIdentifier }
        XCTAssertEqual(identifier, "chal-123")
    }

    func testSignerCanBeSharedAcrossActors() async throws {
        // Created off the main actor, then handed to a detached task and to the main actor.
        let signer = try PasskeysSigner(relyingParty: DfnsApi.RelyingParty(id: "acme.com", name: "Acme"))

        let fromDetachedTask = await Task.detached { signer }.value
        let viewModel = await WalletViewModel(signer: signer)
        let fromMainActor = await MainActor.run { viewModel.signer }

        XCTAssertTrue(fromDetachedTask === signer)
        XCTAssertTrue(fromMainActor === signer)
    }
}
