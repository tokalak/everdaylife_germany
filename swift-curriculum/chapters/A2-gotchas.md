# Idioms and Gotchas for Java Developers

A scannable catalogue of traps that specifically catch engineers
coming from Java/Quarkus. Each item: the trap, why it bites, and the
fix. Skim it once now; return to it when something compiles but
behaves wrong.

### Structs are values, not references

The biggest mental shift. A `struct` is *copied* on assignment and
on every parameter pass. Mutating the copy does not touch the
original — there is no shared object, no aliasing.

```swift
var a = Point(x: 1)
var b = a        // copy
b.x = 9          // a.x is still 1
```

Coming from Java, where everything but primitives is a reference,
this surprises you constantly. `class` gives you Java-like reference
semantics; `struct` (the default for models) does not.

### Mutating a struct inside a collection/loop

Because structs are values, `for item in array { item.x = 1 }` does
nothing useful — `item` is a *copy*. To mutate in place, index back
into the storage:

```swift
for i in array.indices { array[i].x = 1 }
```

A `for-each` loop variable over a value-type array is read-only by
design; this catches everyone once.

### Optionals are not `null`

`String?` is a distinct *type*, not a nullable reference. You cannot
call methods on it directly, and there is no silent
`NullPointerException` — the compiler forces you to unwrap. Do **not**
force-unwrap with `!`; that is a deliberate crash.

```swift
guard let name = maybeName else { return }
// name is a non-optional String here
```

Prefer `guard let`, `if let`, or `??`. Reserve `!` for genuine
"impossible to be nil" invariants — it is the Swift equivalent of
`throw new AssertionError()`.

### `==` vs `===`

In Java `==` is identity and `.equals()` is value. In Swift it is
reversed: `==` is **value** equality (`Equatable`), and `===` is
**reference identity** (class instances only).

```swift
a == b    // values equal? (Equatable)
a === b   // same object? (classes only)
```

`===` does not even compile for structs — they have no identity.

### `throws` has no exception type list

Swift errors are untyped at the signature: a function is just
`throws`, with no `throws IOException, SQLException` list. There are
no checked-vs-unchecked categories. You `catch` and switch on the
concrete error type at the call site.

```swift
do { try decode() }
catch let e as LLMError { handle(e) }
catch { fallback() }
```

You lose compiler-enforced exception contracts; you gain less
ceremony. (Swift 6 adds opt-in *typed* throws, rarely needed.)

### `String` is not `Int`-indexable

`s[0]` does not compile. A Swift `String` is a sequence of
*grapheme clusters* (user-perceived characters), not fixed-width
chars, so you use `String.Index`, not integers.

```swift
let first = s[s.startIndex]
let third = s.index(s.startIndex, offsetBy: 2)
```

This protects you from breaking emoji and combined characters — but
it means Java-style `charAt(i)` loops must be rewritten.

### Trailing-closure syntax

When the last argument is a closure, it moves outside the
parentheses. This is why SwiftUI looks the way it does, and why a
method call can look like a language construct.

```swift
items.map { $0 * 2 }          // map(transform:)
Button("Save") { save() }     // trailing closure
```

`$0` is the first implicit argument. Multiple trailing closures use
labels: `Button { ... } label: { ... }`.

### `self` capture and retain cycles

Closures capture `self` *strongly* by default. A long-lived closure
that captures `self`, stored on an object that owns the closure,
creates a retain cycle — ARC never frees it (a leak). Break it with
a capture list.

```swift
task = Task { [weak self] in
    await self?.load()
}
```

There is no tracing GC to clean this up; ARC is deterministic
reference counting, so cycles leak permanently. Reach for
`[weak self]` in stored, escaping closures.

### `@MainActor` and the UI thread

All UI work must be on the main actor. Touching `@Published` state
or a view from a background context is undefined behavior. Mark UI
types `@MainActor`; hop with `await MainActor.run { ... }`.

```swift
@MainActor final class VM: ObservableObject { /* ... */ }
```

Like Swing's EDT, but compiler-enforced. The flip side: do **not**
do heavy work (crypto, the on-device LLM) on `@MainActor` — push it
off, then hop back to assign results.

### Struct mutation needs `var` + `mutating`

A method that changes a struct's own stored properties must be
marked `mutating`, and you can only call it on a `var`. A `let`
struct is *deeply* immutable.

```swift
struct Counter { var n = 0
    mutating func bump() { n += 1 } }
let c = Counter(); // c.bump()  ✗ won't compile
```

`final`-by-value: think Java `record` that can declare in-place
mutators.

### Protocols with associated types can't be plain existentials

A protocol with an `associatedtype` (or `Self` requirements) — the
Swift analog of `interface Repo<T>` — cannot be used as a bare
variable type the way a Java generic interface can.

```swift
func first<C: Collection>(_ c: C) -> C.Element? // ✓
let xs: any Collection = []   // limited
let xs: some Collection = [1] // opaque, one type
```

Use a generic constraint, `some` (opaque, one concrete type), or
`any` (boxed existential, with limits). This is the error
`...can only be used as a generic constraint`.

### `Array`/`Dictionary` are value types (copy-on-write)

Collections are structs: assigning or passing one is logically a
copy. Swift optimizes this with **copy-on-write** — the buffer is
shared until you mutate, then it clones. Cheap to pass, but no
shared mutation across references.

```swift
var a = [1, 2]; var b = a
b.append(3)   // a is still [1, 2]
```

No `Collections.unmodifiableList` needed — immutability is the
default via `let`.

### Compiler-synthesized memberwise init

A `struct` gets a free `init` covering all stored properties — no
Lombok, no constructor boilerplate.

```swift
struct Letter { let title: String; let date: Date }
let l = Letter(title: "Bescheid", date: .now)
```

Caveat: define *any* custom `init` and you lose the synthesized one
(put yours in an `extension` to keep both). Classes get no memberwise
init.

### `switch` must be exhaustive

A `switch` must cover every case or include `default`; a non-
exhaustive switch does not compile. Over an `enum` with no
`default`, adding a case turns *every* switch into a compile error —
which is a feature: the compiler lists what to update.

```swift
switch severity {
case .info: ...
case .urgent: ...
}   // ✗ if .legal exists and isn't handled
```

### No implicit numeric conversion

`Int` and `Double` do not auto-promote. `let x: Double = anInt`
fails; you must convert explicitly. There is no `1 + 1.0` for free.

```swift
let d = Double(count) / 2.0
```

Tedious at first, but it kills a whole class of silent integer/float
bugs. Same for `Int8`/`Int`/`UInt` — all explicit.

### `enum` is far more than a Java enum

A Swift `enum` can carry **associated values** per case — it is a
sum type / sealed hierarchy, not just a named constant set.

```swift
enum Decode {
    case pending
    case done(summary: String, deadline: Date?)
    case failed(LLMError)
}
```

This is your `sealed interface` + records, but lighter. Combined
with exhaustive `switch`, it models state machines cleanly.

### Access control defaults to `internal`

No modifier means `internal` — visible across the whole **module**,
not package-private. A module is a *build target* (the app, a Swift
package), not a folder. Levels: `private` < `fileprivate` <
`internal` < `public` < `open`. There is no `protected`.

```swift
struct API { func go() {} }   // internal by default
public struct Lib { /* ... */ }
```

`public` exposes across modules but does not allow subclassing/
overriding from outside — that needs `open`.

### `guard` for early return

`guard` is "assert-or-leave": its `else` branch *must* exit scope
(`return`/`throw`/`break`). It keeps the happy path unindented and
binds unwrapped values into the *enclosing* scope.

```swift
guard let url = makeURL() else { return }
use(url)   // url in scope, non-optional
```

Prefer it over a pyramid of `if let`.

### `lazy` and computed properties

`lazy var` defers initialization until first access (handy for the
expensive model handle). A computed property (`var x: T { ... }`)
runs code on every read — no stored backing, like a getter.

```swift
lazy var engine = LlamaEngine()       // built once, on use
var isReady: Bool { engine.loaded }   // recomputed each read
```

`lazy` is not thread-safe; `lazy` requires `var`.

### `Codable` vs Jackson

JSON mapping is compiler-synthesized from the type — **no
annotations**, no `ObjectMapper` bean. Conform to `Codable` and it
just works; customize key names with a `CodingKeys` enum.

```swift
struct Letter: Codable {
    let title: String
    enum CodingKeys: String, CodingKey {
        case title = "betreff"
    }
}
```

No reflection at runtime; encoding/decoding is generated at compile
time.

### Naming conventions

Methods and properties are `lowerCamelCase`; types and protocols are
`UpperCamelCase`. There are **no `get`/`set` prefixes** — a property
*is* the accessor. Booleans read as questions (`isReady`,
`hasDeadline`). Argument labels are part of the method name:
`move(from:to:)`.

```swift
let isReady = doc.hasDeadline   // not getHasDeadline()
```

Enum cases are `lowerCamelCase` too (`.info`, not `.INFO`).

### `import` pulls a whole module

`import SwiftUI` brings in the *entire* module — there is no per-type
import like `import java.util.List`. You do not (and cannot) import
individual symbols normally; the module namespace is flat once
imported.

```swift
import SwiftData   // all of it, not one class
```

Fewer import lines, but name collisions across modules are resolved
by qualifying (`SwiftUI.Path` vs `CoreGraphics`-era types).

## Takeaways

- Value vs reference is the root of most surprises: structs and
  collections copy; only `class` aliases.
- Optionals replace `null` safely — `guard let`, never `!`; `==` is
  value, `===` is identity.
- Errors are untyped, numerics never auto-convert, `switch` is
  exhaustive, and `enum` carries data — lean on the compiler.
- Watch `[weak self]` (ARC, no GC) and `@MainActor` (UI thread,
  enforced); push heavy work off it.
- Idioms — synthesized inits/`Codable`, trailing closures, `lazy`,
  module-wide `import`, camelCase with no `get`/`set` — are less
  boilerplate once the reflexes flip.

**Next:** Appendix C *A Study Plan*.
