# Testing: Swift Testing, XCTest, Previews, and CI

You arrive with JUnit 5 muscle memory: `@Test`, `assertEquals`,
`@ParameterizedTest`, `@BeforeEach`, Mockito for fakes, and a CI job
that runs `mvn verify`. Swift has two test frameworks. The modern
one, **Swift Testing**, will feel like JUnit 5 redesigned for
Swift's value types and async. The older one, **XCTest**, is the
JUnit-4-era workhorse — and it is what **Alltag uses today**. This
chapter leads with the new framework, maps both onto JUnit, converts
a real Alltag test suite line by line, shows how the app injects
fakes for tests, and ends by walking the project's actual local CI
script.

## Swift Testing: the modern framework

Swift Testing ships with the toolchain. You import it, mark
functions with a macro, and assert with `#expect`. The shape mirrors
JUnit 5 closely.

```swift
import Testing

@Test func twoPlusTwo() {
    #expect(2 + 2 == 4)
}
```

`@Test` is `@Test`. `#expect(...)` is the universal assertion — but
note the design: instead of a wall of `assertEquals`,
`assertTrue`, `assertNull`, you write **one** macro around an
ordinary boolean expression. Because `#expect` is a macro, it
decomposes the expression at compile time and, on failure, prints
the operands — `#expect(x == 4)` failing reports the actual value
of `x`, no message needed. That subsumes most of JUnit's assertion
zoo.

| JUnit 5                       | Swift Testing               |
|-------------------------------|-----------------------------|
| `@Test`                       | `@Test`                     |
| `assertEquals(a, b)`          | `#expect(a == b)`           |
| `assertTrue(c)`               | `#expect(c)`                |
| `assertThrows(E, () -> …)`    | `#expect(throws: E.self)`   |
| `assertNotNull(x)` then use   | `try #require(x)`           |
| `@ParameterizedTest`          | `@Test(arguments:)`         |

### `#require`: assert-and-unwrap

`#require` is `#expect`'s strict sibling: it throws and **stops the
test** if its condition fails, and when given an optional it
*unwraps* it. This is the idiom for preconditions — the test cannot
sensibly continue if this is false:

```swift
@Test func decodesHeader() throws {
    let value = try #require(parse(input))  // unwrap or fail
    #expect(value.amount == 90)
}
```

`try #require(optional)` is JUnit's `assertNotNull` followed by a
non-null cast, collapsed into one step that also short-circuits.

### Parameterized tests

JUnit's `@ParameterizedTest` with `@ValueSource`/`@MethodSource`
becomes `@Test(arguments:)`. The runtime expands one case per
argument, each reported independently:

```swift
@Test(arguments: ["de", "en", "tr"])
func languageCodeIsTwoLetters(code: String) {
    #expect(code.count == 2)
}
```

You can zip two argument collections, or pass tuples, the way you
would feed a `@MethodSource` a stream of argument sets.

### Suites, traits, async, throwing

Tests are grouped into **suites**, which are plain Swift types —
idiomatically a `struct`. This is a real departure from JUnit and
from XCTest: because a `struct` is a value type, the runtime creates
**a fresh instance per test**, so stored properties initialized in
`init` are automatically isolated between tests. There is no shared
mutable instance to leak state — `init` *is* your `@BeforeEach`,
and `deinit` (on a `final class` suite) is `@AfterEach`.

```swift
struct CryptorTests {
    let cryptor = FileCryptor()        // fresh per test
    let key = SymmetricKey(size: .bits256)

    @Test func roundTrips() throws {
        let blob = Data("hello".utf8)
        let out = try cryptor.encrypt(blob, using: key)
        #expect(try cryptor.decrypt(out, using: key) == blob)
    }
}
```

**Traits** are metadata/behaviour attached to a test or suite, the
analogue of JUnit's `@DisplayName`, `@Disabled`, `@Tag`, and
`@Timeout` rolled into one mechanism:

```swift
@Test("wrong key is rejected", .disabled("flaky on CI"))
func wrongKeyFails() throws { /* … */ }

@Suite(.tags(.crypto))
struct VaultCryptoTests { /* … */ }
```

Tests are first-class **async/throws**. A test may be `async` and
the runner awaits it; a test may `throw` and an uncaught error fails
it — so the happy path of "this must not throw" needs no assertion
at all, just `throws` on the signature. That is strictly nicer than
JUnit, where you either declare `throws` and let the exception fail
the test or wrap in `assertDoesNotThrow`.

> **Quarkus analogy.** Swift Testing is JUnit 5 reimagined for
> value types: `struct` suites give you per-test isolation for free
> (fresh instance each run), `#expect` collapses the assertion zoo
> into one macro that prints operands, and `async`/`throws` are
> native to a test the way `@Test` methods can `throws` in JUnit.

## XCTest: the incumbent (what Alltag uses)

XCTest is the JUnit-4-shaped framework: subclass a base, name
methods `test…`, assert with a family of free functions, override
lifecycle hooks. Every Alltag test today is XCTest, so this is what
you will read and write first in this codebase.

| JUnit                         | XCTest                         |
|-------------------------------|--------------------------------|
| class `extends` (implicit)    | `final class T: XCTestCase`    |
| `@Test` (method `testFoo`)    | `func testFoo()` (name prefix) |
| `assertEquals(a, b)`          | `XCTAssertEqual(a, b)`         |
| `assertTrue` / `assertFalse`  | `XCTAssertTrue` / `…False`     |
| `assertThrows`                | `XCTAssertThrowsError`         |
| `@BeforeEach` / `@AfterEach`  | `setUp` / `tearDown`           |
| `Assumptions.assumeTrue`      | `XCTSkip`                      |

Key mechanical differences from JUnit and from Swift Testing:

- **Tests are discovered by the `test` prefix**, not an annotation.
  A method named `testX` runs; rename it and it silently stops
  running — a classic footgun.
- **The suite is a `class`** (must be `final class … :
  XCTestCase`), and unlike Swift Testing's `struct` suites, the
  instance is reused with explicit `setUp`/`tearDown` resetting
  state — exactly JUnit 4's model.
- **Throwing tests** just add `throws`; an uncaught error fails the
  test. `XCTAssertThrowsError(try expr)` asserts the *opposite* —
  that the expression *does* throw.
- **`setUpWithError`/`tearDownWithError`** are the throwing variants
  of the lifecycle hooks.
- **`XCTSkip`** throws a skip (JUnit's assumption), used when an
  environment can't support a test — as we saw with the Keychain in
  the unsigned Simulator.

## Worked conversion: `FileCryptorTests`, both ways

Alltag's `FileCryptor` encrypts a blob under a `SymmetricKey` with
authenticated encryption. Its real test suite asserts four things:
a round-trip recovers the plaintext, a wrong key fails, a tampered
ciphertext fails authentication, and empty data round-trips. Here is
the **real XCTest source**, verbatim from
`ios/Tests/AlltagTests/Persistence/FileCryptorTests.swift`:

```swift
import CryptoKit
import XCTest
@testable import Alltag

/// A-09: blob encryption is a round-trip and authenticated.
final class FileCryptorTests: XCTestCase {
    private let cryptor = FileCryptor()
    private let key = SymmetricKey(size: .bits256)

    func testEncryptThenDecryptRecoversPlaintext() throws {
        let plaintext = Data(
            "Behörden-Brief: Bitte zahlen Sie 90 €.".utf8)
        let ciphertext = try cryptor.encrypt(
            plaintext, using: key)
        XCTAssertNotEqual(ciphertext, plaintext,
            "ciphertext must not equal plaintext")
        let recovered = try cryptor.decrypt(
            ciphertext, using: key)
        XCTAssertEqual(recovered, plaintext)
    }

    func testDecryptWithWrongKeyFails() throws {
        let ciphertext = try cryptor.encrypt(
            Data("secret".utf8), using: key)
        let otherKey = SymmetricKey(size: .bits256)
        XCTAssertThrowsError(
            try cryptor.decrypt(ciphertext, using: otherKey))
    }

    func testTamperedCiphertextFailsAuthentication()
        throws {
        var ciphertext = try cryptor.encrypt(
            Data("secret".utf8), using: key)
        ciphertext[ciphertext.count - 1] ^= 0xFF // flip tag
        XCTAssertThrowsError(
            try cryptor.decrypt(ciphertext, using: key))
    }

    func testEmptyDataRoundTrips() throws {
        let ciphertext = try cryptor.encrypt(
            Data(), using: key)
        XCTAssertEqual(
            try cryptor.decrypt(ciphertext, using: key),
            Data())
    }
}
```

Note the patterns: every test is `throws` (so a `try` that throws
unexpectedly fails it), the happy-path assertions use
`XCTAssertEqual`/`XCTAssertNotEqual`, and the two negative tests use
`XCTAssertThrowsError` to assert that decryption *rejects* bad
input. The `cryptor` and `key` are stored properties — but because
XCTest reuses the class instance, they are shared; here that is safe
because neither is mutated.

Now the **same suite rewritten in Swift Testing**:

```swift
import CryptoKit
import Testing
@testable import Alltag

/// A-09: blob encryption is a round-trip and authenticated.
struct FileCryptorTests {
    let cryptor = FileCryptor()
    let key = SymmetricKey(size: .bits256)

    @Test func encryptThenDecryptRecoversPlaintext()
        throws {
        let plaintext = Data(
            "Behörden-Brief: Bitte zahlen Sie 90 €.".utf8)
        let ciphertext = try cryptor.encrypt(
            plaintext, using: key)
        #expect(ciphertext != plaintext)
        #expect(
            try cryptor.decrypt(ciphertext, using: key)
                == plaintext)
    }

    @Test func decryptWithWrongKeyFails() throws {
        let ciphertext = try cryptor.encrypt(
            Data("secret".utf8), using: key)
        let otherKey = SymmetricKey(size: .bits256)
        #expect(throws: (any Error).self) {
            try cryptor.decrypt(ciphertext, using: otherKey)
        }
    }

    @Test func tamperedCiphertextFailsAuthentication()
        throws {
        var ciphertext = try cryptor.encrypt(
            Data("secret".utf8), using: key)
        ciphertext[ciphertext.count - 1] ^= 0xFF
        #expect(throws: (any Error).self) {
            try cryptor.decrypt(ciphertext, using: key)
        }
    }

    @Test func emptyDataRoundTrips() throws {
        let ciphertext = try cryptor.encrypt(
            Data(), using: key)
        #expect(
            try cryptor.decrypt(ciphertext, using: key)
                == Data())
    }
}
```

What changed, point by point:

- `import XCTest` → `import Testing`.
- `final class … : XCTestCase` → `struct` (a value type;
  fresh per test).
- `func testX` → `@Test func x` — discovery by attribute, not
  by name prefix, so the `test` prefix is dropped.
- `XCTAssertEqual(a, b)` / `XCTAssertNotEqual` → `#expect(a == b)`
  / `#expect(a != b)`.
- `XCTAssertThrowsError(try expr)` → `#expect(throws: …) { try
  expr }`. (You can name a concrete error type instead of `(any
  Error).self` to assert *which* error is thrown — stricter than
  the XCTest form.)
- The explanatory failure messages mostly vanish, because `#expect`
  prints the operands itself.

Both express the identical contract; the Swift Testing version is
shorter and its `struct` isolation removes any worry about shared
state across the four tests.

## Injecting fakes for tests

Alltag avoids a mocking framework (no Mockito equivalent in play) by
designing for **constructor injection** and providing hand-written
in-memory fakes — protocol-conforming test doubles. Three patterns
recur across the suite.

**1. In-memory key store.** `EncryptedFileStore` takes a `keyStore`
in its initializer; tests pass `InMemoryKeyStore()` instead of the
real Keychain-backed one, so persistence tests run without
entitlements:

```swift
private let keyStore = InMemoryKeyStore()
// …
store = try EncryptedFileStore(
    directory: directory, keyStore: keyStore)
```

The same suite uses a fresh `InMemoryKeyStore()` to *simulate a
different device* — proving a foreign key cannot decrypt another
store's blob:

```swift
let foreign = try EncryptedFileStore(
    directory: directory, keyStore: InMemoryKeyStore())
XCTAssertThrowsError(try foreign.load(id: id))
```

**2. In-memory persistence.** The SwiftData stack accepts an
`inMemory` flag — an ephemeral store with no disk, the analogue of
an H2 in-memory database for a fast test. `AppEnvironmentTests`
builds the whole DI container against it:

```swift
let env = AppEnvironment(
    persistence: try PersistenceController(inMemory: true),
    llm: try LLMTestFactory.service())
XCTAssertEqual(env.language.language, .de)
```

**3. Isolated `UserDefaults` suite.** `LanguageStore` reads/writes
`UserDefaults`; injecting them lets each test run against a
**throwaway suite** keyed by a UUID, created in `setUp` and wiped in
`tearDown` — so no test pollutes global app preferences:

```swift
override func setUp() {
    super.setUp()
    suiteName = "alltag.tests.\(UUID().uuidString)"
    defaults = UserDefaults(suiteName: suiteName)
}

override func tearDown() {
    defaults.removePersistentDomain(forName: suiteName)
    super.tearDown()
}
```

> **Note.** The lesson for a Java engineer: Swift apps lean on
> protocols + constructor injection rather than runtime mocking.
> You design the seam (a `keyStore` parameter, an `inMemory` flag,
> an injected `UserDefaults`) and hand-write the fake. It is more
> code than `@Mock`, but the doubles are explicit and type-checked.

Note that `LanguageStoreTests` and `AppEnvironmentTests` are
annotated `@MainActor`: they touch UI-bound, main-actor-isolated
state, so the whole test class is pinned to the main actor — a
concurrency constraint with no JUnit analogue.

## UI tests with XCUITest

Beyond unit tests, **XCUITest** drives the app as a black box —
launching it, finding elements by accessibility identifier, tapping
and asserting on screen — the rough analogue of Selenium/Playwright
for a web app. It runs in a separate UI-test target and is far
slower than a unit test. Alltag's foundation phase carries unit
tests and a smoke test rather than a UI suite; the model, when
added, is `app.buttons["save"].tap()` then assert a label exists.

## Previews: the fast inner loop

SwiftUI **previews** are the closest thing to hot reload. A
`#Preview` block renders a view live in Xcode's canvas without
building and launching the whole app on a simulator — you edit the
view body and the canvas updates in place. Alltag's `RootView`
declares one:

```swift
#Preview {
    RootView()
        .environment(AppEnvironment.live())
}
```

This is your tightest feedback loop for UI work — seconds, not a
full rebuild-and-launch cycle. It complements, rather than replaces,
tests: previews check *appearance* by eye; tests check *behaviour*
deterministically. (A handy trick: you can pass a preview an
`inMemory` environment with seeded fakes, exactly as the tests do,
to render specific states.)

## Code coverage

Coverage is configured **on the scheme**, not via a separate plugin
like JaCoCo. Recall from Chapter 11 that `project.yml`'s scheme
sets `gatherCoverageData: true`; XcodeGen writes that into the
generated scheme as `codeCoverageEnabled = "YES"` under the
`TestAction`. When `xcodebuild test` runs, the toolchain emits
coverage profiles into the result bundle, viewable in Xcode's report
navigator or extractable on the CLI with `xcrun xccov`. No extra
dependency, no separate report goal — it is a property of the test
action.

## CI: the real `ios/scripts/ci.sh`

Alltag's CI is **local and on-demand** — there is no cloud runner.
The script `ios/scripts/ci.sh` mirrors exactly what a CI runner
would do, in four steps:

1. **Print the toolchain** (`xcodebuild -version`, `swift
   --version`) for a reproducible log.
2. **Regenerate the project** with `xcodegen generate` (failing
   loudly if `xcodegen` isn't installed) — because the `.xcodeproj`
   is git-ignored, CI *must* generate it first.
3. **Pick a simulator dynamically.** Rather than hard-code a device
   name that varies by machine and Xcode version, it queries
   `simctl` for available iPhone simulators and takes the newest:

   ```bash
   UDID=$(xcrun simctl list devices available --json \
     | python3 -c "import json,sys; \
       ds=json.load(sys.stdin)['devices']; \
       cands=[d for rt in ds for d in ds[rt] \
         if d['isAvailable'] and 'iPhone' in d['name']]; \
       print(cands[-1]['udid'] if cands else '')")
   ```

4. **Build and test**, with signing disabled:

   ```bash
   xcodebuild test \
     -project "$PROJECT" \
     -scheme "$SCHEME" \
     -destination "platform=iOS Simulator,id=$UDID" \
     CODE_SIGNING_ALLOWED=NO
   ```

   (If `xcbeautify` is installed it pipes through it for readable
   output; otherwise it runs raw.) `set -euo pipefail` at the top
   makes any failed step abort the run with a non-zero exit — the
   pass/fail signal a CI gate needs.

### Why local CI here

The driving reason is **signing**. As Chapter 11 covered, Alltag
defers code signing entirely (`CODE_SIGNING_ALLOWED=NO`), which is
only possible because it builds and tests on the **Simulator**, not
a device. A Simulator build needs **no Apple Developer account, no
certificate, no provisioning profile**. That removes the single
biggest reason teams need cloud CI infrastructure early — there are
no secrets to inject. So the full pipeline (regenerate → pick
simulator → build → test) runs identically on any developer's Mac
with a single command, with nothing to configure.

### What cloud CI would add later

A hosted runner — **GitHub Actions** on a macOS image, or Apple's
**Xcode Cloud** — would layer on top of the same `xcodebuild test`
core and add: running on every push/PR as a merge gate; a clean,
reproducible build environment; archiving and **signed** builds for
TestFlight/App Store distribution (which *do* need a Developer
account, certificates, and provisioning — Chapter 13); and
historical coverage/test-result dashboards. None of that is needed
to validate the on-device, paid, no-backend app during early
development — which is exactly why Alltag ships a script, not a
pipeline.

## Takeaways

- **Swift Testing** is JUnit-5-shaped and modern: `@Test`,
  `#expect` (one macro, prints operands), `try #require` (unwrap +
  assert), `@Test(arguments:)` for parameterization, `struct` suites
  with per-test isolation, native `async`/`throws`, and traits for
  `@Disabled`/`@Tag`/`@Timeout`.
- **XCTest** is the JUnit-4-shaped incumbent and **what Alltag uses
  today**: `final class … : XCTestCase`, `test`-prefixed methods,
  `XCTAssert*`, `setUp`/`tearDown`, `XCTAssertThrowsError`,
  `XCTSkip`.
- The real `FileCryptorTests` converts cleanly: `XCTAssertEqual` →
  `#expect(==)`, `XCTAssertThrowsError` → `#expect(throws:)`,
  class → `struct`, name-prefix → `@Test`.
- Test seams are **protocols + constructor injection**, not mocking:
  `InMemoryKeyStore`, `PersistenceController(inMemory: true)`, and
  per-test `UserDefaults` suites.
- **Previews** (`#Preview`) are the hot-reload-style inner loop;
  **coverage** is a scheme setting (`gatherCoverageData`), not a
  plugin.
- CI is **local** (`ios/scripts/ci.sh`) because deferred signing +
  Simulator means no Apple account or secrets are required; cloud CI
  adds merge gates and signed distribution later.

**Next:** *Code Signing and Provisioning, Demystified*
