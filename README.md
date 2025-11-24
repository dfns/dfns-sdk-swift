# Dfns Swift SDK

Welcome, builders 👋🔑 This repo holds Dfns Swift SDK. Useful links:

- [Dfns Website](https://www.dfns.co)
- [Dfns API Docs](https://docs.dfns.co)

## BETA Warning

> [!CAUTION] 
> **This project is currently in BETA.**

This means that while we've worked hard to ensure its functionality there may still be bugs, performance issues, or unexpected behavior.

## Installation

`File` > `Add Packages Dependencies` > `Search or Enter Package URL` > `https://github.com/dfns/dfns-sdk-swift`

## Concepts

### `PasskeySigner`

All state-changing requests made to the Dfns API need to be cryptographically signed by credentials registered with the User. 

> **Note:** To be more precise, it's not the request itself that needs to be signed, but rather a "User Action Challenge" issued by Dfns. For simplicity, we refer to this process as "request signing".

This request signature serves as cryptographic proof that only authorized entities are making the request. Without it, the request would result in an Unauthorized error.
While implementing an iOS application your backend server will have to communicate with the DFNS API to retrieve this challenge and pass it to your application, `PasskeySigner` will be used to register and authenticate a user.

```
let passkeysSigner = PasskeysSigner()
```

#### Register

```
let fido2Attestation = try! await passkeysSigner.register(challenge: challenge)
```

#### Sign

```
let fido2Assertion = try! await passkeysSigner.sign(challenge: challenge)
```

## DfnsDemo

A demo application using the SDK can be found [here](https://github.com/dfns/dfns-sdk-swift/tree/m/DfnsDemo). This demo application is to be used in conjunction with the [delegated registration and login tutorial](https://github.com/dfns/dfns-sdk-ts/tree/m/examples/sdk/auth-delegated#mobile-frontend). It is a replacement for the `iOS` section, you should read and execute all instruction written above this section to get this demo running.

#### Prerequisites

You need a `Service Account`. To create a new `Service Account`, first [generate a keypair](https://docs.dfns.co/dfns-docs/advanced-topics/authentication/credentials/generate-a-key-pair), then go to `Dfns Dashboard` > `Settings` > `Service Accounts` > `New Service Account`. Follow the [guide here](https://github.com/dfns/dfns-sdk-ts/tree/m/examples/sdk/auth-delegated#server-backend).

#### Configuration

In the `./DfnsDemo/DfnsDemo/Config.swift` set the following values,

- `url` = either `http://localhost:8000` or if using *ngrok*, the public url (e.g. `https://airedale-finer-baboon.ngrok-free.app`, your *ngrok* url might end with `".dev"`, that is fine too).

> [!NOTE]
> If you are using *ngrok* you might also need to add the url (e.g. `https://airedale-finer-baboon.ngrok-free.app`) in `Dfns Dashboard` > `Settings` > `Organization` > `Webauthn Relying Party` > `Whitelisted Passkey Domains (Relying Party ID)`.

#### Modify associated domain entitlement

For iOS to download the correct `apple-app-site-association` file, you need to modify the associated domain entitlement configuration to point to the right location. Open the file `./DfnsDemo/DfnsDemo/DfnsDemo.entitlements` and change the string value `webcredentials:airedale-finer-baboon.ngrok-free.app?mode=developer` to match your domain.

#### Team Id

If you are using this demo iOS app with the tutorial server, remember to update the team id in the server files: https://github.com/dfns/dfns-sdk-ts/blob/m/examples/sdk/auth-delegated/server/static/apple-app-site-association
`${TEAMID}.co.dfns.sdk.tutorial.mobile`. If not known, one can retrieve its teamID with this snippet of code: https://stackoverflow.com/a/46727115

#### Enable Passkeys

In the simulator's menu options, go to `Features` > `Touch ID` or `Face ID` > `Enroll`, and verify the feature is toggled on. Even if the option is shown as on, you may still get the error "Simulator requires enrolled biometrics to use passkeys" when attempting to create a new Passkeys credential. If you encounter this error, go the the menu option and un-enroll, then re-enroll either `Touch ID` or `Face ID`.

Depending on the iOS version the simulator, you may also need to enable Passkeys on the simulated device in the iOS settings. Go to `Settings` > `Developer` > `Authentication Service Testing` > `Syncing Platform Authenticator`.
