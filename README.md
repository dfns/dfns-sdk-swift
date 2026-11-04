# Dfns Swift SDK

Welcome, builders 👋🔑 This repo holds Dfns Swift SDK. Useful links:

- [Dfns Website](https://www.dfns.co)
- [Dfns API Docs](https://docs.dfns.co)

## Requirements

- **Xcode 16 or later** (Swift 6.0 toolchain). CI builds and tests the SDK with Xcode 16.0 and 26.3. Your app can use either the Swift 5 or the Swift 6 language mode.
- **iOS 15.0 or later** as your app's deployment target. The SDK relies on Apple's passkey APIs (`ASAuthorizationPlatformPublicKeyCredentialProvider`), introduced in iOS 15. On iOS 15 passkeys were a developer preview (behind the "Syncing Platform Authenticator" setting). They are enabled by default from **iOS 16**, which is the practical minimum for production use. iPadOS follows the same versions.
- **iOS only.** The package also declares macOS 12 so that its platform-independent code can be unit-tested on a Mac. Passkey signing is not supported on macOS.
- **Device passcode set.** The device must have a passcode (with Face ID or Touch ID where available), and iCloud Keychain enabled. iOS prompts the user to enable it on first passkey creation.
- **Associated Domains entitlement.** Your app must declare the `webcredentials:your-domain.com` associated domain, and the relying-party domain must serve a matching `apple-app-site-association` file.
- **Hardware security keys** (e.g. YubiKey) are supported as an alternative to platform passkeys, also from iOS 15.

## Installation

`File` > `Add Packages Dependencies` > `Search or Enter Package URL` > `https://github.com/dfns/dfns-sdk-swift`

The SDK is data-race safe under the Swift 6 language mode: its models and `PasskeysSigner` are `Sendable`, and `create`/`sign` can be awaited from any actor.

## Concepts

### `PasskeySigner`

All state-changing requests made to the Dfns API need to be cryptographically signed by credentials registered with the User. 

> **Note:** To be more precise, it's not the request itself that needs to be signed, but rather a "User Action Challenge" issued by Dfns. For simplicity, we refer to this process as "request signing".

This request signature serves as cryptographic proof that only authorized entities are making the request. Without it, the request would result in an Unauthorized error.
While implementing an iOS application your backend server will have to communicate with the DFNS API to retrieve this challenge and pass it to your application, `PasskeySigner` will be used to register and authenticate a user.

```
let passkeysSigner = try PasskeysSigner(relyingParty: DfnsApi.RelyingParty(id: "acme.com", name: "Acme"))
```

#### Create

```
let fido2Attestation = try! await passkeysSigner.create(challenge: challenge)
```

#### Sign

```
let fido2Assertion = try! await passkeysSigner.sign(challenge: challenge)
```

## DfnsDemo

A demo application using the SDK can be found [here](https://github.com/dfns/dfns-sdk-swift/tree/m/DfnsDemo). This demo application is to be used in conjunction with the [delegated registration and login tutorial](https://github.com/dfns/dfns-sdk-ts/tree/m/examples/sdk/auth-delegated#mobile-frontend). It is a replacement for the `iOS` section, you should read and execute all instruction written above this section to get this demo running.

#### Prerequisites

The demo app targets iOS 17.4 or later.

To run the demo application, you must first whitelist the domain associated with the app (the [Relying Party](https://www.w3.org/TR/webauthn-2/#relying-party)), e.g. `airedale-finer-baboon.ngrok-free.app`. Go to `Dfns Dashboard` > `Settings` > `Webauthn Relying Party` and add the domain. See [WebAuthn configuration](https://docs.dfns.co/guides/developers/webauthn-configuration) for details.

#### Configuration

In the `./DfnsDemo/DfnsDemo/Config.swift` set the following values,

- `serverUrl` = either `http://localhost:8000` or if using ngrok, the public url, e.g. `https://airedale-finer-baboon.ngrok-free.app` (your ngrok url may end with `.dev` instead, that works too)
- `passkeyRelyingPartyId` = the domain you whitelisted above, e.g. `airedale-finer-baboon.ngrok-free.app`

#### Modify associated domain entitlement

For iOS to download the correct `apple-app-site-association` file, you need to modify the associated domain entitlement configuration to point to the right location. Open the file `./DfnsDemo/DfnsDemo/DfnsDemo.entitlements` and change the string value `webcredentials:airedale-finer-baboon.ngrok-free.app?mode=developer` to match your domain.

#### Team Id

If you are using this demo iOS app with the tutorial server, remember to update the team id in the server files: https://github.com/dfns/dfns-sdk-ts/blob/m/examples/sdk/auth-delegated/server/static/apple-app-site-association
`${TEAMID}.co.dfns.sdk.tutorial.mobile`. If not known, one can retrieve its teamID with this snippet of code: https://stackoverflow.com/a/46727115

#### Enable Passkeys

In the simulator's menu options, go to `Features` > `Touch ID` or `Face ID` > `Enroll`, and verify the feature is toggled on. Even if the option is shown as on, you may still get the error "Simulator requires enrolled biometrics to use passkeys" when attempting to create a new Passkeys credential. If you encounter this error, go the the menu option and un-enroll, then re-enroll either `Touch ID` or `Face ID`.

Depending on the iOS version the simulator, you may also need to enable Passkeys on the simulated device in the iOS settings. Go to `Settings` > `Developer` > `Authentication Service Testing` > `Syncing Platform Authenticator`.
