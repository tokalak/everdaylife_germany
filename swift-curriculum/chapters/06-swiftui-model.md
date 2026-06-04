# The SwiftUI Model: Declarative Views and State

You have built UIs before, just not this kind. On the server you
emitted HTML — Qute templates in Quarkus, maybe Thymeleaf or JSF
earlier — where a request comes in, you compute a model, render a
string, and the connection closes. The output is dead the moment it
leaves the socket. If the data changes, the client must ask again.
On the desktop side you may have touched imperative toolkits (Swing,
or iOS's own UIKit) where a view is a long-lived mutable object you
hold a reference to and poke: `label.setText(...)`, `view.hidden =
true`. SwiftUI is neither of those, and the gap is where every
backend engineer stumbles first.

This chapter is about the single idea that makes the rest of SwiftUI
make sense: **a view is a value, not an object you mutate.** Get this
and the API stops feeling magical. Miss it and you will fight the
framework for weeks.

## A view is a value, not a thing you keep

Here is the app's root, verbatim:

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

`RootView` is a `struct`. Not a class. When SwiftUI wants to know
what the UI looks like, it *constructs a `RootView` value* and reads
its `body`. That value is a lightweight description — "a tab view
containing these five screens, tinted teal, rounded font." It is not
the pixels, and it is not a retained object with identity that you
will mutate later. SwiftUI may create and throw away `RootView`
values dozens of times per second. They are cheap, ephemeral
recipes.

Compare this to a Qute template. Your template is also a
*description* of output, and you also don't hold a reference to the
rendered HTML — you produce it and forget it. So far so familiar.
The difference is that Qute renders **once per request** and SwiftUI
re-renders **whenever the state it read changes**, automatically,
for the life of the screen. The template is reactive and persistent;
the server template is one-shot. SwiftUI is closer to a
server-rendered template that re-runs itself the instant any input
changes — with the framework, not you, deciding when.

Now contrast the imperative side. In UIKit (or Swing) you would
write a `UIViewController`, keep an outlet to a label, and on a
button tap call `label.text = greeting`. *You* mutate the live
object tree. The screen is the source of truth, and your job is to
keep it in sync with your data by hand. This is exactly the bug
factory SwiftUI deletes: forget one `label.text =` and the screen
lies about your data.

> **Quarkus analogy.** Think of `body` as a render method that
> Quarkus calls for you on every model change, not a constructor for
> a stateful component. You never `new` a view and store it. You
> describe what *should* be on screen for the current state; the
> framework computes the diff against what *is* on screen and mutates
> the real UIKit objects underneath. You write declarative; SwiftUI
> runs imperative for you.

### The `View` protocol, `body`, and `some View`

Every screen conforms to one protocol:

```swift
struct HomeView: View {
    var body: some View {
        PlaceholderScreen(
            titleKey: "tab_home", systemImage: "house")
    }
}
```

`View` is a protocol with one required member: a computed property
`body`. That is the whole contract — "I can describe myself." In
Java terms it is an interface with a single method, and `HomeView`
is your implementation.

The return type is `some View`. This is an **opaque return type**:
the method returns *one specific concrete type that conforms to
`View`*, but the caller is not told which one. The actual type here
is a deeply nested generic — something like
`PlaceholderScreen` wrapped in modifier types — and it would be
absurd to write out by hand. `some View` says "trust me, it's a
single `View` type, you don't need its name."

Why not just `-> View` (the protocol as a type, like returning a
Java interface reference)? Because SwiftUI's diffing needs the
*static* concrete type at compile time to compare two renders
efficiently without boxing every view behind a pointer. `some View`
gives the compiler the exact type while hiding it from you. The
nearest Java analogy is a method returning `var`-inferred concrete
type rather than the interface — except Swift lets you keep that
concreteness in the signature while still hiding the name. The
practical rule: write `some View` for `body` and move on.

## The render/diff loop

The mechanism is a tight loop, and it is the same loop for every
SwiftUI app:

1. SwiftUI reads a view's `body`, producing a value tree.
2. It records *which pieces of state that view read* while computing
   `body` — this dependency tracking is automatic.
3. It diffs the new value tree against the previous one and applies
   the minimal changes to the real (UIKit) view objects.
4. When any tracked state changes, SwiftUI re-invokes `body` for
   *only the views that read that state*, and goes back to step 3.

This is a virtual-DOM-style reconciliation, if you've met React, but
without a manual `setState` call site — the dependency is captured
by the act of reading the property. You do not call "re-render." You
mutate state; the framework noticed you read it; it recomputes.

Two consequences fall out of this loop, and both are load-bearing:

**Views must be cheap.** `body` may run constantly. If your `body`
does real work — a network call, a database query, sorting ten
thousand rows — you pay that cost on every recompute. Keep `body` to
pure assembly of subviews. Heavy work belongs in your model layer,
computed once, not in the render path.

**Views must be side-effect-free.** `body` is a pure function of
state. Do not start a timer, write to disk, or fire an analytics
event inside `body`. SwiftUI may call `body` more or fewer times
than you expect, in any order. Side effects go in explicit hooks
(`.task { }`, `.onAppear`, `.onChange`) that the framework calls
deliberately. Treat `body` exactly as you would treat a Quarkus
template expression: it reads the model and produces output, nothing
more.

## State primitives: where the truth lives

If views are disposable values recreated constantly, where does data
that *survives* re-renders live? In **property wrappers** that
SwiftUI manages outside the struct's lifetime. The struct is reborn
on every render; the state behind these wrappers persists. There are
four you need, and choosing the right one is most of what "thinking
in SwiftUI" means.

### `@State` — local source of truth

```swift
struct RootView: View {
    @State private var selection: AppTab = .home
    // ...
}
```

`@State` declares a piece of mutable state **owned by this view**.
The `RootView` struct is recreated on every render, but the `AppTab`
value behind `@State` lives in storage SwiftUI keeps alive across
those re-creations. When you write `selection = .docs`, two things
happen: the value updates, and SwiftUI marks `RootView`'s `body` for
recompute.

Rules of thumb, anchored to your instincts:

- `@State` is **private** and small. It is the view's own scratch
  memory — a selected tab, a toggle, the text in a field. Think
  request-scoped local state, not a shared bean.
- It is the **single source of truth** for that piece of data. The
  screen renders *from* it; nothing else owns it.
- Initialize it inline with a default. SwiftUI uses that only on
  first creation, then preserves the live value.

Notice `AlltagApp` also uses `@State` for `env`, the whole DI
container. That is the second valid use of `@State`: holding a
reference-type model you want to *create once and keep alive* for
the lifetime of the view. `@State` here isn't "small local data" —
it's "I own this object and it must outlive my re-renders."

### `@Binding` — a two-way reference to someone else's state

A child view often needs to *read and write* state owned by a
parent. It must not copy it (copies don't write back) and it must
not own it (the parent already does). `@Binding` is a typed
read/write reference into another view's source of truth.

Look at how `RootView` hands its `selection` to `TabView`:

```swift
TabView(selection: $selection) {
    // ...
}
```

The `$` is the key. Every `@State` (and several other wrappers)
exposes a **projected value** reachable with the `$` prefix. For
`@State var selection`, plain `selection` is the `AppTab` value, and
`$selection` is a `Binding<AppTab>` — a two-way handle. `TabView`
takes that binding so that when the user taps a tab, `TabView`
writes the new value *back through the binding* into `RootView`'s
`@State`. The arrow goes both ways: parent → child for display,
child → parent for edits.

If you have used `&` to pass an out-parameter in C, or an
`AtomicReference` you hand to a collaborator so it can mutate the
referent, that is the shape of a `Binding`: a reference to a slot,
not the value in it. The closest everyday Java analogy is passing a
setter+getter pair as a single object.

> **Note.** The split is simple: own state with `@State`, lend it
> with `$state` as a `Binding`, receive it with `@Binding`. A
> `Binding` never creates a new source of truth — it always points
> at one that lives somewhere else. Unidirectional data flow holds:
> there is exactly one owner per piece of state, and edits route back
> to that owner.

### `@Observable` + `@Environment` — shared, injected state

`@State` and `@Binding` cover state that lives *in the view tree*.
But cross-cutting state — the logged-in user, the persistence layer,
the selected language and theme — should live in a **model object**
shared across many screens, exactly like an injected
application-scoped bean in Quarkus. SwiftUI's modern answer is the
`@Observable` macro:

```swift
@Observable
final class AppEnvironment {
    var language: AppLanguage
    var theme: ThemeSetting
    // ... persistence, etc.
}
```

(`AppEnvironment` in Alltag is the DI container holding language,
theme, and persistence.) Marking a class `@Observable` makes SwiftUI
track reads of its properties automatically. A view that reads
`env.language` is recomputed when — and only when — `language`
changes. You get per-property reactivity for free, no annotations on
each field.

How does a deeply nested view *get* the shared model without
threading it through every initializer? Through the **environment**,
SwiftUI's built-in dependency injection. The app injects it once:

```swift
RootView()
    .environment(env)
```

and any descendant pulls it out by type:

```swift
struct RootView: View {
    @Environment(AppEnvironment.self) private var env
    // ...
}
```

`@Environment(AppEnvironment.self)` means "find the
`AppEnvironment` that an ancestor put into the environment and bind
it here." This is CDI for the view tree: `.environment(env)` is the
producer/binding, `@Environment(...)` is the injection point, and
the type is the lookup key. No view in between needs to know the
model exists. When `env`'s observed properties change, every view
that read them re-renders.

> **Quarkus analogy.** `.environment(env)` is `@Produces` for an
> application-scoped bean; `@Environment(AppEnvironment.self)` is the
> matching `@Inject`. The difference is scope: the environment is
> scoped to a *subtree* of the UI, so children can override what
> ancestors provided — a feature plain CDI doesn't give you.

### `@Bindable` — bindings into an `@Observable`

One gap remains. From `@State` you get bindings with `$`. But
`@Environment(AppEnvironment.self) var env` is a plain reference, not
a binding source — how do you hand a `TextField` a two-way binding
to `env.language`? You re-wrap it with `@Bindable`:

```swift
@Bindable var env = env
TextField("name", text: $env.userName)
```

`@Bindable` takes an `@Observable` object and lets you project
bindings (`$env.userName`) into its individual properties. Use it
when a control needs to *write back* into a shared model. Reading
alone needs only `@Environment`; two-way editing of a model property
needs `@Bindable` to mint the binding.

The full picture, four wrappers, one decision tree:

| Wrapper | Use when |
|---|---|
| `@State` | This view owns the truth |
| `@Binding` | You edit a parent's truth |
| `@Environment` | You read injected shared state |
| `@Bindable` | You edit an `@Observable`'s field |

## The old pattern you will still see

Before the `@Observable` macro (pre-iOS 17), shared models used the
`ObservableObject` protocol, marked changing fields with
`@Published`, were owned with `@StateObject`, and injected with
`@EnvironmentObject` / `@ObservedObject`. You will meet this in
tutorials and older code:

```swift
// Older code you'll see — not how Alltag writes it:
final class OldEnv: ObservableObject {
    @Published var language: AppLanguage = .de
}
```

It works, but it is coarser (any `@Published` change notifies *all*
observers, not just those reading that field) and noisier (every
field needs `@Published`). **Modern code uses `@Observable`.** When
you start a new model, reach for `@Observable`; only touch
`ObservableObject` when maintaining existing code.

## View identity and lifetime

Since views are recreated constantly, how does SwiftUI know that
"this `HomeView` now" is the same one as "that `HomeView` a frame
ago" — so it can *preserve* its `@State` rather than reset it? By
**identity**. By default, a view's identity is its position in the
view tree (structural identity). In a `ForEach`, identity comes from
an explicit ID:

```swift
ForEach(AppTab.allCases) { tab in
    screen(for: tab)
        .tabItem {
            Label(tab.titleKey, systemImage: tab.systemImage)
        }
        .tag(tab)
}
```

`AppTab` is `Identifiable` (its `id` is the raw string), so `ForEach`
tracks each generated screen by that stable id. Identity is what ties
the disposable view *value* to the persistent *state* behind its
wrappers. Change a view's identity and SwiftUI tears down its state
and builds fresh; keep it stable and the state rides along across
every re-render. This is why `Identifiable` ids must be stable and
unique — they are the primary keys of your UI.

## Previews

One payoff of value-type views: you can construct any screen in
isolation, no running app, no simulator boot, no navigating five
taps deep. The `#Preview` macro renders a view live in Xcode's
canvas:

```swift
#Preview {
    RootView()
        .environment(AppEnvironment.live())
}
```

Because `RootView` is just a value and its dependency arrives through
`.environment(...)`, the preview wires up a real `AppEnvironment` and
shows the whole tab shell instantly. This is the unit-test
ergonomics of pure functions applied to UI: deterministic input
(injected state) in, rendered view out. Build models to be
constructible in a preview and your UI becomes as testable as your
service layer.

## Takeaways

- A SwiftUI `View` is a value-type `struct` describing UI for the
  current state — not a retained, mutable object (UIKit) and not a
  one-shot server template. SwiftUI re-runs `body` on state change
  and diffs the result onto real views.
- `body: some View` returns one hidden concrete `View` type. Keep
  `body` cheap and side-effect-free; it may run constantly.
- Four state primitives: `@State` (own the truth), `@Binding` +
  `$projection` (edit a parent's truth), `@Observable` model via
  `@Environment` (read injected shared state), `@Bindable` (edit an
  observable's field). One owner per piece of state; edits flow back
  to it — unidirectional data flow.
- `.environment(env)` plus `@Environment(AppEnvironment.self)` is
  CDI for the view tree, scoped to a subtree.
- Modern code uses the `@Observable` macro;
  `ObservableObject`/`@Published`/`@StateObject` is the older pattern
  you'll still read.
- View identity (structural, or `Identifiable` id in `ForEach`) ties
  disposable view values to persistent wrapped state. `#Preview`
  renders any view in isolation by injecting its dependencies.

**Next:** *Layout: Stacks, Modifiers, and the Layout System*
