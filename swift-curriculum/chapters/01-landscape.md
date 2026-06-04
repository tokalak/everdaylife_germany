# The Landscape: from JVM to iOS

You know how a Quarkus service reaches production: `mvn package`
emits a JAR or native image, a runtime (JVM or an app server)
hosts your code, and a load balancer fronts it. iOS inverts
almost every layer of that picture. This chapter maps the new
terrain onto what you already know, and flags where the map lies.

## No JVM, no GC at the platform level

Swift compiles **ahead of time to native machine code** through
**LLVM** — the same backend as `clang`. There is no bytecode, no
interpreter, no JIT warm-up, and no class loader. The binary that
ships in your app is `arm64` instructions the iPhone CPU runs
directly. The closest JVM analogy is a GraalVM native image, but
that is the exception on the JVM and the only option here.

There is also no tracing garbage collector. Swift manages object
lifetimes with **ARC** (Automatic Reference Counting): the
compiler inserts retain/release calls at compile time, and an
object is freed the instant its last strong reference drops. No
background GC thread, no stop-the-world pauses, no `-Xmx`.

> **Quarkus analogy.** Picture every build as `quarkus build
> --native`, every time, with no JVM fallback. You get fast
> launch and a small resident footprint, but you also inherit
> native-build realities: no runtime reflection-by-default, no
> hot class redefinition, no live JVM to attach a profiler to in
> the same way.

ARC is not free of hazards — reference cycles leak, exactly like
a non-collected graph would. The full treatment, including
`weak`/`unowned` and how value types sidestep the problem, is in
*Memory and Concurrency: ARC, async/await, Actors*. For now,
hold one fact: memory is deterministic, not collected.

## The players, and how they map

| JVM world            | iOS world                       |
|----------------------|---------------------------------|
| Java (language)      | Swift (language)                |
| JDK / `java.*`       | SDK frameworks (Foundation …)   |
| A web/UI framework   | SwiftUI                         |
| Maven / Gradle       | SPM + Xcode project (XcodeGen)  |
| JUnit                | Swift Testing / XCTest          |
| CDI / Spring DI      | SwiftUI `Environment`           |
| App server hosts JAR | The OS hosts your `.app`        |
| `public static main` | `@main App`                     |

**Swift** is the language: statically typed, with generics,
protocols (think interfaces with more power), value types, and
first-class closures. It will feel like a denser, more
value-oriented Java. **SwiftUI** is the declarative UI framework
— roughly the role a server-side template engine or a frontend
framework plays, except it renders native widgets and owns the
render loop.

The **SDK frameworks** are your standard library plus platform
APIs, the equivalent of the JDK. **Foundation** gives you
`Data`, `URL`, `Date`, `FileManager`, JSON coding — the
`java.*`/`javax.*` workhorses. Specialized frameworks layer on
top: **CryptoKit** for AES-GCM (you will see it below),
**SwiftData** for persistence, **CryptoKit** + **Keychain** for
key storage. Unlike the JDK, these are versioned with the OS, not
shipped inside your artifact.

## Xcode is the whole toolchain

In the JVM world your tools are separable: IntelliJ for editing,
Maven for builds, a separate JDK, a separate app server, JUnit on
the classpath. **Xcode** collapses all of that into one
application: editor, the Swift compiler and build system, the
**Simulator**, the debugger, Instruments (the profiler), and the
signing machinery. It is IntelliJ + Maven + the runtime + the
profiler in a single window.

That bundling is the first big adjustment. You do not pick your
build tool; the project *is* an Xcode build. In this repo we tame
that with **XcodeGen**: the `.xcodeproj` is generated from a
declarative `project.yml` and git-ignored, so the YAML is the
source of truth — closer to a `pom.xml` than to the opaque,
merge-conflict-prone Xcode project file. You will see this in
*The Toolchain: Xcode, SPM, XcodeGen, and the Build*.

```bash
cd ios
xcodegen generate          # project.yml -> Alltag.xcodeproj
open Alltag.xcodeproj
```

The **Simulator** runs the same `arm64` build on your Mac, fast
and free, with no code signing. It is excellent for development
but it is not a device: it has no real camera, no Secure Enclave,
no cellular, and different performance characteristics. A
physical iPhone requires **code signing** even for a debug build
— covered in *Code Signing and Provisioning, Demystified*.

## You do not own `main()`

A Quarkus app, however thin, ultimately has an entry point the
container calls. On iOS the OS hosts your app the way an app
server hosts your code, but the contract is stricter: **you do
not write `main()`**. The system launches your process, and your
job is to hand it a single type marked `@main` that conforms to
the `App` protocol. That type's `body` describes the window and
the first view. Here is Alltag's actual entry point:

```swift
@main
struct AlltagApp: App {
    @State private var env = AppEnvironment.live()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(env)
        }
    }
}
```

Read it as: build the dependency container once
(`AppEnvironment.live()`), inject it into the SwiftUI
**environment** — the framework's DI mechanism, analogous to a
CDI `BeanManager` you populate at startup — and mount `RootView`
in a window. There is no `psvm`, no servlet, no `@ApplicationScoped`
producer. `@main` is the only entry point, and the framework
drives everything after it.

`RootView` is the concrete shell: a five-tab `TabView` that is
the app's whole top-level navigation.

```swift
struct RootView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var selection: AppTab = .home

    var body: some View {
        TabView(selection: $selection) {
            ForEach(AppTab.allCases) { tab in
                screen(for: tab)
                    .tabItem {
                        Label(tab.titleKey,
                              systemImage: tab.systemImage)
                    }
                    .tag(tab)
            }
        }
        .tint(AppColor.primary)
        .environment(\.locale, env.language.locale)
    }
}
```

The five tabs — **Home · Docs · Decode · Dates · Settings** —
are modeled as a plain `enum AppTab` so the set is testable and
the ordering explicit, with Decode deliberately in the center.
You will dissect views and tabs in *Building Screens: Lists,
Navigation, Forms, Tabs*.

## The big mental shift: one device, offline, no logs

Here is the inversion that matters most for a backend engineer.
Your code no longer runs on a fleet of servers you administer. It
runs on **one device you do not control**, in someone's pocket,
frequently **offline**, with **no server logs** to grep when
something breaks. There is no SSH, no `kubectl exec`, no central
database, no dashboard of your users' state. Distribution is
funneled through a single channel — the **App Store** — and
Apple reviews every release.

**Alltag embodies this by design.** It is a privacy-first
companion for German bureaucracy with **no backend at all**:
documents are stored encrypted on-device, and even the AI runs
locally (an on-device LLM — see the brief). The `AppEnvironment`
container holds persistence, language, theme, and the LLM facade,
and pointedly *no* network service and *no* entitlement service —
it is a **paid app**, unlocked at install, with nothing to phone
home about.

> **Note.** Alltag is a *paid* app: a single upfront App Store
> price, no subscriptions, no in-app purchases, nothing gated at
> runtime. That is a product choice, not a platform requirement —
> but it reinforces the "no backend" posture this book leans on.

This changes engineering priorities you take for granted.
Observability shifts from server logs to opt-in crash reports and
on-device diagnostics. Resilience means surviving with no
network, not retrying a downstream. Security moves from "protect
the server" to "protect data at rest on a possibly-stolen phone"
— hence AES-GCM and the Keychain, in *Persistence: SwiftData,
the Keychain, Files, and CryptoKit*.

## Corrections your mental model needs

- **Native, not bytecode.** No JVM ships with your app; the
  binary is machine code. No write-once-run-anywhere — you build
  per platform.
- **ARC, not GC.** Memory is reclaimed deterministically at the
  last release; cycles still leak.
- **Value types are everywhere.** `struct` and `enum` are copied,
  not shared by reference. Much of the standard library
  (`String`, `Array`, `Int`) is a value type. This is the single
  biggest day-to-day difference from Java; *Types* covers it.
- **One IDE, one build.** Xcode is editor + build + Simulator +
  profiler. You configure, not assemble, the toolchain.
- **You do not own `main()`.** `@main App` is your entry point;
  the OS hosts and drives your process.
- **No backend by default.** State lives on the device. No
  server logs, often offline, App Store is the only door out.
- **DI without a container framework.** SwiftUI's `Environment`
  is the idiomatic injection mechanism; there is no Spring/CDI
  bean graph scanning your classpath.

## Getting started costs nothing

To begin you need exactly one thing: **Xcode**, free from the Mac
App Store. It bundles the Swift compiler, the SDKs, and the
Simulator, so you can build and run Alltag on a simulated iPhone
without an Apple Developer account or any signing setup — the
repo even builds with `CODE_SIGNING_ALLOWED=NO` for exactly this
reason. A paid account and signing enter the picture only when
you target a physical device or ship to the store. The full setup
is in *The Toolchain: Xcode, SPM, XcodeGen, and the Build*.

## Takeaways

- Swift compiles AOT to native code via LLVM; there is no JVM and
  no platform GC — **ARC** reclaims memory deterministically.
- The players map cleanly: Swift vs. Java, SDK frameworks vs.
  JDK, SwiftUI as the UI framework, Xcode as IntelliJ + Maven +
  runtime + profiler in one.
- You do not write `main()`; a single `@main App` is the entry
  point and the OS hosts your process, like an app server hosting
  a JAR but stricter.
- The defining shift: your code runs on one uncontrolled,
  often-offline device with no server logs — Alltag's backend-less,
  on-device, paid design makes that concrete.
- All you need to start is Xcode from the Mac App Store; signing
  is only for devices and the store.

**Next:** *Swift Fundamentals: Values, Optionals, Errors* digs
into the language itself — `let`/`var`, value semantics, and how
optionals and `throws` replace `null` and checked exceptions.
