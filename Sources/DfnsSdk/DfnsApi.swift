/**
 Types defined in the Dfns API that might be arguments or return values of the demo server
*/
public enum DfnsApi {} // just a namespace

// MARK: - UserActionChallenge
extension DfnsApi {
	public struct UserActionChallenge: Sendable, Codable {
		public let attestation: String
		public let userVerification: String
		public let externalAuthenticationUrl: String
		public let challenge: String
		public let challengeIdentifier: String
		public let supportedCredentialKinds: [SupportedCredentialKind]
		public let allowCredentials: AllowCredentials

        public init(
            attestation: String,
            userVerification: String,
            externalAuthenticationUrl: String,
            challenge: String,
            challengeIdentifier: String,
            supportedCredentialKinds: [SupportedCredentialKind],
            allowCredentials: AllowCredentials
        ) {
            self.attestation = attestation
            self.userVerification = userVerification
            self.externalAuthenticationUrl = externalAuthenticationUrl
            self.challenge = challenge
            self.challengeIdentifier = challengeIdentifier
            self.supportedCredentialKinds = supportedCredentialKinds
            self.allowCredentials = allowCredentials
        }
	}
}

// MARK: - UserRegistrationChallenge
extension DfnsApi {
	public struct UserRegistrationChallenge: Sendable, Codable {
		public let temporaryAuthenticationToken: String
		public let user: UserInformation
		public let supportedCredentialKinds: SupportedCredentialKinds
		public let otpUrl: String
		public let challenge: String
		public let authenticatorSelection: AuthenticatorSelectionCriteria
		public let attestation: String
		public let pubKeyCredParams: [PublicKeyCredentialParameters]
		public let excludeCredentials: [PublicKeyCredentialDescriptor]

        public init(
            temporaryAuthenticationToken: String,
            user: UserInformation,
            supportedCredentialKinds: SupportedCredentialKinds,
            otpUrl: String,
            challenge: String,
            authenticatorSelection: AuthenticatorSelectionCriteria,
            attestation: String,
            pubKeyCredParams: [PublicKeyCredentialParameters],
            excludeCredentials: [PublicKeyCredentialDescriptor]
        ) {
            self.temporaryAuthenticationToken = temporaryAuthenticationToken
            self.user = user
            self.supportedCredentialKinds = supportedCredentialKinds
            self.otpUrl = otpUrl
            self.challenge = challenge
            self.authenticatorSelection = authenticatorSelection
            self.attestation = attestation
            self.pubKeyCredParams = pubKeyCredParams
            self.excludeCredentials = excludeCredentials
        }
	}
}

// MARK: - RelyingParty
extension DfnsApi {
	public struct RelyingParty: Sendable, Codable {
		public let id: String
		public let name: String

        public init(
            id: String,
            name: String
        ) {
            self.id = id
            self.name = name
        }
	}
}


// MARK: - SupportedCredentialKind
extension DfnsApi {
	public struct SupportedCredentialKind: Sendable, Codable {
		public let kind: String
		public let factor: String
		public let requiresSecondFactor: Bool

        public init(
            kind: String,
            factor: String,
            requiresSecondFactor: Bool
        ) {
            self.kind = kind
            self.factor = factor
            self.requiresSecondFactor = requiresSecondFactor
        }
	}
}

// MARK: - AllowCredentials
extension DfnsApi {
	public struct AllowCredentials: Sendable, Codable {
		public let webauthn: [PublicKeyCredentialDescriptor]
		public let key: [PublicKeyCredentialDescriptor]

        public init(
            webauthn: [PublicKeyCredentialDescriptor],
            key: [PublicKeyCredentialDescriptor]
        ) {
            self.webauthn = webauthn
            self.key = key
        }
	}
}

// MARK: - PublicKeyCredentialDescriptor
extension DfnsApi {
	public struct PublicKeyCredentialDescriptor: Sendable, Codable {
		public let type: String
		public let id: String

        public init(
            type: String,
            id: String
        ) {
            self.type = type
            self.id = id
        }
	}
}

// MARK: - Fido2Assertion
extension DfnsApi {
	public struct Fido2Assertion: Sendable, Codable {
		public let kind: String
		public let credentialAssertion: Fido2AssertionData

        public init(
            kind: String,
            credentialAssertion: Fido2AssertionData
        ) {
            self.kind = kind
            self.credentialAssertion = credentialAssertion
        }
	}
}

// MARK: - UserActionAssertion
extension DfnsApi {
	public struct UserActionAssertion: Sendable, Codable {
		public let challengeIdentifier: String
		public let firstFactor: Fido2Assertion

        public init(
            challengeIdentifier: String,
            firstFactor: Fido2Assertion
        ) {
            self.challengeIdentifier = challengeIdentifier
            self.firstFactor = firstFactor
        }
	}
}

// MARK: - ClientData
extension DfnsApi {
    public struct ClientData: Sendable, Codable {
        public let type: String
        public let challenge: String
        public let origin: String

        public init(
            type: String,
            challenge: String,
            origin: String
        ) {
            self.type = type
            self.challenge = challenge
            self.origin = origin
        }
    }
}

// MARK: - Fido2AssertionData
extension DfnsApi {
	public struct Fido2AssertionData: Sendable, Codable {
		public let clientData: String
		public let credId: String
		public let signature: String
		public var authenticatorData: String
		public var userHandle: String?
		
		public init(
			clientData: String,
			credId: String,
			signature: String,
			authenticatorData: String,
			userHandle: String? = nil
		) {
			self.clientData = clientData
			self.credId = credId
			self.signature = signature
			self.authenticatorData = authenticatorData
			self.userHandle = userHandle
		}
	}
}

// MARK: - PublicKeyCredentialParameters
extension DfnsApi {
	public struct PublicKeyCredentialParameters: Sendable, Codable {
		public let type: String
		public let alg: Int

        public init(
            type: String,
            alg: Int
        ) {
            self.type = type
            self.alg = alg
        }
	}
}

// MARK: - SupportedCredentialKinds
extension DfnsApi {
	public struct SupportedCredentialKinds: Sendable, Codable {
		public let firstFactor: [String]
		public let secondFactor: [String]

        public init(
            firstFactor: [String],
            secondFactor: [String]
        ) {
            self.firstFactor = firstFactor
            self.secondFactor = secondFactor
        }
	}
}

// MARK: - UserInformation
extension DfnsApi {
	public struct UserInformation: Sendable, Codable {
		public let id: String
		public let displayName: String
		public let name: String

        public init(
            id: String,
            displayName: String,
            name: String
        ) {
            self.id = id
            self.displayName = displayName
            self.name = name
        }
	}
}

// MARK: - AuthenticatorSelectionCriteria
extension DfnsApi {
	public struct AuthenticatorSelectionCriteria: Sendable, Codable {
		public let authenticatorAttachment: String?
		public let residentKey: String
		public let requireResidentKey: Bool
		public let userVerification: String
		
		public init(
			authenticatorAttachment: String? = nil,
			residentKey: String,
			requireResidentKey: Bool,
			userVerification: String
		) {
			self.authenticatorAttachment = authenticatorAttachment
			self.residentKey = residentKey
			self.requireResidentKey = requireResidentKey
			self.userVerification = userVerification
		}
	}
}

// MARK: - Fido2Attestation
extension DfnsApi {
	public struct Fido2Attestation: Sendable, Codable {
		public let credentialInfo: Fido2AttestationData
		public let credentialKind: String

        public init(
            credentialInfo: Fido2AttestationData,
            credentialKind: String
        ) {
            self.credentialInfo = credentialInfo
            self.credentialKind = credentialKind
        }
	}
}

// MARK: - Fido2AttestationData
extension DfnsApi {
    public struct Fido2AttestationData: Sendable, Codable {
        public let attestationData: String
        public let clientData: String
        public let credId: String

        public init(
            attestationData: String,
            clientData: String,
            credId: String
        ) {
            self.attestationData = attestationData
            self.clientData = clientData
            self.credId = credId
        }
    }
}
