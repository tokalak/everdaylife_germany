# Memory and Concurrency: ARC, async/await, Actors

This chapter covers the two runtime models where Swift diverges
most sharply from the JVM: how objects are reclaimed, and how
concurrent code is made safe. Coming from Quarkus you have a
garbage collector you rarely think about and a thread-safety
story you enforce by discipline (and hope). Swift inverts both.
Memory is managed deterministically at compile time, and data
races are caught by the compiler before the program runs.

## Part 1 — Memory: ARC instead of a garbage collector

The JVM tracks live objects at runtime. A background collector
periodically traces the object graph from GC roots, reclaims the
unreachable, and occasionally stops your threads to do it. You
tune heap sizes and collectors (G1, ZGC) precisely because this
is non-deterministic and can pause request handling.

Swift uses **Automatic Reference Counting (ARC)**. Each class
instance carries a reference count. The compiler — not a runtime
collector — inserts `retain` (increment) and `release`
(decrement) calls at the points where references begin and end.
When the count hits zero, `deinit` runs and the memory is freed,
immediately and at a known place in the code.

| Aspect | JVM GC | Swift ARC |
|---|---|---|
| When | Runtime, async | Compile-inserted |
| Determinism | Non-deterministic | Deterministic |
| Pauses | Possible (STW) | None |
| Cost | Background threads | Inline retain/release |

> **Quarkus analogy.** ARC is closest to `try-with-resources`
> or a reference-counted `AutoCloseable`, except the compiler
> writes the `close()` calls for you and threads them through
> every assignment, return, and capture. There is no collector
> thread and no STW pause to tune.

The trade-off: ARC cannot break **reference cycles**. A GC
traces reachability, so two mutually-referencing objects with no
external root are collected. ARC only counts; two objects
pointing at each other keep each other's count above zero
forever. That is the one memory failure mode a backend engineer
must learn to recognize.

### Retain cycles, weak, and unowned

Only **classes** participate in reference counting. A cycle
forms when two class instances hold strong references to each
other, or — far more common — when a closure captures the object
that owns it.

```swift
final class Vault {
    var onUnlock: (() -> Void)?
    func arm() {
        // STRONG capture of self → cycle:
        // self -> closure -> self
        onUnlock = { self.refresh() }
    }
    func refresh() { /* ... */ }
}
```

`self` retains the closure (it is stored in `onUnlock`); the
closure retains `self`. Neither count reaches zero; `deinit`
never runs. The fix is a **capture list** that captures `self`
weakly:

```swift
onUnlock = { [weak self] in self?.refresh() }
```

`weak` references are optional and become `nil` automatically
when the referent is deallocated — so you unwrap with `?` or
`guard let`. `unowned` is the non-optional variant: use it only
when the captured object is guaranteed to outlive the closure
(accessing a deallocated `unowned` reference traps, like a
`!`-forced nil). Default to `[weak self]`; reach for `unowned`
only when the lifetime invariant is genuinely airtight.

> **Gotcha.** Capture lists are evaluated once, when the closure
> is created. `[weak self]` does not "watch" `self`; it grabs a
> weak reference at that instant. This matters for `Task`
> closures and SwiftUI callbacks that outlive the current scope.

### Value types and copy-on-write

The cycle problem is a *class* problem. Swift's `struct` and
`enum` are **value types**: assigning or passing them copies the
value, so there is no shared identity to form a cycle and
usually nothing to reference-count. `AppLanguage` in Alltag is a
value type:

```swift
enum AppLanguage: String, CaseIterable,
    Identifiable, Sendable {
    case de, en, tr, fr, es, it, ar, ru, zh
}
```

Passing an `AppLanguage` around never allocates, never retains,
and never leaks. This is the opposite of Java, where every
non-primitive is a heap reference. In Swift, prefer `struct`;
reach for `class` only when you need identity, inheritance, or
shared mutable state.

Naively, value semantics imply copying large collections on
every assignment. Swift avoids that with **copy-on-write
(COW)**. `Array`, `String`, and `Dictionary` are structs that
wrap a reference to heap storage. Assigning shares the storage;
the copy is deferred until the first mutation, and only then if
the storage is shared (referenced more than once).

```swift
var a = [1, 2, 3]
var b = a          // shares storage, no copy
b.append(4)        // now b copies; a is untouched
```

So you get value semantics (safe to pass across boundaries) with
reference-level performance for reads. No defensive copying, no
`Collections.unmodifiableList`, no aliasing surprises.

### When a backend engineer should actually worry

Rarely. Value types do not leak. The realistic risks are two:

1. A `class` whose stored closure captures `self` strongly
   (the `Vault` example). Audit any `var handler: (() -> Void)?`
   field.
2. Long-lived objects (a controller, an `@Observable` store)
   captured strongly by closures with a longer lifetime than
   expected — delegates, notification observers, `Task`s.

Xcode's Memory Graph Debugger and Instruments' Leaks/Allocations
play the role of a heap dump plus a leak detector. But unlike
JVM leaks, the common Swift leak has a single shape — a captured
`self` — so `[weak self]` is the one habit that prevents almost
all of them.

## Part 2 — Concurrency: the big shift

This is where Swift will feel most foreign. In Quarkus you reach
for `ExecutorService`, `CompletableFuture`, or Mutiny `Uni`, and
you protect shared state with `synchronized`, `ReentrantLock`,
or `Atomic*`. You are responsible for thread-safety, and the
compiler does not check it. Swift replaces this with `async`/
`await`, structured tasks, `actor` isolation, and — the headline
— **compile-time data-race safety**.

### async/await vs CompletableFuture and Uni

An `async` function can suspend and resume without blocking its
thread. `await` marks a suspension point. The shape reads like
synchronous code but is non-blocking, much like Mutiny lets you
compose without blocking a worker thread — except there is no
pipeline type to thread through.

```java
// Java: the type is contagious and explicit.
CompletableFuture<Document> load(UUID id) { ... }
load(id).thenApply(this::decrypt)
        .thenAccept(this::render);
```

```swift
// Swift: async is a function effect, like throws.
func load(_ id: UUID) async throws -> Document { ... }

let doc = try await load(id)
let plain = try await decrypt(doc)
render(plain)
```

Key differences from `CompletableFuture`/`Uni`:

- `async` is an *effect* on the function (like `throws`), not a
  wrapper type. There is no `CompletableFuture<T>` to unwrap or
  `Uni<T>` to subscribe to — you write `try await` and get `T`.
- You cannot `await` outside an async context. To bridge from
  sync code you start a `Task` (below), the rough analog of
  handing work to an executor.
- Suspension is cooperative: an awaiting function yields its
  thread back to a shared pool, so thousands of in-flight
  `async` calls do not mean thousands of OS threads.

### Task: entering the concurrent world

A `Task` is the unit that runs async work — loosely, "submit
this to the cooperative pool." Creating one from synchronous
code (a SwiftUI button, `viewDidLoad`) is how you cross into
async:

```swift
Task {
    do {
        let doc = try await load(id)
        await render(doc)
    } catch {
        log.error("load failed: \(error)")
    }
}
```

Unlike `executor.submit`, a `Task` inherits context from where
it is created — priority, and crucially the **actor** it runs
on (so a `Task` created in `@MainActor` code stays on the main
actor unless told otherwise).

### Structured concurrency: async let and TaskGroup

Structured concurrency ties child task lifetimes to a lexical
scope. When the scope exits, its children are guaranteed
finished or cancelled — no orphaned futures, no leaked threads.
There is no clean JVM equivalent before Project Loom's
`StructuredTaskScope`.

`async let` runs siblings concurrently and joins at the `await`:

```swift
func loadDashboard() async throws -> Dashboard {
    async let docs = fetchDocuments()
    async let lang = fetchLanguagePack()
    // both run concurrently; join here:
    return Dashboard(
        documents: try await docs,
        language: try await lang)
}
```

For a dynamic number of children, use a `TaskGroup` — the analog
of `invokeAll` over a list, but scoped and cancellation-aware:

```swift
func decryptAll(_ ids: [UUID]) async throws
    -> [Document] {
    try await withThrowingTaskGroup(
        of: Document.self
    ) { group in
        for id in ids {
            group.addTask { try await load(id) }
        }
        var out: [Document] = []
        for try await doc in group {
            out.append(doc)
        }
        return out
    }
}
```

### Cancellation is cooperative

Cancelling a `Task` (or its parent scope exiting) does not
forcibly stop anything — exactly like `Thread.interrupt()` sets
a flag rather than killing the thread. Your code must observe
it: call `try Task.checkCancellation()` (throws
`CancellationError`) or read `Task.isCancelled` in loops. Most
async stdlib calls (`URLSession`, `Task.sleep`) check
cancellation for you.

```swift
for id in ids {
    try Task.checkCancellation()
    results.append(try await load(id))
}
```

> **Quarkus analogy.** Structured concurrency is what you wish
> `CompletableFuture` had: child tasks cannot outlive their
> parent scope, errors propagate to the awaiting parent, and
> cancelling the parent cancels the children. No manually
> tracking and cancelling a `List<Future<?>>`.

### actor: isolation instead of locks

An `actor` is a reference type whose mutable state is protected
by the compiler. Only one task touches an actor's state at a
time; all access from outside is serialized and must be
`await`ed. This is the Swift answer to `synchronized`,
`ReentrantLock`, and `Atomic*` — but enforced rather than
remembered.

```swift
actor ModelDownloadTracker {
    private var bytesByModel: [String: Int] = [:]

    func record(_ model: String, bytes: Int) {
        // No lock needed: actor serializes this.
        bytesByModel[model, default: 0] += bytes
    }

    func total(_ model: String) -> Int {
        bytesByModel[model, default: 0]
    }
}
```

From outside, every call hops onto the actor and suspends:

```swift
await tracker.record("gemma", bytes: n)
```

The compiler *rejects* synchronous access to `bytesByModel`
from another context. You cannot forget the lock, because there
is no lock to forget — the type system requires the `await`.
This is the classic actor model (Akka, Erlang), but built into
the language and checked at compile time.

> **Note.** Actor isolation prevents data races, not logical
> races. Two `await`ed `record` calls are each atomic, but the
> interleaving between them is still nondeterministic — just as
> two `synchronized` methods don't compose into one atomic
> operation. For read-modify-write you still need a single
> actor method that does the whole thing.

### @MainActor: the UI thread, enforced

UI frameworks require their work on one thread — Swing's EDT,
JavaFX's Application Thread. The JVM enforces this only at
runtime (`IllegalStateException`, or worse, silent corruption).
Swift has a global actor, `@MainActor`, and the compiler
enforces it.

Annotating a type with `@MainActor` isolates all its members to
the main thread. Alltag's environment and stores do exactly
this:

```swift
@MainActor
@Observable
final class AppEnvironment {
    let theme: ThemeController
    let language: LanguageStore
    let persistence: PersistenceController
    let llm: LLMService
    // ...
}
```

```swift
@MainActor
@Observable
final class LanguageStore {
    private(set) var language: AppLanguage
    func select(_ language: AppLanguage) {
        guard language.isSelectable else { return }
        self.language = language
        // ...
    }
}
```

Because `LanguageStore` is `@MainActor`, calling `select(_:)`
from a background `Task` requires an `await` that hops to the
main thread — the compiler guarantees the UI-bound `@Observable`
state is only mutated on the main thread. No more "updated the
model off the EDT" bugs.

`PersistenceController` is `@MainActor` for the same reason: its
`mainContext` is main-actor bound. The class comment captures
the escape route for background work:

```swift
/// `@MainActor` because the app's `mainContext` is
/// main-actor bound; background work uses a `ModelContext`
/// created off a `ModelContainer` (Sendable).
@MainActor
final class PersistenceController {
    let container: ModelContainer
    // ...
}
```

The `ModelContainer` is `Sendable`, so it can cross actor
boundaries; a background `Task` makes its own `ModelContext`
from it rather than touching the main-actor `mainContext`.

### Sendable and compile-time data-race safety

This is the selling point with no Java equivalent. `Sendable`
is a marker protocol meaning "safe to pass across concurrency
boundaries." With `SWIFT_STRICT_CONCURRENCY: complete` — set in
Alltag's `project.yml` — the compiler **checks** that every
value crossing an actor or task boundary is `Sendable`, and
flags anything that could be mutated from two places at once.

```yaml
settings:
  base:
    SWIFT_STRICT_CONCURRENCY: complete
```

Java has nothing like this. `@GuardedBy` is a comment; the
JMM defines what *correct* synchronization means but the
compiler never verifies you did it. You find data races in
production, via heisenbugs. Swift refuses to compile the race.

What is `Sendable` for free? Value types of `Sendable` members
(so `AppLanguage`, which is declared `Sendable`), actors
(isolated by construction), and immutable classes. Mutable
classes are *not* `Sendable` unless you prove it.

Protocols can require it. `KeyProviding` is `Sendable` so any
key store can be shared across the encryption pipeline's tasks:

```swift
protocol KeyProviding: Sendable {
    func symmetricKey() throws -> SymmetricKey
}
```

`KeychainKeyStore` is a `struct` with immutable `let` fields, so
it satisfies `Sendable` automatically. The compiler verifies it.

### @unchecked Sendable: the escape hatch

Sometimes you know a type is safe but the compiler cannot prove
it. `@unchecked Sendable` opts out of checking — "trust me." It
is the analog of writing thread-safe Java by hand: correct, but
unverified. Use it sparingly and document the invariant.

Alltag's test key store is the real example: a `final class`
(reference type, so not auto-`Sendable`) holding a `let` key.
It is logically immutable, hence safe to share, but the compiler
won't infer that for a class:

```swift
final class InMemoryKeyStore: KeyProviding,
    @unchecked Sendable {
    private let key: SymmetricKey

    init(key: SymmetricKey = SymmetricKey(size: .bits256)) {
        self.key = key
    }

    func symmetricKey() throws -> SymmetricKey { key }
}
```

The `key` is a `let` set once in `init` and never mutated, so
concurrent reads are safe — but because it is a class, you
assert that with `@unchecked Sendable` rather than getting it
for free. (A `struct` here would have been `Sendable`
automatically; it's a class because the protocol is shared and
the test needs a stable identity.)

> **Gotcha.** `@unchecked Sendable` silences the checker
> *completely* for that type. If you later add a mutable `var`,
> the compiler will not warn you that you have reintroduced a
> race. Treat every `@unchecked` as a small unverified contract,
> and keep the type tiny so the invariant is obvious.

### nonisolated, and Swift 6 defaults

`nonisolated` marks a member of an actor-isolated type as *not*
isolated — it can be called synchronously from anywhere because
it touches no isolated state (e.g. a computed property over
`let` fields, or a `Hashable` conformance). It is the targeted
exception to a `@MainActor` or actor type.

```swift
@MainActor
final class Catalog {
    let id: String              // immutable
    nonisolated var key: String { "catalog-\(id)" }
}
```

Under **Swift 6**, strict concurrency becomes the *default* — so
`SWIFT_STRICT_CONCURRENCY: complete` is the on-ramp Alltag is
already standing on. Code written this way today compiles
unchanged under the Swift 6 language mode; code that ignored
concurrency will face a wall of errors at migration. Building
with `complete` now is paying down that debt incrementally
instead of all at once.

> **Quarkus analogy.** Think of `Sendable` as `@ThreadSafe`
> that the compiler actually enforces, and `@MainActor` as a
> statically checked "must run on the EDT." The mental model is
> familiar; what's new is that the guarantees are proven at
> build time, not discovered in production.

## Takeaways

- ARC reclaims memory deterministically at scope/lifetime end —
  no GC pauses, but you must break reference cycles yourself
  with `[weak self]` (default) or `unowned` (sharp edge).
- Prefer value types (`struct`/`enum`); they don't leak and
  can't form cycles. `Array`/`String`/`Dictionary` use
  copy-on-write for value semantics at reference-read cost.
- `async`/`await` is an effect, not a wrapper type; `Task`
  bridges from sync code; structured concurrency (`async let`,
  `TaskGroup`) ties child lifetimes to a scope and cancels
  cooperatively.
- `actor` replaces locks with compiler-enforced serialized
  access; `@MainActor` makes the UI-thread requirement
  statically checked — Alltag's `AppEnvironment`,
  `LanguageStore`, and `PersistenceController` are all
  `@MainActor`.
- `Sendable` plus `SWIFT_STRICT_CONCURRENCY: complete` gives
  compile-time data-race safety Java has no equivalent for;
  `@unchecked Sendable` (e.g. `InMemoryKeyStore`) is the
  documented escape hatch, and `complete` is the Swift 6
  default in waiting.

**Next:** *The SwiftUI Model: Declarative Views and State*
