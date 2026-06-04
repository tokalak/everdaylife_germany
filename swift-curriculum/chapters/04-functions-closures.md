# Functions, Closures, and Functional Style

Swift functions look like Java methods until you hit argument labels,
trailing closures, and result builders. This chapter covers the call-
site ergonomics, first-class closures, and the higher-order collection
API — anchored to Java methods and Streams, then the deltas.

## Function syntax and argument labels

```swift
func encrypt(_ plaintext: Data,
             using key: SymmetricKey) throws -> Data
```

The surprising part for a Java reader is that most parameters have *two*
names: an **external argument label** (seen at the call site) and an
**internal parameter name** (used in the body).

```swift
func encrypt(_ plaintext: Data, using key: SymmetricKey)
//           ▲ label  ▲ name    ▲label ▲name
```

- `_ plaintext`: the `_` suppresses the label, so the first argument is
  passed positionally. Inside the body it's `plaintext`.
- `using key`: the label is `using`; inside the body it's `key`.

The call site reads as a sentence:

```swift
let blob = try cryptor.encrypt(data, using: key)
```

This is deliberate API design, not noise. The method *name* is
`encrypt(_:using:)`, and labels are part of it — `encrypt(_:with:)`
would be a different function. There is no Java analog; Java
distinguishes overloads only by parameter *types*, never by call-site
labels. When you read `AES.GCM.seal(plaintext, using: key)`, the
`using:` is doing the same job.

Defaults, variadics, and `inout` round out the signature surface:

```swift
init(service: String = "de.everydaygermany.app.documents",
     account: String = "document-encryption-key")

func sum(_ values: Int...) -> Int       // variadic
func reset(_ x: inout Int) { x = 0 }     // pass-by-ref
```

`KeychainKeyStore`'s init uses **default arguments** so tests can pass an
isolated slot while production calls `KeychainKeyStore()`. A variadic
(`Int...`) is `int...` from Java. `inout` is true pass-by-reference for a
value type: the callee mutates the caller's variable, and you must pass
it with `&x`. It is not a shared reference — the value is copied in and
copied back out at the call boundaries.

> **Quarkus analogy.** Default arguments replace the telescoping-
> constructor and `@DefaultValue` patterns: one signature, optional
> params filled at the call site. No overload explosion, no builder.

## Closures: first-class functions

A closure is a lambda: an anonymous function value that captures its
environment. Functions are first-class — you store them, pass them, and
return them. The full form mirrors a function signature in braces:

```swift
let add = { (a: Int, b: Int) -> Int in a + b }
add(2, 3)   // 5
```

In a context where the type is known, you drop the annotations, and
shorthand argument names `$0`, `$1` replace the parameter list:

```swift
let names = docs.map { $0.fileName }
```

### Trailing-closure syntax

If a closure is the last argument, it moves outside the parentheses; if
it's the *only* argument, the parentheses vanish entirely. This is why
so much Swift and all of SwiftUI reads as blocks rather than calls. The
`dynamic(light:dark:)` helper in `ColorTokens` passes a closure to
`UIColor.init(_:)`:

```swift
Color(uiColor: UIColor { traits in
    traits.userInterfaceStyle == .dark
        ? UIColor(rgb: dark)
        : UIColor(rgb: light, alpha: lightAlpha)
})
```

`UIColor { traits in ... }` is `UIColor(_: { traits in ... })` with the
trailing closure pulled out. The closure runs *later*, whenever the
trait environment changes — that's what makes the color dynamic.

A second example from `KeychainKeyStore` — a closure handed to
`withUnsafeBytes` to copy raw key bytes into `Data`:

```swift
let data = key.withUnsafeBytes { Data($0) }
```

`$0` is the buffer pointer; `Data($0)` copies it out. The closure scopes
the unsafe pointer's lifetime to that one expression.

### Capture lists

A closure captures referenced variables. For reference types this can
form a retain cycle, so a **capture list** lets you capture weakly:

```swift
loader.onFinish = { [weak self] result in
    self?.apply(result)
}
```

`[weak self]` captures `self` as an optional weak reference, breaking
the cycle. Treat this as the intro; ARC, `weak`, and `unowned` are the
subject of *Memory and Concurrency*. Value types captured by a closure
are copied, so they never need a capture list for cycle reasons.

## Higher-order functions vs Java Streams

The collection transforms you know from `Stream` are methods directly on
the collection — no `.stream()` to enter and no `.collect()` to exit.

```swift
let selectable: [AppLanguage] = [.de, .en]
let visible = AppLanguage.allCases
    .filter { $0.isSelectable }
    .map(\.endonym)        // key path as a function
    .sorted()
```

Mapping to the Java equivalents:

| Swift | Java Stream |
|-------|-------------|
| `map` | `map` |
| `filter` | `filter` |
| `reduce(_:_:)` | `reduce` |
| `compactMap` | `map` + filter null |
| `flatMap` | `flatMap` |

Real call from `AppLanguage`:

```swift
var isSelectable: Bool {
    Self.selectable.contains(self)
}
```

`contains` is a higher-order member too (`contains(where:)` takes a
predicate; here the value overload). Two deltas matter against Streams:

**1. Methods on the collection, eager by default.** `map`/`filter`
return a fully materialised `Array` immediately. There is no lazy
pipeline and no terminal operation; the result *is* the array. You don't
"open" or "close" a stream.

**2. Opt into laziness with `.lazy`.** For a large source where you want
Stream-style deferred, fused evaluation:

```swift
let firstBig = records.lazy
    .filter { $0.expiresAt != nil }
    .map(\.fileName)
    .first
```

`.lazy` makes the chain compute elements on demand, so `first` stops
after the first match instead of transforming the whole array. That's
the Stream laziness you're used to — but it's opt-in, because eager is
the common, simpler case.

`compactMap` deserves a note: it maps and drops `nil`s in one pass,
unwrapping `Optional` results — the idiomatic way to parse-and-filter
(e.g. `rawValues.compactMap(AppLanguage.init(rawValue:))`).

> **Gotcha.** Because the standard operators are eager, chaining many of
> them over a large array allocates an intermediate array per step. For
> hot paths or huge inputs, prefix with `.lazy` to fuse them, the way a
> `Stream` already does.

## KeyPaths

`\.id` is a **key path**: a first-class, type-safe reference to a
property, usable wherever a `(Root) -> Value` function is expected.

```swift
.map(\.endonym)            // == .map { $0.endonym }
.sorted(using: KeyPathComparator(\.createdAt))
```

The nearest Java idea is a method reference (`Doc::getEndonym`), but a
key path is a reusable *value* you can store, compose, and pass around,
not just a call-site shorthand. SwiftUI and SwiftData use them
pervasively (`\.createdAt` in a sort, `\.self` as an identity id).

## `@escaping` vs non-escaping

By default a closure parameter is **non-escaping**: it must run before
the function returns and cannot be stored. That lets the compiler skip
capture-cycle worries and optimise harder.

A closure that outlives the call — stored in a property, scheduled,
passed to another thread — must be marked `@escaping`:

```swift
func load(then completion: @escaping ([DocumentRecord]) -> Void)
```

The compiler enforces the distinction: try to store a non-escaping
closure and it won't compile. Inside an `@escaping` closure, references
to `self` must be explicit, which is the nudge to add `[weak self]`.
With `async`/`await`, most of this fades — you write straight-line code
instead of escaping completion handlers — but you'll still see
`@escaping` in callback-style and AppKit/UIKit APIs.

## `@resultBuilder` and `@ViewBuilder`

A **result builder** is a compile-time transform that turns a block of
statements into a single aggregated value. You rarely write one, but you
use one constantly: SwiftUI's `@ViewBuilder` is a result builder that
collects the views in a block into one composite view.

`RootView.screen(for:)` is a `@ViewBuilder` function whose body is a
`switch` returning a *different* concrete view type per branch:

```swift
@ViewBuilder
private func screen(for tab: AppTab) -> some View {
    switch tab {
    case .home: HomeView()
    case .docs: VaultView()
    case .decode: DecoderView()
    case .dates: DatesView()
    case .settings: SettingsView()
    }
}
```

Without `@ViewBuilder` this wouldn't compile: the branches return
`HomeView`, `VaultView`, etc. — distinct types — yet the signature
promises one `some View`. The builder rewrites the `switch` into a
`_ConditionalContent` wrapper that erases the branches into a single
view type. The same mechanism lets you stack views in a `VStack { ... }`
body without commas, `return`s, or an array literal.

Conceptually it's a typed builder DSL the compiler generates for you —
closer to a Java fluent builder than to anything in `Stream`, but
applied implicitly to ordinary control flow.

> **Note.** You can author your own `@resultBuilder` (validation DSLs,
> query builders), but the high-value takeaway is recognising that
> `@ViewBuilder` blocks are *not* normal closures — `if`, `switch`, and
> bare expressions inside them are being transformed, which explains why
> SwiftUI bodies don't use `return` or commas.

## Takeaways

- Argument labels are part of a function's name: `_` drops the label,
  a word before the parameter names it, so `encrypt(data, using: key)`
  reads as a sentence. No Java equivalent.
- Closures are first-class lambdas; trailing-closure syntax (and `$0`
  shorthand) is why SwiftUI reads as blocks. `[weak self]` capture lists
  break retain cycles (full treatment later).
- `map`/`filter`/`reduce`/`compactMap`/`flatMap` are methods on the
  collection — no `.stream()`/`.collect()` — and **eager** by default;
  add `.lazy` for Stream-style deferred fusion.
- Key paths (`\.endonym`) are reusable, type-safe property references
  usable as functions, beyond a Java method reference.
- `@escaping` marks closures that outlive the call (stored/async);
  non-escaping is the optimised default.
- `@ViewBuilder` is a `@resultBuilder`: it transforms a block (including
  `switch`/`if`) into one composite view, which is why
  `RootView.screen(for:)` can return different view types as `some View`.

**Next:** *Memory and Concurrency: ARC, async/await, Actors* — the
reference-counting model behind `[weak self]`, structured concurrency,
and actor isolation.
