# Layout: Stacks, Modifiers, and the Layout System

You know how to declare a view and where its state lives. Now: how
does it get *positioned and sized*? SwiftUI has no `<div>`, no
absolute coordinates you set, no constraint solver you configure by
hand (UIKit's Auto Layout did that, and it was miserable). Instead it
uses a small, predictable size-negotiation algorithm plus composable
**stacks** and **modifiers**. Once you internalize the negotiation,
layout stops being guesswork.

## Stacks: the three containers

Almost all layout is three container views that arrange their
children along an axis:

- `HStack` — children left-to-right (a row).
- `VStack` — children top-to-bottom (a column).
- `ZStack` — children back-to-front (overlapping, shared center).

You saw all the pieces in the placeholder screen:

```swift
ZStack {
    AppColor.paper.ignoresSafeArea()
    VStack(spacing: 12) {
        Image(systemName: systemImage)
            .font(.system(size: 44))
            .foregroundStyle(AppColor.primary)
        Text(titleKey)
            .font(.title2.weight(.semibold))
            .foregroundStyle(AppColor.ink)
        Text("placeholder_coming_soon")
            .font(.subheadline)
            .foregroundStyle(AppColor.inkSoft)
    }
    .padding()
}
```

The `ZStack` layers a full-bleed paper background behind a centered
`VStack` of icon + two text lines. The `VStack` stacks its three
children vertically with `12` points between each.

### Alignment and spacing

Each stack takes an `alignment` and a `spacing`:

```swift
VStack(alignment: .leading, spacing: 12) { ... }
HStack(alignment: .top, spacing: 8) { ... }
```

The crucial subtlety: **alignment is on the cross axis.** A `VStack`
arranges *vertically*, so its `alignment` controls *horizontal*
placement (`.leading`, `.center`, `.trailing`). An `HStack`'s
alignment is *vertical* (`.top`, `.center`, `.bottom`). `spacing` is
along the main axis — the gap *between* children. Omit `spacing` and
SwiftUI picks a sensible default per platform; pass `0` to butt
children together.

> **Note.** `.leading` and `.trailing`, not left/right. In Alltag,
> `RootView` sets `.environment(\.layoutDirection,
> env.language.layoutDirection)` so Arabic flips the whole UI to RTL.
> Because you wrote `.leading` (not `.left`), every stack mirrors for
> free. Hard-coded `.left` would break right-to-left users. Always
> think in leading/trailing.

### Spacer and frame

A `Spacer` is a greedy empty view that expands to fill available
space along its stack's axis, pushing siblings apart:

```swift
HStack {
    Text("Alltag")
    Spacer()         // shoves the gear to the trailing edge
    Image(systemName: "gearshape")
}
```

`frame` constrains or expands a view's size:

```swift
Image(systemName: "house")
    .frame(width: 44, height: 44)        // fixed
Text("Hi").frame(maxWidth: .infinity)    // grow to fill width
```

`maxWidth: .infinity` is the SwiftUI idiom for "take all the width
my parent offers" — used constantly to make cards and rows fill
their container.

## Modifiers: order matters

This is the part that trips up everyone from a CSS background. A
**modifier** is a method on a view that returns a *new view wrapping
the original*. `someView.padding()` does not mutate `someView`; it
returns a `Padding<SomeView>` value. Chaining modifiers builds an
onion of wrapper views from the inside out. Because each modifier
operates on the result of the previous one, **order changes the
result.**

The canonical example — padding vs. background:

```swift
// A: pad first, then background
Text("Hi")
    .padding()
    .background(AppColor.card)

// B: background first, then pad
Text("Hi")
    .background(AppColor.card)
    .padding()
```

In **A**, `.padding()` wraps the text in 16 points of space, *then*
`.background` colors that padded region — you get a colored card with
the text inset and breathing room inside. In **B**, `.background`
colors the tight text bounds first, *then* `.padding` adds
*transparent* space around the already-colored box — a small colored
chip with empty margin around it. Same modifiers, opposite visuals,
purely from order.

CSS muddies this intuition. In CSS, `padding` and `background` are
properties of one box and there is no ordering between them. SwiftUI
has no "box with properties"; it has a *pipeline of nested views*,
and each modifier sees only what is inside it. Read a modifier chain
inside-out, like nested function calls: `background(padding(text))`
vs. `padding(background(text))`. That reframing makes the difference
obvious.

> **Gotcha.** When a card looks wrong, suspect modifier order before
> anything else. Background bleeding to the wrong bounds,
> tap-targets the wrong size, a `cornerRadius` clipping the inset
> instead of the fill — almost always an ordering bug. Sketch the
> onion: which modifier wraps which?

## The layout algorithm: a three-step negotiation

Here is the mental model that explains everything. SwiftUI lays out
in a single top-down then bottom-up pass, and for every parent/child
pair it is three steps:

1. **The parent proposes a size.** The root is proposed the safe-area
   rectangle. Each container proposes some size to each child (a
   `VStack` proposes its full width and a share of height; a frame
   proposes its fixed dimensions; and so on).
2. **The child chooses its own size.** The child is *not* forced to
   take what was proposed. A `Text` takes only as much width as its
   glyphs need (then wraps). An `Image` takes its intrinsic size.
   `Color` and `Spacer` greedily take everything offered. `frame`
   reports the size you asked for. The child returns *its* chosen
   size.
3. **The parent positions the child.** Knowing the child's chosen
   size, the parent places it within its own bounds per the
   alignment.

The whole tree is this conversation, recursively. The parent
*proposes*, never *dictates*; the child *decides*. This is the
inverse of Auto Layout, where you wrote constraints and a solver
reconciled them globally. SwiftUI's local, two-way negotiation has no
solver and no constraint conflicts — but you must reason about who
proposes and who chooses.

This single model explains the FAQs:

- *Why doesn't my `Text` fill the width?* Because in step 2 `Text`
  chooses its glyph width, ignoring the wider proposal. Force it with
  `.frame(maxWidth: .infinity)` so the frame (which *does* accept the
  proposal) reports full width.
- *Why does `Color` fill everything?* Because in step 2 `Color`
  accepts any proposal — it is greedy. That is exactly why
  `AppColor.paper.ignoresSafeArea()` works as a full-screen
  background in the placeholder.
- *Why does `.padding()` shrink the proposal?* Because padding
  subtracts its inset from the proposal before passing it to its
  child, then reports the child's size plus the inset.

## GeometryReader: use sparingly

Sometimes a child needs the actual proposed size — to draw something
proportional, say half the parent's width. `GeometryReader` exposes
it:

```swift
GeometryReader { proxy in
    Rectangle()
        .frame(width: proxy.size.width * 0.5)
}
```

The catch, straight from the algorithm: `GeometryReader` is greedy —
in step 2 it accepts the *entire* proposed size, like `Color`. Drop
one into a `VStack` and it expands to fill, shoving your other
content. So use it in leaf positions, scoped tightly, only when you
genuinely need a measured dimension. Reaching for `GeometryReader` to
solve a layout that stacks, frames, and alignment could handle is the
most common SwiftUI anti-pattern. Try the negotiation first.

## Scrolling and lazy content

`ScrollView` makes its content scrollable. By itself it does *not*
arrange anything — pair it with a stack:

```swift
ScrollView {
    VStack(spacing: 16) { /* rows */ }
}
```

A plain `VStack` builds *all* children immediately. For a long or
unbounded list that is wasteful, so use the lazy variants, which
build children only as they scroll into view:

- `LazyVStack` / `LazyHStack` — lazy linear stacks inside a
  `ScrollView`.
- `LazyVGrid` / `LazyHGrid` — lazy grids defined by `GridItem`
  columns.
- `Grid` — a non-lazy, true 2-D grid with aligned rows and columns,
  for small fixed layouts (like a form-ish table).

Rule of thumb: bounded, small content → `VStack`/`Grid`; long or
data-driven content → `Lazy*` (or `List`, covered next chapter, which
is lazy and adds platform row styling).

### Safe area

The **safe area** is the region clear of the notch, home indicator,
status bar, and tab bar. SwiftUI insets your content to it by
default — which is why your text never hides under the clock. A
*background* should usually ignore it to reach the screen edges,
exactly as the placeholder does:

```swift
AppColor.paper.ignoresSafeArea()
```

The paper color floods the entire screen; the foreground `VStack`
stays safely inset. Ignore the safe area for decoration, respect it
for content.

## Adaptive layout: Dynamic Type and never hard-coding sizes

iOS users can scale text system-wide (accessibility, large-text
modes). A layout that hard-codes point sizes ignores that setting and
breaks for those users. Alltag's typography is deliberately built to
scale. The *entire* font styling is one root modifier:

```swift
extension View {
    /// Applies the app's rounded type design to this subtree.
    func appFontDesign() -> some View {
        fontDesign(.rounded)
    }
}
```

applied once in `RootView` as `.appFontDesign()`. Note what it does
*not* do: it sets the *design* (rounded SF Pro) but never a point
size. Throughout the app, text uses **semantic font roles** —
`.title2`, `.subheadline`, `.body` — as in the placeholder:

```swift
Text(titleKey).font(.title2.weight(.semibold))
Text("placeholder_coming_soon").font(.subheadline)
```

Semantic roles scale automatically with the user's Dynamic Type
setting; `.font(.system(size: 17))` would not. (The icon's
`.font(.system(size: 44))` is the deliberate exception — a glyph, not
body text.) Because the design is applied once at the root and
cascades down the view tree, every screen inherits rounded, scalable
type with zero per-view ceremony. This is the layout payoff of the
modifier model: a single modifier on `RootView` reaches every
descendant.

> **Quarkus analogy.** `.appFontDesign()` at the root is like setting
> a base theme in your master Qute template that every page extends —
> define it once, every screen inherits it. The difference is that
> SwiftUI's cascade flows through the *runtime* view tree via the
> environment, so a subtree can override it locally without touching
> the root.

## Color and light/dark via semantic tokens

The same "define once, resolve at use" philosophy drives color.
Alltag never writes a raw hex in a view; it uses **semantic tokens**
from `AppColor`, each a dynamic light/dark pair:

```swift
enum AppColor {
    static let paper =
        dynamic(light: 0xFAF8F4, dark: 0x1B1916)
    static let ink =
        dynamic(light: 0x2B2722, dark: 0xF2EEE6)
    static let primary =
        dynamic(light: 0x2BA39A, dark: 0x35B6AC)  // teal
}
```

Each token resolves to the right shade for the active `ColorScheme`
*automatically* — the `dynamic` helper wraps a `UIColor` that picks
its value from the current trait collection. A view just says
`.foregroundStyle(AppColor.ink)` and gets dark ink in light mode,
light ink in dark mode, no conditionals. The names are *semantic*
(`paper`, `ink`, `primary`), not literal (`beige`, `tealHex`), so the
palette is a single reviewable file and a redesign touches one place,
not every view. This is exactly how you'd centralize a color scheme
behind named constants on the server — except these constants are
*context-resolving*, returning a different value per appearance mode
at render time.

The app-wide accent uses the same token. `RootView` applies:

```swift
.tint(AppColor.primary)
.appFontDesign()
.preferredColorScheme(env.theme.theme.colorScheme)
```

`.tint(AppColor.primary)` cascades the teal accent to interactive
elements (selected tab, buttons) across the whole tree.
`.preferredColorScheme(...)` lets the user's theme setting *force*
light or dark (or follow the system when nil). All three are root
modifiers cascading to every screen — the modifier-cascade pattern
doing triple duty: font, color accent, and appearance, each defined
once.

## Takeaways

- Layout is `HStack`/`VStack`/`ZStack` plus `Spacer`, `padding`, and
  `frame`. A stack's `alignment` is the *cross* axis; `spacing` is
  the main axis. Use `.leading`/`.trailing`, not left/right, so RTL
  (Arabic) mirrors for free.
- Modifiers wrap views into a nested onion — `someView.padding()`
  returns a new view. **Order matters**: pad-then-background vs.
  background-then-pad give different results. Read chains inside-out.
- The layout algorithm is a 3-step negotiation: parent *proposes* a
  size, child *chooses* its own, parent *positions* it. This single
  model explains why `Text` won't fill width, why `Color`/`Spacer`
  are greedy, and what `padding`/`frame` do.
- `GeometryReader` is greedy and should be used sparingly, only as a
  scoped leaf. Use `ScrollView` + `Lazy*` for long content; respect
  the safe area for content, ignore it for backgrounds.
- Never hard-code point sizes: `.appFontDesign()` sets design once at
  the root and views use semantic roles (`.title2`) so Dynamic Type
  scales. Color uses `AppColor` semantic light/dark tokens that
  resolve to the active `ColorScheme`; `.tint`, `.appFontDesign`, and
  `.preferredColorScheme` cascade from `RootView` to every screen.

**Next:** *Building Screens: Lists, Navigation, Forms, Tabs*
