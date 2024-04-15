# Dfns Swift SDK

Welcome, builders 👋🔑 This repo holds Dfns Swift SDK. Useful links:

- [Dfns Website](https://www.dfns.co)
- [Dfns API Docs](https://docs.dfns.co)

## BETA Warning

:warning: **Attention: This project is currently in BETA.**

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
let passkeySigner = PasskeySigner(appOrigin: "https://app.dfns.wtf", relyingParty: "airedale-finer-baboon.ngrok-free.app")
```

#### Register

```
let credentialInfo = try! passkeySigner.register(
	challenge: "Y2gtN2NoZmEtdjdxZTgtOWZucHBhZTYzM2F1YW5xYQ",
	displayName: "my-user@gmail.com,
	userId: "us-7o7m3-t9ra9-9mvo5eessqtg9log"
)
```

#### Sign

```
let credentialAssertion = try! passkeySigner.sign(challenge: "Y2gtNXM1djAtcm40aDUtOXEwcnQyNjY4NWhvZnYybw")
```

## DfnsDemo

A demo application using the SDK can be found [here](https://github.com/dfns/dfns-sdk-swift/tree/m/DfnsDemo). This demo application is to be used in conjunction with the [delegated registration and login tutorial](https://github.com/dfns/dfns-sdk-ts/tree/m/examples/sdk/auth-delegated#mobile-frontend). It is a replacement for the `iOS` section, you should read and execute all instruction written above this section to get this demo running.

#### Prerequisites

To run the demo application on an iOS device, you must have an `Application` for iOS. To create a new `Application`, go to `Dfns Dashboard` > `Settings` > `Org Settings` > `Applications` > `New Application`, and enter the following information

- Name, choose any name, for example `Dfns Tutorial iOS`
- Application Type, leave as the default `Default Application`
- Relying Party, set to the domain you associated with the app, e.g. `panda-new-kit.ngrok-free.app`
- Origin, set to the full url of the domain, e.g. `https://panda-new-kit.ngrok-free.app`

After the `Application` is created, copy and save the `App ID`, e.g. `ap-39abb-5nrrm-9k59k0u3jup3vivo`.

#### Configuration

In the `./DfnsDemo/DfnsDemo/Config.swift` set the following values,

- `appId` = the `App ID` of the new `Application`
- `url` = either `http://localhost:8000` or if using ngrok, the public url `https://panda-new-kit.ngrok-free.app`
- `relyingParty` = same one used for the app creation on the Dfns dashboard (`panda-new-kit.ngrok-free.app`)
- `appOrigin` = same one used for the app creation on the Dfns dashboard (`https://panda-new-kit.ngrok-free.app`)

**NOTE**

The project uses `react-native-config` to manage the configuration settings. If you ever have to change the settings, there's a bug where the old settings are cached and not properly refreshed. You need to manually clear the cache before rebuild the app.

```
mobile %  rm node_modules/react-native-config/ios/ReactNativeConfig/GeneratedDotEnv.m
```

#### Modify associated domain entitlement

For iOS to download the correct `apple-app-site-association` file, you need to modify the associated domain entitlement configuration to point to the right location. Open the file `./DfnsDemo/DfnsDemo/DfnsDemo.entitlements` and change the string value `webcredentials:panda-new-kit.ngrok-free.app?mode=developer` to match your domain.

#### Enable Passkeys

In the simulator's menu options, go to `Features` > `Touch ID` or `Face ID` > `Enroll`, and verify the feature is toggled on. Even if the option is shown as on, you may still get the error "Simulator requires enrolled biometrics to use passkeys" when attempting to create a new Passkeys credential. If you encounter this error, go the the menu option and un-enroll, then re-enroll either `Touch ID` or `Face ID`.

Depending on the iOS version the simulator, you may also need to enable Passkeys on the simulated device in the iOS settings. Go to `Settings` > `Developer` > `Authentication Service Testing` > `Syncing Platform Authenticator`.
