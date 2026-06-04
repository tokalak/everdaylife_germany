# Preface {.unnumbered}

You are a backend engineer. You know Java well, you are productive in Quarkus,
and you can reason about types, concurrency, build pipelines, and tests without
anyone holding your hand. This book does not treat you like a beginner. It
treats you like an expert in a *neighbouring* field who needs a fast, honest
map of a new one.

The goal is narrow and practical: **take you from "I know the JVM" to "I can
build, test, and ship an iOS app to the App Store."** Not someday — on a
realistic timeline, studying in your own free time.

## How this book is different

Most Swift tutorials assume you have never programmed. They spend three chapters
on variables and loops. You do not need that, and reading it would waste the one
resource you are short on: time. So this book does three things differently.

**It teaches by delta.** For every new concept, the first question is "what is
the closest thing you already know in Java or Quarkus?" — and the second is
"where does that analogy break?" A Swift `struct` is *almost* a Java `record`,
until you learn it has value semantics and mutating methods. An `@Observable`
class is *almost* a CDI bean, until you see the SwiftUI render loop. The
analogies get you 80% of the way in one sentence; the rest of the section is the
20% that actually matters.

**It is grounded in a real app.** Throughout, the running example is **Alltag** —
a privacy-first iOS companion for navigating everyday German bureaucracy: an
encrypted on-device document vault, an on-device LLM that decodes official
letters, deadline tracking, and a multilingual UI (including right-to-left
Arabic). It is a paid app with no backend: everything happens on the device.
That makes it an unusually good teacher, because it exercises the parts of iOS
that backend engineers find most foreign — local persistence, encryption,
the Keychain, app lifecycle, signing — rather than just calling a REST API. The
code in this book is the *actual* code from that project, not toy snippets.

**It respects "the essence."** Swift and iOS are vast. This book deliberately
omits the long tail: UIKit (the old imperative framework), Objective-C interop,
Combine, the dozens of niche APIs you can look up when you need them. What
remains is the load-bearing 20% that you will use every day, taught properly.

## How it is organised

- **Part I — The Swift Language.** The language itself, mapped onto your Java
  knowledge: value vs. reference types, optionals, errors, protocols, generics,
  closures, and the concurrency model (ARC, `async`/`await`, actors).
- **Part II — SwiftUI.** Declarative UI: how views are pure functions of state,
  how state and dependencies flow, layout, real screens, app architecture, and
  on-device persistence with SwiftData, the Keychain, and CryptoKit.
- **Part III — Ship It.** The ecosystem: Xcode and the build system, testing and
  CI, the famously confusing world of code signing, and the full path through
  App Store Connect, TestFlight, and review to a live release.
- **Appendices.** A Java-to-Swift cheat sheet, a catalogue of gotchas that
  specifically trip up Java developers, a week-by-week study plan, and a curated
  resource list.

You can read Part I linearly, then dip into Parts II and III as you build. The
appendices are meant to be kept open in a second window.

## What you need

A Mac and a free copy of **Xcode** from the Mac App Store. That is enough for
everything in Parts I and II and most of Part III — you can build, run in the
Simulator, and write tests without paying anyone. The **Apple Developer
Program** (99 € / year) is required only for the final step: running on your own
iPhone and submitting to the App Store. We will be explicit about where that
line is.

> **A note on conventions.** Code you will recognise as Swift is shown in
> `monospace`. Boxed asides like this one flag three recurring things: a
> **Quarkus analogy** that ports your intuition, a **Gotcha** that catches Java
> developers specifically, and a plain **Note** for everything else. When the
> text says "see *Chapter Title*," it means another chapter in this book.

Let us begin where every backend engineer's mental model needs its first
correction: the shape of the iOS world itself.
