# Architecture: State, Dependencies, and the @Observable Environment

You know how to build screens. The harder question is how to
wire an app: where state lives, where business logic goes, and
how a view gets the services it needs without reaching for a
global. On the server you answer this with a DI container —
in Quarkus, CDI scans, builds, and injects beans, and you
rarely think about object graphs explicitly. SwiftUI has no
such framework, and that is not a gap to fill with a
third-party clone. The platform gives you a smaller, sharper
set of tools: `@Observable` models and an environment you
build *by hand*. This chapter shows how Alltag uses them, and
where the CDI muscle memory will mislead you.

## MV, not MVVM

The first thing to unlearn is the reflex to add a ViewModel to
every screen.

The dominant pre-`@Observable` pattern was **MVVM**: each view
got an `ObservableObject` ViewModel publishing `@Published`
properties, and the view observed it. This existed largely to
work around old SwiftUI: only `ObservableObject` could drive
updates, and it did so coarsely (any `@Published` change
re-rendered every observer). Teams coming from server MVC
cargo-culted a ViewModel per view because it *felt* like the
service layer they knew.

iOS 17's `@Observable` macro changes the economics. A plain
class annotated `@Observable` drives view updates directly, and
crucially the tracking is *fine-grained*: a view re-renders
only when a property it actually read changes. There is no
`ObservableObject`, no `@Published`, no per-property ceremony.

```swift
@Observable
final class ThemeController {
    private(set) var theme: AppTheme
    func select(_ theme: AppTheme) { /* ... */ }
}
```

This enables **MV** — Model plus View. The "model" is your
domain types and the `@Observable` services that own them; the
view reads them directly. You do *not* interpose a
pass-through ViewModel whose only job is to forward properties.
That object would add indirection, a second source of truth,
and tests for glue code that does nothing.

> **Gotcha.** "MV" is not "put everything in the view." It is
> "don't add a ViewModel layer that earns nothing." Logic still
> belongs in models and services (below) — just not in a
> mandatory per-screen wrapper. Add a dedicated observable
> object when a screen has real presentation state to manage;
> skip it when the screen only reads shared models.

Alltag has no `SettingsViewModel`. `SettingsView` reads
`ThemeController` and `LanguageStore` straight from the
environment. The controllers *are* the model layer.

## Dependency injection without a framework

So how do those controllers reach the view? Through SwiftUI's
**environment** — a typed, hierarchical context propagated down
the view tree. You inject a value once near the root, and any
descendant reads it by type.

Alltag's container is `AppEnvironment`:

```swift
@MainActor
@Observable
final class AppEnvironment {
    let theme: ThemeController
    let language: LanguageStore
    let persistence: PersistenceController
    let llm: LLMService

    init(
        persistence: PersistenceController,
        llm: LLMService,
        theme: ThemeController = ThemeController(),
        language: LanguageStore = LanguageStore()
    ) {
        self.persistence = persistence
        self.llm = llm
        self.theme = theme
        self.language = language
    }
}
```

This single object owns the long-lived foundations:
persistence, language, theme, and the on-device LLM facade. It
is injected once at the app root and read anywhere:

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

```swift
struct RootView: View {
    @Environment(AppEnvironment.self) private var env
    // ...
}
```

`.environment(env)` puts the container into the tree at the
root. `@Environment(AppEnvironment.self)` pulls it out, by
type, in any descendant — `RootView`, `SettingsView`, screens
nested arbitrarily deep. No prop-drilling through intermediate
views, no singleton.

### Compared to CDI — and where it diverges

If you squint, this *is* dependency injection: a container of
collaborators, resolved by type, handed to consumers. But the
deltas from Quarkus CDI matter, and getting them wrong is how
backend engineers fight SwiftUI.

| Aspect | Quarkus CDI | `AppEnvironment` |
|---|---|---|
| Graph built | by container, at boot | by hand, in `live()` |
| Resolved by | type + qualifiers | type (env key) |
| When | runtime, reflection | compile-time |
| Mechanism | proxies | plain references |

Point by point:

- **No reflection, no proxies.** CDI scans the classpath,
  reads annotations, and synthesizes proxy beans. SwiftUI does
  none of this. `AppEnvironment` is a `final class` you `init`
  with plain stored properties. What you write is what runs —
  the object graph is literal code in a factory method, not a
  thing assembled by a container at startup.
- **Built by hand in a factory.** There is no `@Inject` doing
  the wiring. You construct the graph yourself in `live()`
  (next section). This is more typing than CDI but radically
  more legible: the entire dependency graph is one readable
  function, steppable in a debugger, with zero "where did this
  bean come from" mystery.
- **Compile-time.** A missing dependency is a compile error
  (the `init` won't satisfy), not a runtime
  `UnsatisfiedResolutionException`. You cannot ship an app with
  an unfulfilled dependency.
- **Passed down the tree, not globally scoped.** A CDI
  `@ApplicationScoped` bean is reachable from anywhere in the
  process. The SwiftUI environment is *hierarchical*: a value
  is visible only to descendants of where it was injected. That
  scoping is structural, by view position, not by annotation.
- **Resolution is by type alone.** The environment keys on the
  concrete type. There is no qualifier mechanism like
  `@Named`/`@Qualifier`. To inject two of the same type, you
  give them distinct types, not labels.

> **Quarkus analogy.** `@Environment(AppEnvironment.self)` is
> `@Inject AppEnvironment`. `.environment(env)` is the
> producer that put it in scope. But the scope is *the view
> subtree*, not the application, and the wiring is your
> handwritten `init`, not a proxy the container forged.

## The factory: `live()` vs a CDI producer

CDI assembles graphs with `@Produces` methods. Alltag's
equivalent is the static `live()` factory — the one place the
production object graph is constructed:

```swift
static func live() -> AppEnvironment {
    let llm = makeLLM()
    do {
        return AppEnvironment(
            persistence: try PersistenceController(), llm: llm)
    } catch {
        assertionFailure(
            "Persistent store unavailable, in-memory: \(error)")
        return AppEnvironment(
            persistence: try! PersistenceController(
                inMemory: true), llm: llm)
    }
}
```

This reads like a CDI producer, but everything is explicit and
sequential. It constructs the real persistence stack, and — a
detail a server engineer will respect — if the on-disk
SwiftData store can't be opened, it logs and falls back to an
in-memory store so the app still launches rather than crashing
on first run. A producer method scattering this fallback across
annotations would obscure it; here it is four lines you can
read top to bottom. `theme` and `language` default in the
`init`, so `live()` doesn't even name them.

Note also *who owns* the container. In `AlltagApp` it is held
by `@State`:

```swift
@State private var env = AppEnvironment.live()
```

`@State` here does not mean "view-local UI flag" — it means the
`App` struct *owns* this reference for the process lifetime and
SwiftUI keeps it alive across re-evaluations of `body`. The
container is constructed exactly once, at launch, and never
rebuilt. That is the SwiftUI idiom for a root-owned singleton:
not a `static` global, but a `@State`-owned value created at the
top of the tree. Descendants borrow it via `@Environment`; the
root owns its lifetime. Contrast CDI, where the container owns
every bean's lifecycle and scope; here ownership is a property
of *where in the tree the value is declared*.

### The test container

The payoff of hand-built DI is testability without a test
container framework. Alltag's `PersistenceController` takes an
`inMemory: Bool`; an in-memory `AppEnvironment` is just a
different construction:

```swift
let env = AppEnvironment(
    persistence: try PersistenceController(inMemory: true),
    llm: LLMService(/* stub engine */))
```

No `@QuarkusTest`, no CDI test bootstrap, no `@Mock` beans
swapped by the container. You build the graph you want and pass
it in. Because every collaborator is constructor-injected, a
test substitutes a stub `LLMEngine` or an isolated
`UserDefaults` suite by *handing it to the initializer*. The
`LanguageStore` and `ThemeController` initializers already
accept an injected `UserDefaults` precisely so tests use an
isolated suite:

```swift
init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    // ...
}
```

Constructor injection with sensible defaults is the whole
dependency-inversion story. The default keeps production call
sites clean; the parameter keeps tests hermetic. No framework
required.

## Where business logic lives

If there is no ViewModel and the container only holds
foundations, where does logic go? Into **use-cases and
services**, constructed in the environment from those
foundations.

The `AppEnvironment` doc comment states the intent directly:
*"As features land, their use-cases are constructed here from
these foundations (persistence, language, theme)."* A Decoder
use-case is built from the LLM facade plus persistence; a
deadline calculator from persistence plus the calendar. The
view calls the use-case; the use-case owns the rules. This is
exactly the service layer you would put behind a Quarkus
resource — the resource (view) stays thin and delegates to a
service that does the work.

The factory `makeLLM()` shows a service being assembled from
parts: a `ModelStore`, a `ModelProvisioner`, an engine, and a
runtime are composed into one `LLMService` facade. The view
sees the facade; the wiring stays in the environment.

The foundations themselves are real services, not config bags.
`PersistenceController` owns the SwiftData stack — its
`ModelContainer`, its schema, its on-disk location:

```swift
@MainActor
final class PersistenceController {
    let container: ModelContainer
    static let schema = Schema([DocumentRecord.self])
    init(storeURL: URL? = nil,
         inMemory: Bool = false) throws { /* ... */ }
}
```

A use-case that needs to read documents takes the container (or
a `ModelContext` from it) injected through the environment, the
same way a Quarkus service takes an injected `EntityManager`.
The architectural rule that matters: the view never constructs a
`ModelContext` or talks to SwiftData directly. It goes through a
Control-layer use-case, which the environment built from the
`PersistenceController` foundation. Foundations at the bottom,
use-cases in the middle, views at the edge — the dependency
arrows point inward, exactly as in a hexagonal server app.

### Boundary–Control–Entity

Alltag organizes code with **BCE**, per feature. You will see
it in the folder layout — `Features/Settings/Boundary`,
`Features/Decoder/...`, each feature a vertical slice:

- **Boundary** — the SwiftUI views, the user-facing edge.
  `SettingsView`, `VaultView`, `DecoderView` live here.
- **Control** — use-cases and services, the logic constructed
  from the foundations.
- **Entity** — domain models and persisted records (e.g.
  `DocumentRecord`).

A backend engineer can read this directly as a hexagonal /
ports-and-adapters layering: Boundary is the inbound adapter
(the UI port), Control is the application/service layer, Entity
is the domain. The discipline is the same one you apply
server-side — keep the framework-facing edge thin, keep rules
in the middle, keep the domain pure. Organizing *per feature*
rather than per layer means a feature's view, logic, and models
sit together, so a change to Decode rarely touches Settings.

## Unidirectional data flow

Tie it together and you get a clean one-way loop, the same
shape as a well-behaved request handler:

1. A view reads state from an `@Observable` model in the
   environment (`env.theme.theme`).
2. A user action calls a method on a model or use-case
   (`env.theme.select(.dark)`).
3. The model mutates its own state and persists it.
4. `@Observable` tracking marks every view that read the
   changed property dirty; SwiftUI re-renders just those.

State flows down (model → view); events flow up (view →
method). Views never mutate model state directly — they call
intent methods (`select(_:)`), which is why those properties
are `private(set)`. That single rule — read freely, mutate only
through methods — is what keeps a SwiftUI app debuggable. When
`SettingsView` calls `select`, the change ripples through the
shared `env` to `RootView`, which re-applies the color scheme
and locale app-wide. One mutation, one source of truth, a
deterministic re-render. No event bus, no observers to
register, no `@Inject Event<ThemeChanged>` to fire.

> **Note.** `@Observable` requires `@MainActor` discipline for
> UI-driving state — note `AppEnvironment`, `ThemeController`,
> and `LanguageStore` are all `@MainActor`. State that a view
> reads must mutate on the main actor. Background work
> (LLM inference, disk I/O) runs off-main with `async/await`,
> then hops back to the main actor to publish results. This is
> stricter than CDI, where a bean's threading is your problem
> to coordinate; here the compiler enforces the boundary.

## Choosing a state property wrapper

A recurring beginner question — "which wrapper do I use?" — has
a small, learnable answer once you separate *ownership* from
*access*. Three wrappers cover nearly everything:

| Wrapper | Meaning | Use for |
|---|---|---|
| `@State` | this view/App owns it | local UI, root container |
| `@Environment` | injected, read by type | shared services (`env`) |
| `@Bindable` | writable view onto a model | binding to `@Observable` |

`@State` is ownership: the declaring view (or `App`) creates and
keeps the value. Use it for a screen's transient flags
(`showingScanner`) and, at the root, for the long-lived
container. `@Environment` is the read side of DI: the value was
created elsewhere and injected; you borrow it by type and never
own its lifetime. `@Bindable` is purely about producing
`Binding`s into an `@Observable` reference you already hold.

The mistake to avoid is using `@State` for something a parent
should own, or duplicating an environment value into local
`@State` (which forks the source of truth and goes stale). Map
it to the server analogue: `@State` is a field you allocate and
manage; `@Environment` is an injected collaborator you must not
re-instantiate. When in doubt, ask "who is responsible for this
value's lifetime?" — that answers the wrapper.

## Mutating shared state: `@Bindable`

One loose end from the screens chapter. When a control needs
to *write* into an `@Observable` model, you need a `Binding`.
For a model you hold directly, `@Bindable` synthesizes them:

```swift
struct ThemeRow: View {
    @Bindable var controller: ThemeController
    var body: some View {
        // $controller.theme is a Binding<AppTheme>
    }
}
```

`@Bindable` is the bridge between an `@Observable` reference
type and the `$`-binding syntax that controls expect. Where the
model exposes a settable property, `$model.prop` just works.
Alltag's `SettingsView` instead writes a custom
`Binding(get:set:)` because `select(_:)` carries a guard and a
persistence side effect that a raw property write would skip —
a reminder that `@Bindable` is the convenience, and an explicit
binding is the escape hatch when a write needs to do more than
assign.

## Takeaways

- Prefer **MV**: `@Observable` models drive views directly.
  Don't cargo-cult a ViewModel per screen — add an observable
  object only when a screen has real presentation state.
- DI is the **environment**: inject an `@Observable` container
  with `.environment(...)`, read it with `@Environment(...)`.
  `AppEnvironment` is Alltag's whole container.
- It resembles CDI but is hand-built in a factory, resolved by
  type, scoped to the view subtree, compile-time checked, with
  no reflection or proxies.
- `live()` is the production producer; an `inMemory` container
  and constructor-injected defaults give framework-free
  testability.
- Logic lives in use-cases/services constructed in the
  environment, organized by feature as Boundary–Control–Entity.
- Data flows one way: read state down, send events up via
  intent methods on `@MainActor` `@Observable` models. Use
  `@Bindable` for writable bindings, an explicit
  `Binding(get:set:)` when a write must route through guarded
  logic.

**Next:** Persistence: SwiftData, the Keychain, Files, and CryptoKit
