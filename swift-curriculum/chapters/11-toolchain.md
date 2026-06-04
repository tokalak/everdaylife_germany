# The Toolchain: Xcode, SPM, XcodeGen, and the Build

You know how to stand up a JVM project blindfolded: a `pom.xml`
or `build.gradle`, a `settings.xml` pointing at Nexus, JUnit on
the test classpath, and a CI YAML that runs `mvn verify`. The
tools are separable. IntelliJ is *an* editor; Maven is *the*
build; the JDK is *a* runtime; you could swap any of them. Apple's
world is more fused. This chapter maps the iOS toolchain onto what
you already know, walks the real configuration of the **Alltag**
app, and shows where the analogy holds and where it breaks.

## Xcode is four tools wearing one icon

In the JVM world your daily work is spread across several programs:
IntelliJ (or VS Code), the `mvn`/`gradle` CLI, a profiler like
JFR/async-profiler, and maybe a separate device/container to run
on. Xcode collapses all of that into a single `.app`:

| Xcode role        | JVM-world equivalent                |
|-------------------|-------------------------------------|
| Editor + indexer  | IntelliJ IDEA                       |
| Build system      | Maven / Gradle (`xcodebuild`)       |
| Simulator         | a local device to run on            |
| Instruments       | JFR, async-profiler, VisualVM       |

The build engine has a headless CLI, `xcodebuild`, analogous to
`mvn` — the IDE is a front end over it. So you *can* build without
the GUI (CI does exactly that), but you cannot, in practice, build
without **Xcode installed**: the compiler (`swiftc`), the SDKs, the
linker, and the Simulator runtimes all ship inside the Xcode app
bundle, selected by `xcode-select`. There is no standalone "Swift
SDK for iOS" you download separately the way you grab a JDK. That
coupling is the first thing that feels wrong coming from Java: the
toolchain version *is* the IDE version.

> **Quarkus analogy.** `xcodebuild` is `mvn`/`gradle`; the Xcode
> GUI is IntelliJ driving it. But unlike a JDK you can `apt
> install`, the iOS SDK and simulators live inside Xcode itself —
> one big versioned bundle, not separable parts.

Alltag is built and tested on **Xcode 26** with an **iOS 17.0**
deployment target (see `ios/README.md`). Swift here is **5.x**
with strict concurrency on, the iOS analogue of compiling with
`-Werror` plus a thread-safety checker baked into the language.

The fourth tool, **Instruments**, is the profiler — Time Profiler,
Allocations, Leaks, and dozens of other "instruments" you record a
trace with, the way you would attach JFR or async-profiler to a
running JVM. The difference is integration: you launch a profiling
session straight from the same scheme's **Profile** action (which,
per the scheme, builds Release), so the optimized binary you measure
is the one you ship. There is nothing to wire up separately.

## The `.xcodeproj`: an opaque bundle and a merge-conflict magnet

A Maven project's source of truth is a human-readable `pom.xml`.
Xcode's is the `.xcodeproj` — and it is the opposite of
human-readable. It is a **bundle** (a directory macOS shows as one
file) whose core is `project.pbxproj`: a giant, machine-managed
property list full of synthetic hex identifiers like
`67478AD1A8217FB2ACD51368`. Every file you add, every build
setting you toggle in the GUI, rewrites this file.

Two consequences hurt teams:

- **Merge conflicts.** Two engineers each add a file on their
  branch and the `pbxproj` collides in ways git cannot sanely
  three-way-merge. There is no clean `<dependency>` block to
  reconcile — just reshuffled hex IDs.
- **Opacity.** You cannot meaningfully code-review a diff of it.
  The intent ("added a test target") is buried under generated
  noise.

The fix the community converged on is to stop hand-editing the
`.xcodeproj` and instead **generate** it from a readable spec. That
is what Alltag does.

## Why Alltag uses XcodeGen

[XcodeGen](https://github.com/yonaskolb/XcodeGen) reads a YAML
file, `project.yml`, and produces the `.xcodeproj` from scratch.
The generated project is **git-ignored**; the YAML is the source of
truth. The header of `ios/project.yml` says it outright:

```text
# The .xcodeproj is GENERATED from this file and is .gitignored.
# Regenerate locally with:  cd ios && xcodegen generate
```

This is precisely the `pom.xml` model. The spec is small, diffable,
reviewable, and conflict-free; the heavy generated artifact never
enters version control. After cloning, or after adding files or
flipping a setting, you run:

```bash
cd ios
xcodegen generate
open Alltag.xcodeproj
```

`xcodegen generate` is the moral equivalent of letting Maven
synthesize an IDE project from the POM. Files are picked up by
*directory*, not enumerated by hand: the spec points a target at a
folder and every source under it is included. Add a `.swift` file,
re-run `generate`, done — no `pbxproj` surgery, no conflict.

> **Gotcha.** Because the `.xcodeproj` is generated and ignored,
> never edit project settings in Xcode's GUI and expect them to
> stick — the next `xcodegen generate` overwrites them. The GUI is
> for browsing and running; `project.yml` is for changing. Treat it
> like a `target/` directory you happen to open in an IDE.

## Reading the real `project.yml`

Open `ios/project.yml` and read it top to bottom; it is the whole
build definition in ~70 lines.

### Project-level options and settings

```yaml
name: Alltag

options:
  bundleIdPrefix: de.everydaygermany
  developmentLanguage: de
  deploymentTarget:
    iOS: "17.0"
```

`deploymentTarget: iOS "17.0"` is the minimum OS the app supports —
the analogue of `<maven.compiler.release>17</...>` but for the
*platform*, not the language. Code may use APIs up to the SDK Xcode
ships, but must still run on iOS 17. `developmentLanguage: de` makes
**German** the base localization (a deliberate decision for this
app; English and others layer on later).

```yaml
settings:
  base:
    MARKETING_VERSION: "0.1.0"
    CURRENT_PROJECT_VERSION: "1"
    SWIFT_VERSION: "5.0"
    DEVELOPMENT_TEAM: ""
    CODE_SIGN_STYLE: Automatic
    CODE_SIGNING_ALLOWED: "NO"
    CODE_SIGNING_REQUIRED: "NO"
    SWIFT_STRICT_CONCURRENCY: complete
    ENABLE_USER_SCRIPT_SANDBOXING: "YES"
```

These are **build settings** — Xcode's equivalent of compiler
flags plus packaging metadata, applied to everything unless a target
overrides them.

- `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` are the
  user-facing version (`0.1.0`) and the internal build number — the
  `<version>` and a monotonic build counter.
- `SWIFT_VERSION: "5.0"` selects the **language mode**, like
  `--release 17`. (Swift 6 introduces a stricter mode; Alltag stays
  in 5 mode while opting into the new concurrency checks.)
- `SWIFT_STRICT_CONCURRENCY: complete` is the headline: it makes
  the compiler enforce data-race safety at compile time, flagging
  any value shared across concurrency boundaries that is not
  provably `Sendable`. There is no JVM analogue — imagine `javac`
  rejecting code that lets a non-thread-safe object escape to
  another thread. Covered in depth in the concurrency chapter; here,
  note that it is *on at the project level*.
- The four `CODE_SIGN*` / `DEVELOPMENT_TEAM` settings **defer
  signing**: empty team, automatic style, signing not allowed and
  not required. This is what lets the app build and test on the
  Simulator and in CI with no Apple Developer account — the subject
  of Chapter 13.
- `ENABLE_USER_SCRIPT_SANDBOXING: "YES"` sandboxes any build-phase
  scripts, a hardening default.

### Targets

A **target** is a build product plus the rules to produce it —
closest to a Maven *module* or a Gradle *subproject*, but finer:
the app and its tests are separate targets in one project. Alltag
declares two.

```yaml
targets:
  Alltag:
    type: application
    platform: iOS
    sources:
      - path: Alltag
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: de.everydaygermany.app
        GENERATE_INFOPLIST_FILE: "YES"
        TARGETED_DEVICE_FAMILY: "1"
        # ... INFOPLIST_KEY_* and asset names
```

The `Alltag` target is `type: application` — it produces
`Alltag.app`. Its `PRODUCT_BUNDLE_IDENTIFIER` is
**`de.everydaygermany.app`**, the unique reverse-DNS identity of
the app on device and in the App Store (think Maven `groupId` +
`artifactId`, but globally unique and Apple-registered).
`TARGETED_DEVICE_FAMILY: "1"` means iPhone only.

```yaml
  AlltagTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - path: Tests/AlltagTests
    dependencies:
      - target: Alltag
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: de.everydaygermany.app.tests
        GENERATE_INFOPLIST_FILE: "YES"
```

`AlltagTests` is a `bundle.unit-test` target that **depends on**
`Alltag`. The dependency is what lets the tests reach into the app
with `@testable import Alltag` — analogous to test sources on the
same module having package-private access, except here the app and
tests are distinct targets and `@testable` grants that access
explicitly. Tests get their own bundle identifier,
`de.everydaygermany.app.tests`.

### Schemes

A **scheme** ties targets to *actions*: Build, Run, Test, Profile,
Archive. There is no clean Maven analogue — it is closest to a set
of named run configurations plus a binding of which targets each
lifecycle phase touches.

```yaml
schemes:
  Alltag:
    build:
      targets:
        Alltag: all
    test:
      targets:
        - AlltagTests
      gatherCoverageData: true
```

The `Alltag` scheme builds the app target and, on **Test**, runs
`AlltagTests` with **coverage gathering on**. XcodeGen writes this
into the generated scheme file
(`Alltag.xcscheme`), where you can see the same intent expanded:
`codeCoverageEnabled = "YES"`, the `Debug` configuration for tests,
and `Release` for Profile and Archive. That last detail matters:
**build configurations** (Debug vs. Release) are chosen *per
action*. You test and debug in Debug (assertions on, optimizations
off) and ship/profile in Release (optimized) — the same Debug/prod
split you know, but selected by which scheme action you invoke
rather than a Maven profile flag.

## Swift Package Manager vs. Maven/Gradle

**Swift Package Manager (SPM)** is the dependency manager, declared
in a `Package.swift` — and unlike `pom.xml`, the manifest is
*Swift code*, executed to produce the package description (closer in
spirit to a Gradle Kotlin DSL than to declarative XML). A minimal
manifest declaring one dependency:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Example",
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-log",
            from: "1.5.0"),
    ],
    targets: [
        .target(name: "Example", dependencies: [
            .product(name: "Logging", package: "swift-log"),
        ]),
    ]
)
```

The biggest mental shift: **SPM is decentralized.** A dependency is
a **git URL**, resolved directly against GitHub (or any git host),
pinned by a `Package.resolved` lockfile (the analogue of a Gradle
lockfile). There is no Maven Central, no Nexus, no `settings.xml`
with mirror and credential configuration. Versions are git tags;
resolution is semantic-version ranges over those tags. No central
coordinate namespace means no `groupId:artifactId` — the URL *is*
the coordinate. For an app, you usually add packages through Xcode
(File ▸ Add Package Dependencies), and Xcode records them in the
project; XcodeGen also supports a `packages:` section in
`project.yml` so dependencies stay declared in the readable spec.

Alltag, being a paid, on-device app with deliberately few external
dependencies, keeps this lean — but the model is the one above:
point at a git URL, pin a version, build.

> **Note.** Decentralized resolution means a dependency can vanish
> if its repo goes away, and there is no built-in private registry
> story as mature as Nexus. The tradeoff buys zero-infrastructure
> setup: no artifact server to run, no `settings.xml` to distribute.

## The Simulator: a simulator, not an emulator

This distinction matters and is easy to get wrong. The Android
**emulator** virtualizes ARM hardware; it is slow because it
emulates a different CPU. Apple's **Simulator** does *not* emulate a
phone's CPU. On a Mac it builds your app for the host architecture
and runs it as a **native macOS process** against a simulated iOS
runtime (UIKit, the frameworks, a fake device environment). The
result is fast — launches in seconds, no virtualized hardware — but
it is *not* a faithful device: no real Keychain entitlements
sometimes, no Apple-silicon-only hardware features, performance
characteristics that differ from a real iPhone. You develop against
the Simulator and *verify* on a device.

You will see this asymmetry in the tests: `KeychainKeyStoreTests`
deliberately `XCTSkip`s when the Keychain is unavailable in an
unsigned Simulator run (`errSecMissingEntitlement`, -34018), because
the Simulator does not grant the same entitlements a signed device
build would.

## `xcodebuild`, DerivedData, and Info.plist

### The CLI

`xcodebuild` is the headless build, the `mvn` of this world. Its
three verbs you will use most:

```bash
# compile the app for a simulator
xcodebuild build -project Alltag.xcodeproj -scheme Alltag \
  -destination 'platform=iOS Simulator,name=iPhone 17'

# build + run the test suite
xcodebuild test -project Alltag.xcodeproj -scheme Alltag \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  CODE_SIGNING_ALLOWED=NO

# produce a distributable archive (Release)
xcodebuild archive -project Alltag.xcodeproj -scheme Alltag \
  -archivePath build/Alltag.xcarchive
```

`-scheme` selects what to build and `-destination` selects where to
run it (which simulator or device). Note you can override build
settings on the command line — `CODE_SIGNING_ALLOWED=NO` — exactly
as the README and CI do, the way you would pass `-D` to Maven.

### DerivedData

Build outputs, the module cache, indexes, and intermediate
artifacts land in **DerivedData** (by default under
`~/Library/Developer/Xcode/DerivedData/`), not in your project
tree. It is the equivalent of `target/` plus the Maven local repo
cache plus the IDE index — and when Xcode behaves strangely, deleting
DerivedData is the canonical "clean build" reset (`mvn clean`'s
heavier cousin). Because it lives outside the repo, it is implicitly
"ignored" without a `.gitignore` entry. A frequent gotcha is that
stale DerivedData masks problems — a renamed type still resolving, a
deleted file still linking — so when a build is mysterious, the
first move is `xcodebuild clean` or deleting the per-project folder
under DerivedData, not a clean `git` checkout.

### Info.plist and entitlements

Every iOS app ships an **`Info.plist`** — a property list of
runtime metadata: display name, supported orientations, scene
configuration, required device capabilities. It is the rough
analogue of a `MANIFEST.MF` plus deployment descriptor. Classically
you hand-maintained this XML file; Alltag instead has Xcode
**synthesize** it. In `project.yml`:

```yaml
GENERATE_INFOPLIST_FILE: "YES"
INFOPLIST_KEY_UILaunchScreen_Generation: "YES"
INFOPLIST_KEY_UIApplicationSceneManifest_Generation: "YES"
INFOPLIST_KEY_UISupportedInterfaceOrientations:
  "UIInterfaceOrientationPortrait"
ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor
```

`GENERATE_INFOPLIST_FILE: "YES"` tells the build to *generate* the
`Info.plist` rather than read a checked-in one, and each
`INFOPLIST_KEY_*` setting injects one entry into it. So the launch
screen, the scene manifest, and the portrait-only orientation are
all declared as build settings in the readable spec — no XML to
merge. The asset settings point the build at the app icon and accent
color in the asset catalog.

**Entitlements** are a separate, signing-time concern: a list of
privileged capabilities the OS grants the app (Keychain sharing,
push, app groups). They live in an `.entitlements` file and are
sealed into the app at signing. Alltag defers signing, so it carries
no custom entitlements yet — Chapter 13 returns to this.

## How to build and run Alltag, end to end

Two paths, both starting from the same regenerate step.

**Interactive (the inner dev loop):**

```bash
cd ios
xcodegen generate
open Alltag.xcodeproj
# pick an iPhone simulator in the toolbar, press Cmd-R
```

**Headless (what CI does):** the repo ships a local CI script,
`ios/scripts/ci.sh`, that regenerates the project, picks the newest
available iPhone simulator via `simctl`, and runs `xcodebuild test`
with signing disabled. You can run the identical pipeline locally:

```bash
ios/scripts/ci.sh
```

That single command — regenerate, select simulator, build, test —
is the whole story of building this app without ever touching the
Xcode GUI. The next chapter takes that test step apart.

## Takeaways

- **Xcode fuses** editor, build system (`xcodebuild`), Simulator,
  and profiler into one app; the SDK and simulators live *inside*
  it, so toolchain version is tied to IDE version.
- The **`.xcodeproj`** is an opaque, conflict-prone generated-style
  bundle; Alltag treats it as a build artifact, **git-ignoring** it
  and generating it from `project.yml` via **XcodeGen** — its
  `pom.xml`.
- Read `project.yml` as the build definition: iOS 17 deployment
  target, `SWIFT_STRICT_CONCURRENCY: complete`, two targets
  (`Alltag` app + `AlltagTests`), one scheme with coverage,
  generated `Info.plist`, bundle id **`de.everydaygermany.app`**.
- **SPM** is decentralized: dependencies are git URLs pinned by a
  lockfile — no Maven Central, no `settings.xml`.
- The **Simulator** runs natively (fast, not an emulator) but is
  not a faithful device — verify on hardware.
- Build & run with `xcodegen generate` then Xcode, or run the whole
  pipeline headless with `ios/scripts/ci.sh`.

**Next:** *Testing: Swift Testing, XCTest, Previews, and CI*
