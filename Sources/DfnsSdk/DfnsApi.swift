/**
    Types defined in the Dfns API that might be arguments or return values of the demo server
 */
public enum DfnsApi {
    public struct UserActionChallenge: Codable {
        public init(attestation: String, userVerification: String, externalAuthenticationUrl: String, challenge: String, challengeIdentifier: String, rp: DfnsApi.RelyingParty, supportedCredentialKinds: [DfnsApi.SupportedCredentialKind], allowCredentials: DfnsApi.AllowCredentials) {
            self.attestation = attestation
            self.userVerification = userVerification
            self.externalAuthenticationUrl = externalAuthenticationUrl
            self.challenge = challenge
            self.challengeIdentifier = challengeIdentifier
            self.rp = rp
            self.supportedCredentialKinds = supportedCredentialKinds
            self.allowCredentials = allowCredentials
        }

        public let attestation: String
        public let userVerification: String
        public let externalAuthenticationUrl: String
        public let challenge: String
        public let challengeIdentifier: String
        public let rp: RelyingParty
        public let supportedCredentialKinds: [SupportedCredentialKind]
        public let allowCredentials: AllowCredentials
    }

    public struct UserRegistrationChallenge: Codable {
        public init(temporaryAuthenticationToken: String, rp: DfnsApi.RelyingParty, user: DfnsApi.UserInformation, supportedCredentialKinds: DfnsApi.SupportedCredentialKinds, otpUrl: String, challenge: String, authenticatorSelection: DfnsApi.AuthenticatorSelectionCriteria, attestation: String, pubKeyCredParams: [DfnsApi.PublicKeyCredentialParameters], excludeCredentials: [DfnsApi.AllowCredentials]) {
            self.temporaryAuthenticationToken = temporaryAuthenticationToken
            self.rp = rp
            self.user = user
            self.supportedCredentialKinds = supportedCredentialKinds
            self.otpUrl = otpUrl
            self.challenge = challenge
            self.authenticatorSelection = authenticatorSelection
            self.attestation = attestation
            self.pubKeyCredParams = pubKeyCredParams
            self.excludeCredentials = excludeCredentials
        }

        public let temporaryAuthenticationToken: String
        public let rp: RelyingParty
        public let user: UserInformation
        public let supportedCredentialKinds: SupportedCredentialKinds
        public let otpUrl: String
        public let challenge: String
        public let authenticatorSelection: AuthenticatorSelectionCriteria
        public let attestation: String
        public let pubKeyCredParams: [PublicKeyCredentialParameters]
        public let excludeCredentials: [AllowCredentials]
    }

    public struct RelyingParty: Codable {
        public init(id: String, name: String) {
            self.id = id
            self.name = name
        }

        public let id: String
        public let name: String
    }

    public struct SupportedCredentialKind: Codable {
        public init(kind: String, factor: String, requiresSecondFactor: Bool) {
            self.kind = kind
            self.factor = factor
            self.requiresSecondFactor = requiresSecondFactor
        }

        public let kind: String
        public let factor: String
        public let requiresSecondFactor: Bool
    }

    public struct AllowCredentials: Codable {
        public init(webauthn: [DfnsApi.PublicKeyCredentialDescriptor], key: [DfnsApi.PublicKeyCredentialDescriptor]) {
            self.webauthn = webauthn
            self.key = key
        }

        public let webauthn: [PublicKeyCredentialDescriptor]
        public let key: [PublicKeyCredentialDescriptor]
    }

    public struct PublicKeyCredentialDescriptor: Codable {
        public init(type: String, id: String) {
            self.type = type
            self.id = id
        }

        public let type: String
        public let id: String
    }

    public struct Fido2Assertion: Codable {
        public init(kind: String, credentialAssertion: DfnsApi.Fido2AssertionData) {
            self.kind = kind
            self.credentialAssertion = credentialAssertion
        }

        public let kind: String
        public let credentialAssertion: Fido2AssertionData
    }

    public struct UserActionAssertion: Codable {
        public init(challengeIdentifier: String, firstFactor: DfnsApi.Fido2Assertion) {
            self.challengeIdentifier = challengeIdentifier
            self.firstFactor = firstFactor
        }

        public let challengeIdentifier: String
        public let firstFactor: Fido2Assertion
    }

    public struct ClientData: Codable {
        public init(type: String, challenge: String, origin: String) {
            self.type = type
            self.challenge = challenge
            self.origin = origin
        }

        public let type: String
        public let challenge: String
        public let origin: String
        // public let crossOrigin: Bool
    }

    public struct Fido2AssertionData: Codable {
        public init(clientData: String, credId: String, signature: String, authenticatorData: String, userHandle: String? = nil) {
            self.clientData = clientData
            self.credId = credId
            self.signature = signature
            self.authenticatorData = authenticatorData
            self.userHandle = userHandle
        }

        public let clientData: String
        public let credId: String
        public let signature: String
        public var authenticatorData: String
        public var userHandle: String?
    }

    public struct PublicKeyCredentialParameters: Codable {
        public init(type: String, alg: Int) {
            self.type = type
            self.alg = alg
        }

        public let type: String
        public let alg: Int
    }

    public struct SupportedCredentialKinds: Codable {
        public init(firstFactor: [String], secondFactor: [String]) {
            self.firstFactor = firstFactor
            self.secondFactor = secondFactor
        }

        public let firstFactor: [String]
        public let secondFactor: [String]
    }

    public struct UserInformation: Codable {
        public init(id: String, displayName: String, name: String) {
            self.id = id
            self.displayName = displayName
            self.name = name
        }

        public let id: String
        public let displayName: String
        public let name: String
    }

    public struct AuthenticatorSelectionCriteria: Codable {
        public init(authenticatorAttachment: String? = nil, residentKey: String, requireResidentKey: Bool, userVerification: String) {
            self.authenticatorAttachment = authenticatorAttachment
            self.residentKey = residentKey
            self.requireResidentKey = requireResidentKey
            self.userVerification = userVerification
        }

        public let authenticatorAttachment: String?
        public let residentKey: String
        public let requireResidentKey: Bool
        public let userVerification: String
    }

    public struct Fido2Attestation: Codable {
        public init(credentialInfo: DfnsApi.Fido2AttestationData, credentialKind: String) {
            self.credentialInfo = credentialInfo
            self.credentialKind = credentialKind
        }

        public let credentialInfo: Fido2AttestationData
        public let credentialKind: String
    }

    public struct Fido2AttestationData: Codable {
        public init(attestationData: String, clientData: String, credId: String) {
            self.attestationData = attestationData
            self.clientData = clientData
            self.credId = credId
        }

        public let attestationData: String
        public let clientData: String
        public let credId: String
    }
}
