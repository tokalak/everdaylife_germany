# Alltag (iOS)

AI-assisted iOS app helping foreigners handle bureaucracy and everyday life in
Germany. See [`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md) for scope and
[`AGENTS.md`](AGENTS.md) for conventions.

## Prerequisites

- Xcode 17+ (iOS 17.0 deployment target; built/tested on Xcode 26).
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Project generation

The `.xcodeproj` is **generated** from [`project.yml`](project.yml) and is
git-ignored. After cloning, or after changing files/targets/settings:

```sh
cd ios
xcodegen generate
open Alltag.xcodeproj
```

## Build & test from the command line

```sh
cd ios
xcodegen generate
xcodebuild test \
  -project Alltag.xcodeproj \
  -scheme Alltag \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  CODE_SIGNING_ALLOWED=NO
```

CI runs the same flow on every PR — see
[`../.github/workflows/ios-ci.yml`](../.github/workflows/ios-ci.yml).

## Run on a connected iPhone (USB)

Unlike the Simulator, a physical device **requires code signing**. A free Apple
ID works (no paid Developer account needed) — Xcode issues a 7-day personal
provisioning profile. Do this once:

1. **Enable signing in the project.** Edit [`project.yml`](project.yml):
   - set `DEVELOPMENT_TEAM` to your Team ID (find it in Xcode ▸ Settings ▸
     Accounts ▸ your Apple ID ▸ *Manage Certificates*, or run
     `security find-identity -p codesigning -v`), and
   - change `CODE_SIGNING_ALLOWED` / `CODE_SIGNING_REQUIRED` to `"YES"`.

   Then regenerate: `xcodegen generate`.

   > A free personal team also requires a **unique** bundle ID — if
   > `de.everydaygermany.app` is already taken on Apple's side, append a suffix
   > (e.g. `de.everydaygermany.app.dev`) for local device builds.

2. **Prepare the iPhone.** Connect it by USB and unlock it. Tap **Trust** on the
   "Trust This Computer?" prompt. On iOS 16+, enable **Settings ▸ Privacy &
   Security ▸ Developer Mode**, toggle it on, and let the phone restart.

### Easiest: run from Xcode

```sh
cd ios && xcodegen generate && open Alltag.xcodeproj
```

Pick your iPhone from the run-destination menu (top toolbar) and press **⌘R**.
The first run prompts you to register the device and, on the phone, to trust the
developer under **Settings ▸ General ▸ VPN & Device Management**.

### From the command line

List connected devices and grab the identifier:

```sh
xcrun devicectl list devices          # modern (Xcode 15+); shows the device UUID
# or:  xcodebuild -showdestinations -scheme Alltag -project Alltag.xcodeproj
```

Build, install, and launch on that device (replace `<DEVICE_ID>`):

```sh
cd ios
xcodegen generate
xcodebuild -project Alltag.xcodeproj -scheme Alltag \
  -destination 'platform=iOS,id=<DEVICE_ID>' \
  -allowProvisioningUpdates build

# install + launch the freshly built .app
APP=$(xcodebuild -project Alltag.xcodeproj -scheme Alltag -showBuildSettings \
  -destination 'platform=iOS,id=<DEVICE_ID>' \
  | awk '/ BUILT_PRODUCTS_DIR /{d=$3}/ FULL_PRODUCT_NAME /{n=$3}END{print d"/"n}')
xcrun devicectl device install app   --device <DEVICE_ID> "$APP"
xcrun devicectl device process launch --device <DEVICE_ID> de.everydaygermany.app
```

> Wireless debugging: after the first USB pairing, enable **Connect via network**
> on the device row in Xcode ▸ Window ▸ Devices and Simulators, then the same
> commands work over Wi-Fi.

## Source layout (Boundary-Control-Entity)

Code is organized **per feature**, each split into Boundary / Control / Entity
(see `IMPLEMENTATION_PLAN.md` §2.2). Phase 0 has landed the foundations; feature
Control/Entity layers fill in as later phases land.

```
ios/
  project.yml            # XcodeGen spec (source of truth for the project)
  Alltag/
    App/                 # AlltagApp, RootView (5-tab shell), AppEnvironment (DI), AppTab
    DesignSystem/        # AppColor tokens, AppTheme/ThemeController, typography, placeholders (foundation; full set Phase 1)
    Core/
      Persistence/       # PersistenceController (SwiftData), EncryptedFileStore, KeyStore, FileCryptor, DocumentRecord
      Localization/      # AppLanguage, LanguageStore
      # added later: LLM/, Notifications/
    Features/            # per-feature Boundary views (placeholders today)
      {Home,Vault,Decoder,Calendar,Settings}/Boundary
      # added later: Onboarding, Personas, Tools, Guides + Control/Entity layers
    Resources/           # Assets.xcassets, Localizable.xcstrings
  Tests/
    AlltagTests/         # unit tests mirroring feature folders
```

## Configuration (P0-01)

| Setting            | Value                                            |
|--------------------|--------------------------------------------------|
| Bundle ID (app)    | `de.everydaygermany.app`                         |
| Bundle ID (tests)  | `de.everydaygermany.app.tests`                   |
| Deployment target  | iOS 17.0                                          |
| Device family      | iPhone (iOS-first, D3)                            |
| Development region  | German (default/dev language, D7)               |
| Signing            | **Deferred** — simulator/CI only                 |

### Signing & App Store Connect — manual follow-ups

Signing is intentionally deferred: `CODE_SIGNING_ALLOWED=NO` lets the app build
and test on the Simulator and in CI without an Apple Developer account. These
steps require an Apple Developer account and Apple's web/Xcode UI, so they are
**not** automatable here:

1. **Apple Developer account / Team ID** — once enrolled, set `DEVELOPMENT_TEAM`
   in `project.yml` and flip `CODE_SIGNING_ALLOWED`/`CODE_SIGNING_REQUIRED` to
   `YES`, then `xcodegen generate`. Automatic signing handles the rest.
2. **Register the App ID** `de.everydaygermany.app` in the Developer portal.
3. **Create the App Store Connect record** (new app, primary language German)
   for TestFlight/distribution (P9-05/06).
