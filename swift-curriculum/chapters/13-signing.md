# Code Signing and Provisioning, Demystified

You ship a Quarkus service by building a jar (or a container image)
and pushing it somewhere a runtime can fetch it: `scp` to a host,
`docker push` to a registry, `helm upgrade` on a cluster. The
artifact is trusted because *you* control the destination. Nobody
asks the jar to prove who built it. The host runs whatever bytes you
hand it.

iOS inverts that. An iPhone runs almost no code that Apple's trust
chain has not vouched for. There is no `scp`-the-binary path to a real
device, no "just run the artifact." Every app that launches on a
physical iPhone — yours, in development, or a paying customer's —
carries a cryptographic chain proving (a) a known Apple Developer
account built it, (b) for a specific app identity, (c) with a
specific set of permissions, (d) onto an authorized device or the
App Store. **Code signing** is how that chain is expressed.

This is, by wide agreement, the single most confusing part of iOS.
The good news for you: the primitives are ones you already use every
day — keypairs, X.509 certificates, a certificate authority, and a
signed manifest. The confusion is almost entirely vocabulary and the
fact that Apple's tooling hides the wiring. Once you name the pieces,
it collapses into something you already understand from TLS and
code-signing certs.

## Why the chain of trust exists

Apple's threat model is consumer-facing: a phone full of banking
apps, photos, and health data, owned by someone who is not a system
administrator. The platform guarantees that arbitrary, unvetted code
cannot run. The kernel refuses to execute a binary whose signature it
cannot validate against a trusted anchor — Apple's own root.

Compare your world. Your JVM happily loads any class on the
classpath. Your container runtime runs any image you pull. The trust
boundary lives at the *deploy* step, enforced by your registry creds
and your cluster RBAC, and you, the operator, are trusted. On iOS the
trust boundary lives at *every app launch*, enforced by the OS, and
the developer is *not* implicitly trusted — they must present a
chain that terminates at Apple.

> **Quarkus analogy.** Think of a corporate environment where the JVM
> refuses to load any jar that is not signed by a cert chaining to the
> company CA, and where the CA only issues certs to enrolled
> developers, scoped to one application's coordinates. iOS is that,
> with Apple as the mandatory CA and the App Store as the only public
> distribution channel.

There are exactly two destinations that require a full chain:
**physical devices** and the **App Store / TestFlight**. The
*Simulator* is the exception — it runs your code as a normal macOS
process under your own user account, so it needs no signature at all.
That single fact is why Alltag can build and test today with no Apple
account, and we will return to it.

## The pieces, mapped to things you know

There are six moving parts. Learn the mapping once and the Xcode
dialogs stop being mysterious.

| iOS concept            | What you already call it          |
|------------------------|-----------------------------------|
| Developer account/Team | CA enrollment + org identity      |
| Certificate            | Code-signing cert (keypair)       |
| App ID                 | Application coordinates           |
| Capabilities           | Requested grants / scopes         |
| Provisioning profile   | Signed manifest binding them      |
| The signature          | `jarsigner` / `codesign` output   |

### Apple Developer account and Team

Enrolling in the Apple Developer Program (€99/year) registers you as a
party Apple's CA will issue certificates to. Enrollment yields a
**Team ID** — a short opaque string like `A1B2C3D4E5` — that
identifies the legal entity (an individual or an organization) behind
every artifact you sign. It is the equivalent of being onboarded to
your company CA so it will mint certs in your name. In `project.yml`
the Team is named exactly once, by ID:

```yaml
settings:
  base:
    DEVELOPMENT_TEAM: ""   # fill in when an account is ready
```

It is empty today because Alltag has no account attached yet.

### Certificates: a keypair Apple signed

An iOS signing **certificate** is precisely what you think a
certificate is: an X.509 cert wrapping a public key, issued (signed)
by an Apple intermediate CA, with the matching **private key** held
in your **login Keychain** on the Mac. This is the same shape as a
code-signing cert or a TLS client cert. The private key never leaves
your machine; losing it means you can no longer produce signatures
that validate, exactly as losing a TLS private key would.

There are two flavors, differing only in what destinations they
authorize:

- **Development** (`Apple Development`): signs builds for devices you
  control, for debugging.
- **Distribution** (`Apple Distribution`): signs builds destined for
  the App Store or TestFlight.

Inspect what you hold today the same way you would list identities in
a keystore:

```bash
security find-identity -p codesigning -v
```

This prints the certificates in your Keychain whose private key is
present — the candidates Xcode can actually sign with. An empty list
on a CI box is normal and expected.

### App IDs: the application's coordinates

An **App ID** registers a bundle identifier — Alltag's is
`de.everydaygermany.app` — in Apple's portal, tying that string to
your Team and to a set of allowed capabilities. It is the reverse-DNS
equivalent of a Maven `groupId:artifactId`: a globally unique name
for *this* application. Apple uses it as the key under which it tracks
which capabilities the app may use. The value lives in the target:

```yaml
PRODUCT_BUNDLE_IDENTIFIER: de.everydaygermany.app
```

> **Note.** A *free* personal team (a plain Apple ID, no €99 program)
> can also sign for devices, but it cannot reuse a bundle ID another
> team has already claimed. If `de.everydaygermany.app` is taken on
> Apple's side, append a suffix such as `de.everydaygermany.app.dev`
> for local device builds. This is purely an Apple-namespace
> collision, not a code problem.

### Capabilities and entitlements: what the app may do

**Capabilities** are the privileged features an app requests — push
notifications, iCloud, App Groups, Keychain sharing, Sign in with
Apple, HealthKit, and so on. Each enabled capability is recorded as an
**entitlement**: a signed key/value baked into the app and cross-
checked at runtime by the OS. Think OAuth scopes, but cryptographically
welded to the binary: an app cannot grant itself a capability it was
not provisioned for, because the entitlement is covered by the
signature and the OS enforces it.

Here is the most reassuring sentence in this chapter for Alltag:
**it needs no capabilities beyond the defaults.** Alltag is a paid,
fully on-device app — no backend, no push, no iCloud sync, no App
Groups, no Keychain sharing across apps. Its document vault encrypts
files locally with a key in the device Keychain, which is ordinary
app-sandbox behavior requiring no special entitlement. So the
entitlements set is empty, the App ID needs no capabilities toggled,
and a whole category of signing pain — mismatched entitlements
between profile and app — simply cannot occur here. Fewer scopes,
fewer failure modes.

### Provisioning profiles: the binding document

A **provisioning profile** is the piece that newcomers cannot place,
because nothing in plain backend deployment corresponds to it. It is a
signed property list that *binds together*:

- one or more **certificates** (who may sign),
- one **App ID** (which app),
- a list of **device UDIDs** (for development/ad-hoc; the App Store
  variant lists none),
- the **entitlements** (what the app may do).

Apple signs this document. At build time, Xcode embeds it into the
`.app` bundle as `embedded.mobileprovision`. At install/launch time
the OS reads it and verifies: is this app's signature made by a cert
the profile authorizes? Does the bundle ID match? Is *this* device in
the list (or is this a Store build)? Do the requested entitlements
match what the profile grants? All four must hold or the app will not
launch.

> **Gotcha.** Almost every "it builds but won't install on my phone"
> error is a profile mismatch: a cert not listed, a device UDID
> absent, or an entitlement the profile does not grant. The build
> compiles fine — signing is a *post-compile* packaging step — so the
> failure shows up late, at install or upload, which is why it feels
> mysterious. Read the error as "the binding document does not cover
> this combination," then ask which of the four parts is off.

The mental model: the **certificate** proves *who*, the **App ID**
names *what*, the **device list** scopes *where*, the
**entitlements** declare *which powers*, and the **profile** is the
notarized contract tying all four together. The signature on the
binary is the wax seal.

## Automatic vs manual signing

You can manage those pieces two ways.

**Manual signing** means you create certificates, register devices,
generate profiles in Apple's portal, download them, and point each
build configuration at a specific profile by name. Total control, and
the right choice for locked-down CI where you inject credentials
deliberately. It is also the most error-prone by hand.

**Automatic signing** ("Automatically manage signing" in Xcode) means
you give Xcode your Team and it talks to Apple's portal for you:
creates a development cert if you lack one, registers the attached
device, generates and refreshes the matching profile, and selects it.
For a solo developer it removes nearly all the manual portal work. It
is what Alltag selects:

```yaml
CODE_SIGN_STYLE: Automatic
```

On the command line the flag that lets `xcodebuild` perform those
portal mutations (registering a device, minting a profile) is
`-allowProvisioningUpdates`, which the README already uses for device
builds. Without it, automatic signing can read existing assets but
will not create new ones — useful when you want CI to fail loudly
rather than silently touch your Apple account.

## Why Alltag defers signing — and how to flip it on

Alltag ships today with signing *deferred*. The header comment in
`project.yml` states the decision plainly:

```text
# Signing is deferred (D-decision): the project builds for the
# Simulator and CI without a signing identity. To run on a physical
# device or upload to App Store Connect, fill in DEVELOPMENT_TEAM and
# flip CODE_SIGNING_ALLOWED to YES below.
```

The mechanism is two build settings:

```yaml
CODE_SIGNING_ALLOWED: "NO"
CODE_SIGNING_REQUIRED: "NO"
```

These tell the build system to skip the signing step entirely. This
is correct and deliberate, because the only targets Alltag currently
runs are the **Simulator** (local development) and **CI** (the
`ios/scripts/ci.sh` pipeline). Neither needs a signature: the
Simulator runs the app as a normal process under your macOS user, and
CI only builds and tests against the Simulator. Demanding a signing
identity there would force every contributor and every CI run to carry
an Apple account and certificates to do work that does not require
them. Deferral keeps the barrier to entry at zero until there is an
actual device or Store to target. This is the same instinct as not
provisioning production TLS certs for a service you are only running
against `localhost` in tests.

To target a real device or App Store Connect, flip it on. The steps
are mechanical:

1. **Set the Team.** Put your Team ID in `DEVELOPMENT_TEAM`. Find it
   via Xcode ▸ Settings ▸ Accounts ▸ your Apple ID ▸ *Manage
   Certificates*, or from `security find-identity -p codesigning -v`.

   ```yaml
   DEVELOPMENT_TEAM: "A1B2C3D4E5"
   ```

2. **Enable signing.** Change both flags to `YES`:

   ```yaml
   CODE_SIGNING_ALLOWED: "YES"
   CODE_SIGNING_REQUIRED: "YES"
   ```

3. **Regenerate the project**, since the `.xcodeproj` is generated and
   git-ignored:

   ```bash
   cd ios
   xcodegen generate
   ```

4. **Register the device.** Connect the iPhone by USB, unlock it, tap
   **Trust**, and on iOS 16+ enable **Settings ▸ Privacy & Security ▸
   Developer Mode**. With automatic signing, building from Xcode (⌘R)
   or `xcodebuild ... -allowProvisioningUpdates build` registers the
   device's UDID and mints the profile for you.

For someone with no paid account, **free provisioning** is the
shortcut: sign in to Xcode with a personal Apple ID and automatic
signing issues a **7-day** development profile. The app runs on your
own device for a week, then must be re-signed — fine for trying the
real thing, insufficient for distribution. A paid account is required
the moment you want TestFlight, the App Store, or profiles that do not
expire weekly.

## Common signing errors and how to read them

The error text is intimidating; the cause is almost always one of the
four profile parts being off. A field guide:

| Error                          | Cause and fix                    |
|--------------------------------|----------------------------------|
| No profiles match              | No profile binds this App ID +   |
|                                | cert. Enable automatic + updates |
|                                | or generate one in the portal.   |
| Code signing identity not found| Cert/private key absent from the |
|                                | Keychain. Re-create or re-import.|
| Certificate has expired        | Issue a new one; old builds keep |
|                                | running, new signatures fail.    |
| Device not registered          | UDID not in the profile. Build   |
|                                | with `-allowProvisioningUpdates`.|
| Provisioning profile doesn't   | The App ID's capabilities and    |
| include entitlement X          | the app's entitlements diverge.  |

Two extra notes that resolve a surprising share of cases. First,
**wrong team**: if `DEVELOPMENT_TEAM` names a team you are not a
member of, or an old one, every profile lookup fails confusingly —
check that the ID matches an account in Xcode ▸ Settings ▸ Accounts.
Second, the calm default: **let automatic signing fix it.** Toggle
"Automatically manage signing" on, ensure the right Team is selected,
build once with `-allowProvisioningUpdates`, and Xcode will
regenerate whatever is missing. Manual surgery on certs and profiles
is a tool for when you specifically need determinism — in CI, or when
debugging — not the first move.

## Takeaways

- iOS refuses to run unsigned code on real devices and the Store; the
  Simulator is the exception, which is why Alltag builds today with no
  Apple account.
- The pieces map onto PKI you know: a **certificate** is an Apple-
  signed keypair (private key in your login Keychain); an **App ID**
  is the bundle ID `de.everydaygermany.app`; a **provisioning
  profile** is a signed manifest binding cert + App ID + devices +
  entitlements into the app.
- Alltag needs **no capabilities** — it is paid and fully on-device —
  so an entire class of entitlement mismatch errors cannot occur.
- Deferred signing (`CODE_SIGNING_ALLOWED: "NO"`, empty
  `DEVELOPMENT_TEAM`, `CODE_SIGN_STYLE: Automatic`) is deliberate;
  flip it by setting the Team, switching both signing flags to `YES`,
  and `xcodegen generate`.
- Free provisioning (personal Apple ID, 7-day profile) runs the app on
  your own device with no paid account; a paid account is required for
  TestFlight and the Store.
- Almost every signing error is one of four profile parts being off
  (cert, App ID, device, entitlement); automatic signing with
  `-allowProvisioningUpdates` regenerates most of them.

**Next:** *Distribution: App Store Connect, TestFlight, and Review*
