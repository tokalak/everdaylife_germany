# A Study Plan

A book is inert without a schedule. This appendix turns the chapters into an
8-week, part-time curriculum — roughly 5-7 hours per week, the kind of load you
can sustain in evenings and on weekends without burning out. It assumes you are
employed full-time as a backend engineer and learning on the side.

The structure is deliberate: **read a little, build a lot.** Each week pairs
reading with a concrete, small deliverable in a throwaway practice app, plus
optional reinforcement against the real *Alltag* codebase, which you already
have on disk. You learn Swift by writing Swift, not by reading about it.

## Before week 1: setup (about an hour)

- Install **Xcode** from the Mac App Store (it is large — start the download
  the night before).
- Open Xcode once, let it install the additional components, and accept the
  licence (`sudo xcodebuild -license accept` if it nags from the CLI).
- `brew install xcodegen xcbeautify` — the two tools *Alltag* uses.
- Clone/open the Alltag project: `cd ios && xcodegen generate && open
  Alltag.xcodeproj`, then press the **Run** button (the simulator boots).
- Create a scratch project: **File > New > Project > iOS App**, interface
  *SwiftUI*. This is your sandbox for the exercises below.

> **Note.** Do not try to be productive in week 1. The goal is a working
> toolchain and the muscle memory of build-run-iterate. Everything else builds
> on that loop.

## The eight weeks

### Week 1 — Orientation and the language floor

- **Read:** *The Landscape: from JVM to iOS*, *Swift Fundamentals: Values,
  Optionals, Errors*.
- **Build:** in your scratch app, write a plain Swift file with a handful of
  functions that take optionals and `throws`, and call them from a test. Force
  yourself to use `guard let`, `if let`, `??`, and a `do`/`catch`.
- **Reinforce:** open Alltag's `FileCryptor.swift` and `AppEnvironment.swift`
  and trace every `try`, `guard`, and optional. You have read these in the
  book; now read them cold.
- **Milestone:** you can explain, out loud, why `let env = AppEnvironment.live()`
  cannot throw but the initializer it calls can.

### Week 2 — The type system

- **Read:** *Types: Structs, Enums, Protocols, Generics*.
- **Build:** model a tiny domain you know (say, an invoice) three ways — as a
  `struct`, with an `enum` for its status (with associated values for, e.g.,
  `.refunded(amount:)`), and behind a `protocol` with two conforming types.
- **Reinforce:** re-implement Alltag's `AppLanguage` enum from memory, then
  diff against the real file. Note every computed property you forgot.
- **Milestone:** you reach for `struct` by default and can articulate when you
  would deliberately choose a `class`.

### Week 3 — Functions, closures, and concurrency

- **Read:** *Functions, Closures, and Functional Style*, *Memory and
  Concurrency: ARC, async/await, Actors*.
- **Build:** write an `async` function that fetches from a public JSON API with
  `URLSession`, decode it with `Codable`, and call it from a `Task` in a button
  action. Add a `TaskGroup` that fetches three things in parallel.
- **Reinforce:** find every `@MainActor` and `Sendable` in Alltag and explain
  why each is there. Turn on **strict concurrency** in your scratch app
  (`SWIFT_STRICT_CONCURRENCY = complete`) and fix the warnings.
- **Milestone:** you no longer reach for completion handlers, and a data-race
  warning reads as a helpful compiler message rather than noise.

### Week 4 — SwiftUI: the mental model

- **Read:** *The SwiftUI Model: Declarative Views and State*, *Layout: Stacks,
  Modifiers, and the Layout System*.
- **Build:** a single screen with `@State`, a `Toggle`, a `TextField`, and a
  computed result that updates live. Deliberately break it by mutating state
  from the wrong place, and watch what the compiler says.
- **Reinforce:** add a `#Preview` to one of Alltag's placeholder views and
  iterate on padding/colour using the canvas, without ever launching the
  simulator.
- **Milestone:** you can predict what re-renders when a given `@State` changes.

### Week 5 — SwiftUI: real screens

- **Read:** *Building Screens: Lists, Navigation, Forms, Tabs*.
- **Build:** a two-tab app with a `NavigationStack`, a `List` of `Identifiable`
  items you can tap into a detail screen, and a `Form`-based settings tab with a
  `Picker`. Add `.swipeActions` to delete a row.
- **Reinforce:** read Alltag's `RootView` and `AppTab`; then rebuild the Settings
  screen exercise from that chapter against the real `ThemeController` and
  `LanguageStore`.
- **Milestone:** you can assemble a multi-screen navigable app from memory.

### Week 6 — Architecture and persistence

- **Read:** *Architecture: State, Dependencies, and the @Observable
  Environment*, *Persistence: SwiftData, the Keychain, Files, and CryptoKit*.
- **Build:** give your practice app an `@Observable` environment container
  injected at the root (mirroring `AppEnvironment`), and a `@Model` entity
  persisted with SwiftData, listed via `@Query`. Add, edit, and delete records.
- **Reinforce:** this is the week to read Alltag's whole `Core/Persistence`
  folder end to end — `PersistenceController`, `DocumentRecord`,
  `EncryptedFileStore`, `FileCryptor`, `KeyStore` — and trace one document from
  bytes to encrypted file to metadata row.
- **Milestone:** you could add a new `@Model` entity to Alltag and wire it
  through the environment yourself.

### Week 7 — The toolchain and tests

- **Read:** *The Toolchain: Xcode, SPM, XcodeGen, and the Build*, *Testing:
  Swift Testing, XCTest, Previews, and CI*.
- **Build:** add a Swift Testing target to your practice app and port a couple
  of XCTest cases to `@Test`/`#expect`. Inject a fake via a protocol.
- **Reinforce:** run Alltag's `ios/scripts/ci.sh` locally and read what it does
  line by line. Add one new test to the suite and watch it run.
- **Milestone:** you can add a dependency with SPM, regenerate the project with
  XcodeGen, and run the full test suite from the command line.

### Week 8 — Shipping

- **Read:** *Code Signing and Provisioning, Demystified*, *Distribution: App
  Store Connect, TestFlight, and Review*, *Production: Privacy, Crashes,
  Performance, and Updates*.
- **Build:** enrol in the Apple Developer Program (or use free provisioning),
  flip Alltag's signing settings as described, and run it **on your own iPhone**.
  Then archive a Release build and push it to TestFlight for yourself.
- **Milestone:** an app you built is running on your phone from TestFlight. You
  are now, by any practical definition, an iOS developer.

## A faster track

If you can give it full days rather than evenings, compress the above into
**two weeks**: Part I in days 1-3, Part II in days 4-7, Part III in days 8-10,
with the rest of each block spent building. The ordering still holds — do not
skip the concurrency or persistence weeks, because they are where a backend
engineer's instincts are most often subtly wrong.

## A capstone worth doing

When the eight weeks are done, build one small, complete app of your own from a
blank project to TestFlight: a single feature, persisted locally, tested, and
signed. Nothing teaches the gaps in your knowledge like the unglamorous last
10% — an app icon, a launch screen, a privacy manifest, a rejected build, a
resubmission. That last 10% is the whole point of Part III, and the reason this
book exists.

## Takeaways

- Read a little, build a lot — eight weeks at 5-7 hours each is enough to ship.
- Each week pairs a practice deliverable with a read of the real Alltag code.
- The concurrency and persistence weeks are where backend intuition misleads
  you most; do not rush them.
- The capstone — blank project to TestFlight — is where the learning compounds.

**Next:** the resources worth your time when this book runs out — see *Curated
Resources*.
