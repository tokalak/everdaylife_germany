# Types: Structs, Enums, Protocols, Generics

Swift's type system is wider than Java's: `struct`, `enum`, and `class`
are all first-class, and most code is built from value types. This
chapter maps each construct to its closest Java analog, then marks
where the analogy breaks — which is often.

## `struct`: the default type

A `struct` is a value type. The closest Java starting point is
`record`: a data aggregate with a compiler-synthesised initializer.

```swift
struct FileCryptor {
    func encrypt(_ plaintext: Data,
                 using key: SymmetricKey) throws -> Data {
        let sealed = try AES.GCM.seal(plaintext, using: key)
        guard let combined = sealed.combined else {
            throw FileCryptorError.sealingFailed
        }
        return combined
    }
    // decrypt(...) elided
}
```

If a `struct` has stored properties and you write no `init`, Swift
synthesises a **memberwise initializer** taking every property in
declaration order:

```swift
struct KeychainKeyStore: KeyProviding {
    let service: String
    let account: String
    // synthesised: init(service:account:) — unless you
    // write your own, which KeychainKeyStore does (to
    // supply defaults).
}
```

That is where the `record` analogy ends. Three differences matter.

**1. Value semantics, everywhere.** Assigning or passing a `struct`
copies it. There is no aliasing, no shared mutable reference, no
`equals`/`hashCode` contract to hand-write for identity.

```swift
var a = DateRange(start: .now, end: .now)
var b = a          // full copy
b.end = .distantFuture
// a.end is unchanged
```

In Java, two variables pointing at the same object see each other's
mutations. In Swift, `b` is independent. (Copies are
copy-on-write for the standard library's `Array`/`String`/`Dictionary`,
so this is cheap until you mutate.)

**2. `let` makes the whole value immutable.** A `let` binding to a
`struct` freezes *all* its properties — not just the reference. This is
stronger than Java `final`, which only stops reassignment of the field
itself.

```swift
let store = KeychainKeyStore()
store.account = "x"   // compile error: store is a let
```

With a `class`, `let` only freezes the reference; you could still call
a method that mutates the object's fields. With a `struct`, `let` is
deep.

**3. `mutating` methods.** Because a `struct` value is copied, a method
that changes `self` must say so explicitly with `mutating`. The
compiler then forbids calling it on a `let` value.

```swift
struct Counter {
    private(set) var value = 0
    mutating func bump() { value += 1 }
}
```

Java has no equivalent because objects are always references; "mutating
a record" is not a concept — records are final.

> **Quarkus analogy.** Think of a `struct` like a JPA-detached DTO you
> deep-copy on every hand-off: no entity-manager identity, no shared
> state, no surprise mutation from another thread. The compiler enforces
> what you'd normally enforce by discipline.

## `class`: reference type, used sparingly

A `class` is a reference type with the Java semantics you expect:
identity, shared mutable state, inheritance, and (in Swift) a `deinit`
that runs when the last reference is released — Swift uses ARC
(automatic reference counting), not a tracing GC.

```swift
@Observable
final class ThemeController {
    private(set) var theme: AppTheme
    func select(_ theme: AppTheme) {
        self.theme = theme
        // persist...
    }
}
```

`ThemeController` is a `class` deliberately: it holds shared,
observable, mutable state that the whole view tree reads. That is the
canonical reason to reach for a `class` in Swift — reference identity
and shared mutation are the *point*.

`final` blocks subclassing (like Java `final class`) and lets the
compiler devirtualise calls. The Swift convention inverts Java's
defaults: **classes are `final` unless inheritance is designed in**, and
you prefer `struct` unless you specifically need reference semantics,
identity, inheritance, or Objective-C interop.

`deinit` is deterministic — it runs the instant the refcount hits zero,
unlike Java's `finalize`, which the GC may never call. Use it for
cleanup (closing a handle, invalidating a timer), not for resurrection.

> **Gotcha.** ARC cannot collect reference cycles. Two classes holding
> strong references to each other leak. The fix is `weak`/`unowned`
> references, covered in *Memory and Concurrency*. Value types can't form
> cycles, which is another reason to prefer them.

## `enum`: sum types with pattern matching

Swift's `enum` is not Java's `enum`. It is a true algebraic sum type:
each case can carry associated values, and the compiler enforces
exhaustive handling. The mental model is Java's `sealed interface` with
records as permitted subtypes — but lighter and built in.

### Raw-value enums

When every case maps to a constant (a `String`, `Int`, etc.), give the
enum a **raw type**. `AppTab` is the tab bar's five destinations:

```swift
enum AppTab: String, CaseIterable, Identifiable {
    case home, docs, decode, dates, settings

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .home: return "tab_home"
        case .docs: return "tab_docs"
        case .decode: return "tab_decode"
        case .dates: return "tab_dates"
        case .settings: return "tab_settings"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house"
        case .docs: return "folder"
        case .decode: return "doc.text.viewfinder"
        case .dates: return "calendar"
        case .settings: return "gearshape"
        }
    }
}
```

`: String` synthesises `rawValue` (here `"home"`, `"docs"`, …) and a
failable `init?(rawValue:)`. That round-trip is how `ThemeController`
persists a theme: store `theme.rawValue` in `UserDefaults`, then
`AppTheme(rawValue: raw)` to read it back. The initializer is failable
(returns `AppTheme?`) because an arbitrary string may not match a case.

### Computed properties, not field tables

Note that `titleKey` and `systemImage` are **computed properties** with
a `switch`, not data attached to each case as in a Java enum
constructor. Swift enums can't store per-instance properties on cases
(a case with associated values is a different thing). The idiom is a
computed property that switches over `self`. The compiler's
exhaustiveness check guarantees that adding a sixth tab forces you to
update every such `switch` — a missing case is a compile error, not a
runtime `default` fall-through.

`AppLanguage` follows the same shape with richer derived data:

```swift
enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case de, en, tr, fr, es, it, ar, ru, zh

    var isRTL: Bool { self == .ar }

    var layoutDirection: LayoutDirection {
        isRTL ? .rightToLeft : .leftToRight
    }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    var endonym: String {
        switch self {
        case .de: return "Deutsch"
        case .ar: return "العربية"
        case .zh: return "中文"
        // ...
        }
    }
}
```

### `CaseIterable` and `Identifiable`

`CaseIterable` synthesises `static var allCases: [Self]` — the ordered
list of cases. `RootView` iterates it to build the tab bar:

```swift
ForEach(AppTab.allCases) { tab in
    screen(for: tab)
        .tabItem {
            Label(tab.titleKey,
                  systemImage: tab.systemImage)
        }
        .tag(tab)
}
```

`Identifiable` requires an `id`; SwiftUI uses it for stable diffing
in lists and `ForEach`, the way a UI framework needs a stable key.
Both are **protocols whose requirements the compiler synthesises** for
enums — no boilerplate.

### Associated values: the sum-type payoff

Cases can carry data, making the enum a tagged union:

```swift
enum LoadState {
    case idle
    case loading
    case loaded([DocumentRecord])
    case failed(Error)
}
```

A `switch` then binds the payload:

```swift
switch state {
case .idle, .loading:
    ProgressView()
case .loaded(let docs):
    list(docs)
case .failed(let error):
    errorView(error)
}
```

This is exactly a `sealed interface` with record subtypes plus a
pattern-matching `switch` — but with no class hierarchy, no
`instanceof`, and exhaustiveness for free. `Optional<T>` and the
`throws` machinery are themselves enums built this way.

## `protocol`: interfaces, then more

A `protocol` is an interface: a set of requirements a type promises to
satisfy. `KeyProviding` abstracts where the encryption key comes from:

```swift
protocol KeyProviding: Sendable {
    func symmetricKey() throws -> SymmetricKey
}
```

Two conformances — production and test — exactly as you'd swap a CDI
bean for a mock:

```swift
struct KeychainKeyStore: KeyProviding { /* Keychain */ }

final class InMemoryKeyStore: KeyProviding,
    @unchecked Sendable {
    private let key: SymmetricKey
    func symmetricKey() throws -> SymmetricKey { key }
}
```

Two things a Java reader should register. First, conformance is
declared at the type, but a `struct`, `class`, *and* `enum` can all
conform — protocols are not class-only. Second, `Sendable` is a
**marker protocol** with no methods; it tells the concurrency checker
the type is safe to cross actor boundaries (covered later).

### Protocol extensions = default methods, but more

A protocol extension provides implementations that all conformers get
for free — like Java `default` methods, but able to add *new* members,
not just defaults for declared ones:

```swift
extension KeyProviding {
    func keyFingerprint() throws -> String {
        try symmetricKey()
            .withUnsafeBytes { SHA256.hash(data: Data($0)) }
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
```

Every `KeyProviding` now has `keyFingerprint()` without each type
implementing it. This is the core of **protocol-oriented programming**:
behaviour composed from small protocols + extensions, instead of an
inheritance tree. It is Swift's answer to "I'd put this in an abstract
base class" — but it works for value types too.

### `any` vs `some`

When you reference a protocol as a *type*, you choose between two forms:

```swift
let store: any KeyProviding   // existential (boxed)
func makeStore() -> some KeyProviding  // opaque
```

`any KeyProviding` is an **existential**: a box that can hold any
conformer, resolved dynamically — analogous to a Java variable typed as
the interface. It is flexible but has indirection and blocks protocols
with associated types.

`some KeyProviding` is an **opaque type**: one specific, fixed
conforming type the compiler knows but the caller doesn't name. There's
no boxing, full optimization, and it can carry associated types. SwiftUI
leans on this — every `body` returns `some View`. Reach for `some`
unless you genuinely need to store mixed concrete types together, then
use `any`.

### Associated types

A protocol can have a placeholder type, like a Java generic interface
`interface Repo<T>` — but declared *inside* the protocol:

```swift
protocol Repository {
    associatedtype Entity
    func all() -> [Entity]
}
```

A conformer fixes `Entity` (often inferred). The catch: a protocol with
an associated type can't be used as a plain `any Repository` in every
position, because the associated type isn't pinned — which is precisely
where `some` and generic constraints come in.

## `extension`: open the type

`extension` adds methods, computed properties, and protocol conformance
to an existing type — including types you don't own. There is no Java
equivalent; the Java workaround is a `static` util class
(`StringUtils.foo(s)`). `ColorTokens` extends Apple's `UIColor`:

```swift
private extension UIColor {
    convenience init(rgb: Int, alpha: Double = 1) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: CGFloat(alpha))
    }
}
```

Now `UIColor(rgb: 0xFAF8F4)` reads as a real initializer, not
`ColorUtils.fromRgb(0xFAF8F4)`. `private` scopes the extension to this
file. Extensions are also the idiomatic way to add protocol conformance
after the fact and to organise a type's members into logical groups.

> **Note.** Extensions can't add stored properties or override existing
> methods — they widen the API surface, they don't change a type's
> layout or replace behaviour. That keeps them safe to apply to types
> you don't control.

## Generics: reified, not erased

Generics look familiar: a type or function parameterised over `T`, with
`where` constraints bounding it.

```swift
func first<T>(in items: [T],
             matching p: (T) -> Bool) -> T? {
    for item in items where p(item) { return item }
    return nil
}

func sortedByName<T>(_ items: [T]) -> [T]
    where T: Identifiable, T.ID: Comparable {
    items.sorted { $0.id < $1.id }
}
```

The constraint syntax `where T: Identifiable` is Java's `<T extends
Identifiable>`. The deep difference is the **runtime model**.

Java generics are **erased**: `List<String>` and `List<Integer>` are the
same `List` at runtime, `T` becomes `Object`, and you cannot write
`new T()`, `T.class`, or `instanceof List<String>`.

Swift generics are **reified** and **monomorphised**: the compiler
specialises generic code per concrete type, and the type argument
survives at runtime. Consequences a backend engineer should internalise:

- No type-erasure boxing. `[Int]` stores `Int` values inline, not boxed
  `Integer`s. Value types stay flat through generics — performance you
  can rely on.
- `T` is a real type at runtime: you can call `T.self`, switch on the
  metatype, and satisfy `T: Initializable`-style constraints to
  construct values. There is no `Object` floor.
- Specialisation can mean larger binaries and longer compiles — the dual
  of C++ templates. Swift mitigates this with witness tables when it
  can't or won't specialise, but the semantic model is "the real type is
  there."

> **Quarkus analogy.** Java erasure forces tricks — `Class<T>` tokens,
> `TypeReference`, reflection — to recover a type you "lost." Swift never
> loses it, so those patterns largely disappear. The cost moves to the
> compiler and binary size instead of runtime reflection.

### Where generics meet protocols

`@Model final class DocumentRecord` shows the payoff in real code:

```swift
@Model
final class DocumentRecord {
    @Attribute(.unique) var id: UUID
    var fileName: String
    var category: String
    var createdAt: Date
    var expiresAt: Date?
}
```

SwiftData's generic `FetchDescriptor<DocumentRecord>` and `Query` carry
the concrete element type with no erasure, so fetched results come back
as `[DocumentRecord]`, fully typed, no casts. This is the same machinery
as `[T]` above — generics + protocol constraints + reified types working
together, which is the spine of idiomatic Swift APIs.

## Takeaways

- Default to `struct` (value semantics, `let` = deep immutability,
  `mutating` for in-place change); reach for `class` only when you need
  identity, shared mutable state, inheritance, or `deinit`. Mark classes
  `final`.
- Swift `enum` is a true sum type: associated values model a `sealed
  interface`, and exhaustive `switch` turns "forgot a case" into a
  compile error. Raw-value enums give cheap `String`/`Int` round-trips.
- `CaseIterable` and `Identifiable` are compiler-synthesised protocol
  conformances; protocol extensions are default methods that can also
  add new behaviour — the basis of protocol-oriented programming.
- `extension` reopens any type (even Apple's) to add API — no Java
  equivalent; prefer it over util classes. It can't add stored state or
  override.
- Use `some` (opaque, no boxing) over `any` (existential, boxed) unless
  you must store mixed concrete types.
- Swift generics are reified/monomorphised, not erased: type arguments
  survive at runtime, value types stay unboxed, and the `Class<T>`/
  reflection workarounds from Java disappear.

**Next:** *Functions, Closures, and Functional Style* — argument labels,
closures and capture, `map`/`filter`/`reduce` vs Java Streams, and the
`@resultBuilder` behind SwiftUI's `@ViewBuilder`.
