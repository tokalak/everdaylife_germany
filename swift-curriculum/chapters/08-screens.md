# Building Screens: Lists, Navigation, Forms, Tabs

By now you can compose a view and lay it out. This chapter
assembles those primitives into *real screens*: a tabbed
shell, drill-down navigation, scrollable lists, data-entry
forms, and the modal surfaces (sheets, alerts) that sit on
top. Everything here maps to things you have built a hundred
times on the server and the web — a router, a list endpoint
rendered to a table, a form POST — except the framework is
declarative and the "router" is a value you mutate.

We anchor every primitive to the Alltag app: a five-tab,
on-device German-bureaucracy companion. Its shell, tabs, and
Settings screen are real code we will read verbatim.

## The tab shell: `TabView`

The top-level container for most iOS apps is `TabView`. Think
of it as the app's coarse router — the equivalent of the
top-level path segments (`/home`, `/docs`, `/settings`) that
a Quarkus REST app exposes via JAX-RS `@Path`. The difference:
there is no dispatch on a request. The selected tab is a piece
of state, and SwiftUI re-renders when it changes.

Alltag's information architecture fixes five destinations, with
Decode deliberately in the center. Rather than inline the tabs
in the view, the app models them as an `enum`:

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

`CaseIterable` gives a synthesized `allCases` — your enum
becomes its own ordered registry. `Identifiable` (here `id`
is the `rawValue`) lets `ForEach` iterate it. Modeling tabs
as a type means the set and its ordering are testable and the
center placement is explicit, not a fragile consequence of
view declaration order. This is the kind of small thing a
backend engineer appreciates: configuration as data.

The shell that consumes it, `RootView`:

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
        .appFontDesign()
        .environment(\.locale, env.language.locale)
        .environment(\.layoutDirection,
                     env.language.layoutDirection)
        .preferredColorScheme(env.theme.theme.colorScheme)
    }

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
}
```

Three load-bearing pieces:

- `TabView(selection: $selection)` binds the active tab to
  state. The `$` makes a two-way `Binding` — when the user taps
  a tab, SwiftUI writes back into `selection`. (Bindings are
  covered in the architecture chapter; for now: a writable
  reference to state.)
- `.tabItem { Label(...) }` declares the bar item. `Label`
  pairs a localized title with an SF Symbol (`systemImage`).
  SF Symbols are Apple's bundled icon font — no asset import.
- `.tag(tab)` associates each tab's content with its `AppTab`
  value so `selection` can identify it. The tag type must match
  the selection type.

The modifiers chained after `TabView` apply app-wide: tint
color, font design, locale, layout direction, and color scheme.
Note `@ViewBuilder` on `screen(for:)` — it lets a function whose
branches return *different* view types compile as a single
`some View`, the way the `body` property itself works.

A subtlety that catches server engineers: `TabView` keeps every
tab's view *alive*. Switching from Decode to Settings and back
does not reconstruct `DecoderView` — its `@State` survives. This
is the opposite of a stateless HTTP handler, where each request
rebuilds everything. The view tree is long-lived and SwiftUI
mutates it in place; reach for that model whenever you wonder
"will my scroll position / partially typed text survive a tab
switch?" It will. Conversely, do not stash request-scoped junk
in a tab's `@State` expecting it to reset — it won't.

> **Quarkus analogy.** `TabView` is your top-level router and
> `AppTab` is the route table. But there is no servlet
> dispatch and no request lifecycle — the "current route" is
> just a `@State` value, and switching tabs keeps all five
> screens alive (their state persists), unlike a stateless HTTP
> handler that is reconstructed per request.

## Drill-down: `NavigationStack`

Tabs are lateral. To push a detail screen on top of a list —
the bureaucratic-letter list to a single letter's decoded
view — you need a navigation stack.

Modern SwiftUI uses **`NavigationStack`**. You will see older
tutorials use `NavigationView`; it is deprecated and behaves
differently (it doubles as a split view on iPad and has
murkier programmatic control). Treat `NavigationView` as
legacy. Always reach for `NavigationStack`.

The simplest form wraps a root and reacts to `NavigationLink`s:

```swift
NavigationStack {
    List(letters) { letter in
        NavigationLink(letter.subject) {
            DecodedLetterView(letter: letter)
        }
    }
    .navigationTitle("tab_decode")
}
```

For anything beyond toy apps, prefer **path-based**
navigation: the stack is driven by an explicit array you own.
This is the SwiftUI feature that finally makes navigation feel
like server-side routing — deep links, "pop to root," and
restoring a navigation path become array mutations.

```swift
@State private var path: [Letter] = []

var body: some View {
    NavigationStack(path: $path) {
        List(letters) { letter in
            NavigationLink(letter.subject, value: letter)
        }
        .navigationDestination(for: Letter.self) { letter in
            DecodedLetterView(letter: letter)
        }
    }
}
```

`NavigationLink(value:)` does not name a destination view; it
appends a *value* to `path`. A `.navigationDestination(for:)`
modifier declares, "when a `Letter` is on the stack, render
it like this." That decoupling is the point — you can also push
programmatically with `path.append(letter)`, clear the whole
stack with `path.removeAll()`, or restore a saved path on
launch. The destination type must conform to `Hashable`.

> **Gotcha.** `.navigationTitle`, `.toolbar`, and
> `.navigationDestination` attach to the *content inside* the
> stack, not to `NavigationStack` itself. Put them on the
> `List` (or root view), not on the wrapper. A title set on the
> `NavigationStack` line silently does nothing.

## Lists

`List` is the workhorse for vertical, scrollable, row-based
content — the screen equivalent of rendering a query result to
an HTML table, except it virtualizes rows for you.

Static rows read like markup:

```swift
List {
    Text("Anmeldung")
    Text("Steuer-ID")
    Text("Aufenthaltstitel")
}
```

Dynamic rows iterate a collection. As with `ForEach`, SwiftUI
needs a stable identity per row to diff updates, so the element
type conforms to `Identifiable`:

```swift
List(documents) { doc in
    Label(doc.title, systemImage: doc.icon)
}
```

`Identifiable` is the SwiftUI analogue of a JPA `@Id`: a stable
key the framework uses to track a row across re-renders, decide
what animates, and recycle views. Without it, deletions and
moves can animate the wrong row.

Group rows into **sections** and add headers:

```swift
List {
    Section("Pending") {
        ForEach(pending) { Text($0.title) }
    }
    Section("Filed") {
        ForEach(filed) { Text($0.title) }
    }
}
```

Rows can carry leading/trailing swipe actions — the iOS
gesture you use to delete a mail:

```swift
ForEach(documents) { doc in
    Text(doc.title)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                store.delete(doc)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
}
```

`role: .destructive` colors the button red and lets the OS
treat it as the default full-swipe action. The `.onDelete`
modifier offers a terser path when you only need delete.

For a long document list, add a search field with one modifier:

```swift
List(filtered) { doc in Text(doc.title) }
    .searchable(text: $query, prompt: "Search documents")
```

`.searchable` installs the system search bar and binds the
query to your state; you filter `documents` yourself in a
computed property. There is no server round-trip — filtering is
local, synchronous, over data already in memory. Treat it like
running a `Stream.filter` over a loaded collection, not like
issuing a new query endpoint.

Finally, the list's own lifecycle. Use `.task` to load data
when a screen appears:

```swift
List(documents) { doc in Text(doc.title) }
    .task { await store.load() }
```

`.task` runs an `async` closure when the view appears and
*cancels it automatically* when the view disappears — the
correct hook for fetching or, in Alltag, kicking off on-device
work. Prefer it over the older `.onAppear`, which is
synchronous and has no cancellation.

## Forms and controls

`Form` is a `List` styled for data entry — grouped, inset rows
with platform-correct spacing. It is where Alltag's Settings
live. The controls you will use constantly:

| Control | Purpose | Server analogue |
|---|---|---|
| `TextField` | single-line text | text input |
| `Toggle` | boolean | checkbox |
| `Picker` | one-of-N | select / radio |
| `Stepper` | bounded integer | number input |

A tour:

```swift
Form {
    Section("Reminder") {
        TextField("Title", text: $title)
        Toggle("Notify me", isOn: $notify)
        Stepper("Days before: \(days)",
                value: $days, in: 0...30)
        Picker("Persona", selection: $persona) {
            ForEach(Persona.allCases) { p in
                Text(p.label).tag(p)
            }
        }
    }
}
```

Every control binds to state with `$`. There is no submit
button and no form-encoded POST — the bindings *are* the
two-way data flow. The model updates as the user types or
taps; you read it whenever you need it. A backend engineer
should reframe a SwiftUI `Form` not as an HTML `<form>` you
serialize on submit, but as a live, bidirectional binding
between widgets and an in-memory model.

`Picker`'s `selection` must match the tag type of its options.
Each option carries `.tag(p)` so SwiftUI knows which value the
row represents — the exact mechanism you saw on `TabView`.

## Modals, alerts, and toolbars

Pushing onto a stack is one way to present; *covering* the
current screen is another. SwiftUI presents modals with view
modifiers driven by state, not by imperatively calling a
"present" method.

- `.sheet(isPresented:)` — a card that slides up, dismissible,
  partially covering. The default for most modal flows.
- `.fullScreenCover(isPresented:)` — opaque, full-screen;
  use for immersive flows like the camera capture in Decode.
- `.alert(_:isPresented:)` — a blocking system dialog with
  title and buttons.
- `.confirmationDialog(_:isPresented:)` — an action sheet of
  choices, good for "are you sure / pick one."

```swift
struct VaultView: View {
    @State private var showingScanner = false
    @State private var confirmDelete = false

    var body: some View {
        List { /* documents */ }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Scan") { showingScanner = true }
                }
            }
            .sheet(isPresented: $showingScanner) {
                ScannerView()
            }
            .alert("Delete document?",
                   isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) {}
                Button("Cancel", role: .cancel) {}
            }
    }
}
```

The pattern is uniform: a `Bool` (or optional value) drives
presentation, and the OS owns the lifecycle and the dismiss
gesture. Set the flag false — or let the user swipe down — and
the modal goes away. `.toolbar` declares bar buttons;
`placement` lets the OS position them correctly per platform
(and mirror them under RTL).

> **Note.** There is also `.sheet(item:)`, driven by an
> optional `Identifiable` value instead of a `Bool`. Prefer it
> when the sheet needs data: setting `item` to a non-nil
> document both presents the sheet and hands it the document,
> avoiding the classic "flag is true but the data is stale"
> bug.

Two presentation traps worth naming up front. First, modifier
*order* and *attachment point*: presentation modifiers attach to
the view they decorate, and the presented content is a sibling
of that view in the tree, not a child of wherever you "called"
present. In practice, attach `.sheet`/`.alert` to a stable
container (the `List`, the root of the screen), not to a
transient row, or the modal can dismiss itself when its host row
is recycled. Second, a sheet does *not* inherit the navigation
stack of the screen that presented it. If the sheet's content
needs its own push navigation or its own title bar, wrap that
content in its own `NavigationStack`. This surprises engineers
who expect a presented view to live "inside" the caller's route
the way a forwarded request shares a servlet context — it does
not; a sheet is a fresh presentation context.

## Localization: `LocalizedStringKey` and the catalog

You may have noticed Alltag passes bare strings like
`"tab_home"` and `"settings_appearance"` where you expected
display text. That is deliberate.

Most SwiftUI text-accepting APIs take a `LocalizedStringKey`,
not a `String`. When you write `Text("tab_home")`, the literal
is treated as a *key* and resolved at render time against the
app's **String Catalog** (`Localizable.xcstrings`). The
catalog is a JSON file Xcode manages; Alltag's holds:

```json
"tab_home" : {
  "localizations" : {
    "de" : { "stringUnit" :
      { "state" : "translated", "value" : "Start" } },
    "en" : { "stringUnit" :
      { "state" : "translated", "value" : "Home" } }
  }
}
```

So `Text(tab.titleKey)` renders "Start" in German and "Home"
in English. This is your resource bundle / `messages.properties`,
but type-aware: the compiler distinguishes a `LocalizedStringKey`
literal (looked up) from a `String` variable (shown as-is). A
`String` you pass through a variable is *not* localized — only
literals and explicit `LocalizedStringKey`s are.

That is why `AppTab.titleKey` is typed `LocalizedStringKey`
rather than `String`: it travels as a key, gets resolved late,
and lets the same enum serve all nine of Alltag's planned
languages.

### Locale and RTL

Selecting a language in Alltag does two environment writes on
the root, both visible back in `RootView`:

```swift
.environment(\.locale, env.language.locale)
.environment(\.layoutDirection, env.language.layoutDirection)
```

The first changes which catalog column resolves. The second
mirrors the entire layout for right-to-left scripts. Arabic is
RTL; everything else LTR:

```swift
var isRTL: Bool { self == .ar }

var layoutDirection: LayoutDirection {
    isRTL ? .rightToLeft : .leftToRight
}
```

Setting `\.layoutDirection` to `.rightToLeft` flips leading and
trailing, mirrors the tab bar and toolbars, and reverses swipe
edges — for free, because you used semantic `leading`/`trailing`
edges instead of hard-coded left/right. Build for RTL from day
one and it costs nothing later; retrofit it and you re-audit
every screen.

## Worked example: the Settings screen

Pulling the chapter together, here is Alltag's real
`SettingsView` — a `Form` inside a `NavigationStack`, reading
controllers from the injected environment, exposing a theme
picker and a language picker:

```swift
struct SettingsView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        NavigationStack {
            Form {
                Section("settings_appearance") {
                    Picker("settings_appearance",
                           selection: themeBinding) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.labelKey).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("settings_language") {
                    Picker("settings_language",
                           selection: languageBinding) {
                        ForEach(AppLanguage.selectable) {
                            language in
                            Text(language.endonym)
                                .tag(language)
                        }
                    }
                }
            }
            .navigationTitle("tab_settings")
        }
    }

    private var themeBinding: Binding<AppTheme> {
        Binding(
            get: { env.theme.theme },
            set: { env.theme.select($0) })
    }

    private var languageBinding: Binding<AppLanguage> {
        Binding(
            get: { env.language.language },
            set: { env.language.select($0) })
    }
}
```

Walk the moving parts:

- `@Environment(AppEnvironment.self)` reads the DI container
  injected at the app root. No singleton, no service locator —
  the container is handed down the view tree (architecture
  chapter next).
- The theme `Picker` iterates `AppTheme.allCases` and labels
  each with its `labelKey` (`appearance_system` /
  `appearance_light` / `appearance_dark`), resolved by the
  catalog. `.pickerStyle(.segmented)` renders the inline
  three-segment control.
- The language `Picker` iterates `AppLanguage.selectable` —
  today just `[.de, .en]`, even though the enum defines nine —
  and labels with `endonym`, each language in its own script
  ("Deutsch", "English"), so users recognize their own.
- `.tag(theme)` / `.tag(language)` give each row its value;
  the picker's `selection` type matches.

The bindings deserve a closer look. The controllers expose
`theme` and `language` as `private(set)` — read-only from
outside, mutated only through `select(_:)`, which also
persists to `UserDefaults`. A picker needs a *writable*
`Binding`, so Settings bridges read and write with a custom
`Binding(get:set:)`: read the current value, and on write,
route through `select(_:)` instead of assigning the property.

That indirection is not ceremony. `LanguageStore.select(_:)`
guards against picking a not-yet-localized language:

```swift
func select(_ language: AppLanguage) {
    guard language.isSelectable else { return }
    self.language = language
    defaults.set(language.rawValue, forKey: Self.storageKey)
}
```

A naive `selection: $env.language.language` would bypass that
guard and the persistence side effect. The explicit binding
keeps the controller the single point of truth for *how* a
selection takes effect. (When you have a `@Bindable` model and
no such guard, `$model.property` is the idiomatic shortcut —
the architecture chapter covers `@Bindable`.)

Because `ThemeController` and `LanguageStore` are `@Observable`
and `RootView` reads the same `env`, a tap here propagates
instantly: `select` mutates the controller, observation marks
the root dirty, and `RootView` re-applies `preferredColorScheme`
and `\.locale` across the whole app. One mutation, app-wide
effect, no notification plumbing.

## Takeaways

- `TabView` is the coarse router; model tabs as a `CaseIterable`
  `enum` (`AppTab`) for an explicit, testable, ordered set.
- Use `NavigationStack` (not the deprecated `NavigationView`).
  Path-based navigation with `.navigationDestination(for:)`
  turns routing into array mutation.
- `List`/`Form` render rows from `Identifiable` data; controls
  (`Picker`, `Toggle`, `TextField`, `Stepper`) bind two-way
  with `$` — no submit step.
- Modals are state-driven modifiers: `.sheet`, `.fullScreenCover`,
  `.alert`, `.confirmationDialog`. A `Bool` or optional drives
  presentation; the OS owns dismissal.
- Bare string literals in text APIs are `LocalizedStringKey`s
  resolved against the String Catalog; `\.locale` and
  `\.layoutDirection` switch language and RTL app-wide.
- Bridge read-only controllers to pickers with
  `Binding(get:set:)` so writes route through guarded,
  persisting `select(_:)` methods.

**Next:** Architecture: State, Dependencies, and the @Observable Environment
