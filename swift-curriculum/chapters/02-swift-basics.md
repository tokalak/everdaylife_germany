# Swift Fundamentals: Values, Optionals, Errors

Three things in Swift will reshape your reflexes the most:
bindings are immutable by default, types are values that get
copied, and the two things you fight hardest in Java — `null` and
checked exceptions — are replaced by language features that the
compiler enforces. We ground every point in real Alltag code.

## `let` vs `var`, and type inference

`let` is an immutable binding, `var` a mutable one. The
distinction is `final` in Java, except it is the *default* you
reach for and the compiler nudges you toward — declare with `let`
unless you mutate, and Xcode warns when a `var` is never
reassigned.

```swift
let storageKey = "alltag.language"   // immutable
var selection = AppTab.home          // reassignable
```

Types are **inferred** from the initializer, like Java's `var`,
but inference is pervasive and idiomatic, not a last resort.
Annotate when you want the type to be explicit at a boundary or
when there is no initializer:

```swift
let directory: URL                   // type stated, no value yet
private(set) var language: AppLanguage
```

`private(set)` exposes a property for reading but restricts
writes to the declaring type — the equivalent of a public getter
with a private setter, in one keyword. `LanguageStore` uses it so
views can read `language` but only `select(_:)` can change it.

## Fundamental types, and value semantics

`Int`, `Double`, `Bool`, `String` are the everyday types. The
shock for a Java developer: these are **value types**, not
reference types, and there are no primitive/boxed pairs. `Int`
*is* the type — no `int` vs `Integer`, no autoboxing, no `==` vs
`.equals()` trap. `String` is a value type too: assigning or
passing it gives you an independent copy (copy-on-write under the
hood, so it is cheap until mutated).

```swift
var a = "Behörde"
var b = a          // b is a copy
b.append("n")      // mutating b does not touch a
// a == "Behörde", b == "Behörden"
```

This is your **first contact with value vs reference**. In Swift,
`struct` and `enum` are value types (copied on assignment); only
`class` (and actors) are reference types (shared by pointer, ARC
managed). Most of Alltag's small models are values:

```swift
struct FileCryptor { /* ... */ }     // copied
enum AppLanguage: String { case de, en, /* ... */ }
```

while the long-lived, shared services are classes:

```swift
@Observable
final class LanguageStore { /* ... */ }
```

> **Quarkus analogy.** A Swift `struct` behaves like a JPA
> `@Embeddable` or a Java `record` used purely by value: copy it
> and the copies are independent. A `class` behaves like a normal
> entity/bean: a shared identity passed by reference. The default
> in Swift is *value*; in Java it is *reference*. Full treatment
> in *Types: Structs, Enums, Protocols, Generics*.

`final` on a class forbids subclassing (and lets the compiler
devirtualize) — the inverse of Java, where classes are open until
you write `final`. Idiomatic Swift marks classes `final` unless
inheritance is intended.

## Optionals: the `null` problem, solved by the type system

This is the single most important section. Swift has no implicit
`null`. A reference or value type **cannot** be absent unless its
type explicitly permits it, and the compiler refuses to let you
use a possibly-absent value without handling the absence. It is
Java's `Optional<T>`, but woven into the type system rather than
a wrapper class you remember to use.

### Declaration: `T?`

`T?` is sugar for `Optional<T>`, an enum with cases `.some(T)`
and `.none`. A non-optional `String` is *guaranteed* to hold a
string; a `String?` may hold a string or `nil`.

```swift
let raw: String? = defaults.string(forKey: storageKey)
```

`UserDefaults.string(forKey:)` returns `String?` because the key
may be missing — the API encodes "might not be there" in the
type, where a Java API would return `null` and hope you check.

### Optional binding: `if let` / `guard let`

You cannot use a `String?` where a `String` is required; you must
first **unwrap** it. `if let` binds the value to a name inside a
block only when it is non-nil. This is exactly how `LanguageStore`
reads its persisted setting:

```swift
init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    if let raw = defaults.string(forKey: Self.storageKey),
       let stored = AppLanguage(rawValue: raw) {
        language = stored
    } else {
        language = .default
    }
}
```

Two optionals are unwrapped in one `if let`, comma-separated and
short-circuiting: read the stored string, *and* parse it into an
`AppLanguage` (the failable `init(rawValue:)` also returns an
optional). Only if both succeed do we adopt the stored value;
otherwise fall back to `.default`. There is no `null` check, no
NPE-prone path — the `else` branch is mandatory because `language`
must end up non-nil.

`guard let` is the early-exit twin: unwrap, or leave the scope
now. The unwrapped binding stays in scope *after* the `guard`,
which keeps the happy path unindented. `FileCryptor.encrypt` uses
it:

```swift
func encrypt(_ plaintext: Data,
             using key: SymmetricKey) throws -> Data {
    let sealed = try AES.GCM.seal(plaintext, using: key)
    guard let combined = sealed.combined else {
        throw FileCryptorError.sealingFailed
    }
    return combined          // `combined` is non-optional here
}
```

`sealed.combined` is `Data?`; the `guard` converts "nil means
failure" into a thrown error and gives the rest of the function a
plain `Data`. Compare to Java's `Optional.orElseThrow()`, but the
compiler tracks the unwrapped binding afterward.

> **Quarkus analogy.** `Optional<T>` in Java is opt-in and only
> conventionally non-null at the boundary; nothing stops a field
> from being `null`. In Swift, *every* type is non-optional
> unless marked `?`, and the compiler enforces unwrapping. You
> spend far less time defending against `null` because the
> language forbids it by default.

### Nil-coalescing `??`, chaining `?.`, force-unwrap `!`

`??` supplies a default when the optional is nil — Java's
`Optional.orElse`:

```swift
let lang = AppLanguage(rawValue: raw) ?? .default
```

Optional chaining `?.` calls a member only when the receiver is
non-nil, yielding an optional result — Java's `map`/`flatMap`
chain, but as terse punctuation:

```swift
let id: String? = record?.id        // nil if record is nil
let count = record?.id.count ?? 0   // chain + default
```

Force-unwrap `!` asserts "this is not nil" and **traps
(crashes)** if it is — the moral equivalent of `Optional.get()`
on an empty optional, or dereferencing a `null`. Avoid it in
normal flow. It is acceptable only when absence is a genuine
programmer error you want to surface loudly, or for resources you
know exist (a bundled asset). Reach for `if let`/`guard let`/`??`
first.

**Implicitly-unwrapped optionals** (`T!`) are a third form: a
value declared optional but auto-unwrapped on every use, trapping
if nil. They exist mainly for two-phase initialization and legacy
Objective-C interop (Interface Builder outlets). In modern,
`@Observable`, code you will rarely write one — prefer a real
optional or a non-optional initialized in `init`. Treat `T!` as a
smell unless you have a specific interop reason.

## Error handling: `throws`, `try`, `do`/`catch`

Swift errors look like exceptions but follow different rules. A
function that can fail is marked `throws`; a call to it must be
prefixed with `try`; and you handle errors with `do`/`catch`.

```swift
do {
    let bytes = try store.load(id: docID)
    show(bytes)
} catch {
    log("load failed: \(error)")   // `error` is implicit
}
```

`EncryptedFileStore.save` threads `try` through several failable
steps — key retrieval, encryption, the disk write — and lets any
of them propagate:

```swift
@discardableResult
func save(_ data: Data, id: String) throws -> URL {
    let key = try keyStore.symmetricKey()
    let ciphertext = try cryptor.encrypt(data, using: key)
    let url = fileURL(for: id)
    try ciphertext.write(
        to: url, options: [.atomic, .completeFileProtection])
    return url
}
```

`save` is itself `throws`, so it does not catch — it lets the
caller decide. That is the everyday pattern: annotate `throws`,
sprinkle `try`, handle at the boundary that can do something
about it. `@discardableResult` silences the warning you would
otherwise get for ignoring the returned `URL` — the inverse of
Java's `@CheckReturnValue`.

### The `Error` protocol, and untyped throws

Anything thrown conforms to the **`Error`** protocol — usually a
plain `enum`, which models a closed set of failures with zero
ceremony:

```swift
enum FileCryptorError: Error {
    case sealingFailed
}
```

Here is the key delta from Java. A Swift function signature says
*that* it throws, not *what* it throws: pre-Swift 6 `throws` is
**untyped**, with no `throws SomeException` clause and **no
exception-type hierarchy in the signature**. The `catch` site
receives an opaque `Error` you pattern-match or downcast. There
is no checked/unchecked split either — there is one error
channel, and the compiler enforces only that you mark `throws`
and write `try`. (Swift 6 adds opt-in *typed* throws, but the
untyped default remains idiomatic; do not reach for typed throws
reflexively.)

> **Gotcha.** Coming from Java you will hunt for the exception
> type in the signature. It is not there. `func load(id:) throws
> -> Data` tells you it can fail, full stop. Document the failure
> modes in a doc comment; the type system will not. This is
> closer to Java *unchecked* exceptions in information content,
> but *checked* in that `try` and handling are mandatory.

### `try?`, `try!`, and the `live()` fallback

Two variants trade a `do`/`catch` for an expression:

- `try?` turns a throw into `nil`, giving you an optional result
  — "I do not care why it failed, just whether it did."
- `try!` asserts the call will not throw and **traps** if it
  does — the error-handling sibling of force-unwrap.

`AppEnvironment.live()` shows the disciplined use of both a
`do`/`catch` and a `try!` last-resort fallback:

```swift
static func live() -> AppEnvironment {
    let llm = makeLLM()
    do {
        return AppEnvironment(
            persistence: try PersistenceController(), llm: llm)
    } catch {
        assertionFailure(
            "Persistent store unavailable: \(error)")
        return AppEnvironment(
            persistence: try! PersistenceController(
                inMemory: true), llm: llm)
    }
}
```

The on-disk store is attempted with `try`; if it throws, we log
via `assertionFailure` (which traps in debug, no-ops in release)
and fall back to an in-memory store with `try!` — because an
in-memory store realistically cannot fail, and if it somehow did
there is no recoverable app state, so trapping is acceptable.
`try!` is a deliberate, documented assertion here, not laziness.

> **Note.** `assertionFailure` traps in debug builds but is a
> no-op in release — so this code crashes loudly in development
> yet degrades to the in-memory store in production. That is the
> on-device, no-server-logs posture from *The Landscape*: fail
> visibly while building, survive in the user's hands.

### `defer`: guaranteed cleanup

`defer` schedules a block to run when the current scope exits, by
any path — return, thrown error, or fall-through. It is Java's
`finally`, decoupled from a `try` block and placed next to the
resource it cleans up:

```swift
func process(_ url: URL) throws -> Data {
    let handle = try FileHandle(forReadingFrom: url)
    defer { try? handle.close() }   // runs on every exit
    return try handle.readToEnd() ?? Data()
}
```

Multiple `defer`s run in reverse order. Use it for symmetric
cleanup (close, unlock, restore state) so the teardown cannot be
skipped by an early `throw`.

### `Result<Success, Failure>`

`Result` reifies "value or error" as a value you can store and
pass around — the explicit counterpart to `throws`, useful for
async callbacks, caching an outcome, or batching:

```swift
let outcome: Result<Data, Error>
outcome = Result { try store.load(id: docID) }

switch outcome {
case .success(let data): show(data)
case .failure(let error): log("\(error)")
}
```

`Result { ... }` captures a throwing call as a value; `get()`
converts it back, re-throwing. In modern Alltag the throwing
function plus `async`/`await` (next part) covers most cases, so
reach for `Result` when you specifically need the outcome as
data rather than control flow.

## Takeaways

- `let`/`var` are immutable/mutable bindings; prefer `let`. Type
  inference is pervasive; `private(set)` gives read-public,
  write-private in one keyword.
- `Int`/`Double`/`Bool`/`String` are **value types** — no
  boxing, no primitive/object split. `struct`/`enum` copy;
  `class`/actor share by reference.
- Optionals replace `null`: `T?` must be unwrapped via `if let` /
  `guard let`, defaulted with `??`, or chained with `?.`. Avoid
  `!` and `T!` outside genuine programmer-error and interop cases.
- Errors use `throws`/`try`/`do`-`catch`; `throws` is untyped
  (no exception class in the signature, no checked/unchecked
  split), but `try` and handling are compiler-enforced.
- `try?` yields nil on failure, `try!` traps; `defer` is a
  scope-local `finally`; `Result` turns success-or-error into a
  storable value.

**Next:** *Types: Structs, Enums, Protocols, Generics* expands
value vs reference into the full type system — how `struct`,
`enum`, protocols, and generics replace classes-and-interfaces as
your primary modeling tools.
