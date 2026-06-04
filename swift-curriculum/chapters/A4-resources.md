# Curated Resources

This is a short, opinionated list — the resources worth your time, not an
exhaustive link dump. Everything here is either canonical (Apple's own) or has
earned a durable reputation. Each entry says *why* it matters to someone with
your background.

## Read these first

| Resource | What it is | Why for you |
|---|---|---|
| *The Swift Programming Language* | The official language book, free online | The authoritative reference; skim, then keep as a lookup |
| Apple **SwiftUI Tutorials** | Guided, hands-on projects | The fastest way to internalise the view-and-state loop |
| **Human Interface Guidelines** | Apple's design rules | What reviewers expect; saves rejections |
| Swift API **Design Guidelines** | Naming and idiom conventions | Makes your code read like Swift, not ported Java |

The Swift book lives at `docs.swift.org`; the tutorials and guidelines are on
`developer.apple.com`. Bookmark all four.

## When you are stuck on SwiftUI

- **Hacking with Swift** (Paul Hudson) — `hackingwithswift.com`. The "100 Days
  of SwiftUI" course and the searchable how-to library are the single best
  free SwiftUI resource. When you hit "how do I do X in SwiftUI," this is the
  first search.
- **SwiftUI Field Guide** — `swiftui-lab.com` and the interactive
  `swiftuifieldguide.com` — for genuinely understanding the layout system when
  the three-step negotiation stops being intuitive.
- **Stack Overflow** — still useful, but check the date: pre-2023 SwiftUI
  answers often predate `@Observable`, `NavigationStack`, and SwiftData.

## When you want depth

- **WWDC sessions** (in the Developer app or on `developer.apple.com/videos`).
  The ones worth your time early: "Discover Observation in SwiftUI," "Meet
  SwiftData," "Meet Swift Testing," "Migrate to Swift 6," and any year's "What's
  new in SwiftUI." Watch at 1.5x; they are dense and accurate.
- **Point-Free** (`pointfree.co`) — advanced, opinionated Swift on architecture,
  dependencies, and testing. Paid, and occasionally over-engineered for app
  work, but it will sharpen how you think about composition and side effects.
  Especially relevant given your interest in clean dependency injection.
- **Swift Forums** (`forums.swift.org`) — where the language is actually
  designed. Read the "Evolution" category to understand *why* Swift is shaped
  the way it is; as a language-design-literate engineer you will enjoy it.

## Tools worth installing

| Tool | Purpose | Note |
|---|---|---|
| **XcodeGen** | Project file from YAML | Already used by Alltag |
| **xcbeautify** | Readable `xcodebuild` logs | Pairs with `ci.sh` |
| **SwiftLint** | Style/lint enforcement | Like Checkstyle/PMD |
| **swift-format** | Auto-formatter | Like google-java-format |
| **SF Symbols** app | Browse system icons | Names like `house`, `folder` |

`brew install xcodegen xcbeautify swiftlint swift-format`. The **SF Symbols**
app is a free download from Apple and is how you find icon names like the ones
in Alltag's `AppTab` (`doc.text.viewfinder`, `gearshape`).

## Staying current

- **iOS Dev Weekly** (`iosdevweekly.com`) — a Friday newsletter, the canonical
  way to keep a finger on the ecosystem without doom-scrolling.
- **Swift by Sundell** (`swiftbysundell.com`) — articles and a podcast; reliably
  high quality on practical patterns.
- **Mastodon / the Swift community** — many core team members and prominent
  developers post there; a better signal-to-noise ratio than most feeds.

## For your specific app

*Alltag* leans on a few areas with their own primary sources worth knowing:

| Topic | Where to look |
|---|---|
| On-device encryption | Apple **CryptoKit** docs; the Keychain Services guide |
| Local LLM inference | The **llama.cpp** repository and its Metal backend |
| SwiftData modelling | "Meet SwiftData" + "Model your schema" WWDC sessions |
| Localization | "Discover String Catalogs" WWDC session |
| Privacy manifests | Apple's "Privacy manifest files" documentation |

## A closing note

You have an advantage most people learning iOS do not: you already know how to
build software that matters, reason about types and concurrency, and ship under
constraints. What remained was a new language, a new UI paradigm, and an
unfamiliar release pipeline. That is exactly what this book covered — and now
you have both the map and a real app to practise on.

Build the capstone. Ship it. Then come back and re-read the chapter that gave
you the most trouble; it will read completely differently from the other side
of a shipped app.

**Next:** nothing — close the book and open Xcode.
