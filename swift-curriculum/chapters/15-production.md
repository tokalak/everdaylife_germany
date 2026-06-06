# Production: Privacy, Crashes, Performance, and Updates

On a Quarkus service, "production" means a fleet you own: you tail
logs, scrape Prometheus, watch Sentry, and roll a new container when
something breaks. An iOS app inverts every one of those assumptions.
The **device is production**, you do not own it, you cannot SSH into
it, and — for *Alltag* — you have deliberately chosen to collect
nothing about it. This chapter walks the four things you still must
get right with no server underneath you: privacy declarations,
crash and metric observability, performance (including an on-device
LLM), and shipping updates.

## Privacy: declaring what you touch

A backend declares privacy in a GDPR record and a DPA. Apple wants
it *in the binary*. Two mechanisms matter.

### The Privacy Manifest

`PrivacyInfo.xcprivacy` is a property-list file you add to the app
target (and that every third-party SDK must now ship too). It
declares four things: data you collect, tracking, tracking domains,
and **required-reason APIs**. For *Alltag* the data and tracking
sections are almost empty — the app collects nothing and tracks
nothing — but the file is still mandatory.

```xml
<key>NSPrivacyTracking</key>
<false/>
<key>NSPrivacyCollectedDataTypes</key>
<array/>
<key>NSPrivacyTrackingDomains</key>
<array/>
```

The interesting part is **required-reason APIs**. Apple flags a set
of common APIs (file timestamps, `UserDefaults`, disk space, system
boot time) that have historically been abused for fingerprinting.
If you call one, you must declare an approved reason code, or App
Review rejects the upload. *Alltag* uses `UserDefaults` for theme
and language preferences, so it declares reason `CA92.1` (app's own
data, not shared). It checks free disk space before downloading the
2.62 GB model, so it declares the disk-space reason too.

> **Quarkus analogy.** Think of `PrivacyInfo.xcprivacy` as a
> `compile`-time SBOM for *behavior*, not dependencies. The
> linker-level manifest is checked at upload the way a strict
> license scanner gates a `mvn deploy` — except here a missing
> entry is a hard reject, not a warning.

### App Tracking Transparency

ATT is the `Ask App Not To Track` prompt. It is required only if you
track the user across other apps/sites or share data with data
brokers. *Alltag* does neither, so this is trivial: **no
`AppTrackingTransparency` import, no prompt, nothing to do.** That is
the whole point of the local-only design — entire categories of
compliance work simply evaporate. The privacy "nutrition label" on
the App Store product page reads *Data Not Collected*, which is also
a marketing asset for an app whose pitch is "your documents never
leave this phone."

## Crashes and observability with no server

Here is the uncomfortable truth: you have **no server logs**.
Nothing flows to a central place. When a `fatalError` fires on a
stranger's iPhone in Munich, you find out only if Apple's own
pipeline tells you.

### Xcode Organizer and MetricKit

Apple gives you two privacy-preserving channels, both opt-in by the
user via "Share With App Developers":

- **Organizer crash reports.** Symbolicated crash logs aggregated
  in Xcode's Organizer window, grouped by signature, with device
  and OS breakdowns. This is your Sentry — except it is sampled,
  delayed by hours to days, and only covers users who opted in.
- **MetricKit (`MXMetricManager`).** A daily on-device digest of
  launch time, hang rate, memory peaks, disk writes, battery, and
  crash diagnostics, delivered to your app the next day. You
  receive it locally and *could* forward it — but for *Alltag* that
  would mean adding a network call to a no-network app.

```swift
final class Metrics: NSObject, MXMetricManagerSubscriber {
    func didReceive(_ payloads: [MXMetricPayload]) {
        // Persist locally; never transmit.
        for payload in payloads {
            store.append(payload.jsonRepresentation())
        }
    }
}
```

### The telemetry tradeoff

On Quarkus you would not hesitate to wire Sentry — more signal is
strictly better. For *Alltag* it is a genuine conflict. Any crash
SDK (Sentry, Crashlytics, Bugsnag) opens a network connection,
ships device identifiers, and forces you to add data-collection
entries to the privacy manifest — directly contradicting the *Data
Not Collected* promise. So the decision is deliberate: **rely on
Apple's opt-in Organizer/MetricKit only, and forward nothing.** You
trade observability for an airtight privacy claim. That is the right
call here, but make it consciously — debugging a crash you cannot
reproduce, with no breadcrumbs, is the price.

> **Gotcha.** "I'll just log to a file and read it later" does not
> help: you have no way to retrieve that file from a user's device.
> The on-device crash log is only useful if Apple surfaces it in
> Organizer. Design for low crash *rates* (no force-unwraps, no
> `try!`), because your ability to *react* is structurally limited.

## Performance: Instruments and main-thread hygiene

Profile on a **real device**, never the Simulator — the Simulator
uses your Mac's CPU/GPU/RAM and lies about everything that matters,
especially Metal and memory pressure. Instruments is your profiler:

| Instrument | Finds | Backend analog |
|---|---|---|
| Time Profiler | CPU hot paths | async-profiler |
| Allocations | leaks, growth | heap dump / MAT |
| Hangs | main-thread stalls | event-loop block |
| SwiftUI | redundant redraws | — |

The cardinal rule: **the main thread renders the UI at up to 120
Hz, so it must never block.** SwiftUI views and observable UI state
should be `@MainActor`; anything expensive (file crypto, OCR, model
inference) must run off it. This is stricter than a Quarkus worker
thread — there, a slow request hurts one caller; here, a 200 ms
main-thread stall is a visible, juddering hang for the user holding
the phone.

```swift
@MainActor
final class DecodeViewModel: ObservableObject {
    @Published var result: DecodeResult?

    func decode(_ image: Data) async {
        // Inference runs off the main actor (see below);
        // only the assignment hops back on.
        result = await engine.decode(image)
    }
}
```

Watch **launch time** too. iOS will *kill* an app that takes too
long to launch (the watchdog), so never block `init` on heavy work
— lazy-load the model, the SwiftData store, and large content files.

### The on-device LLM is the performance story

*Alltag*'s Decoder runs **Gemma 4 E2B QAT, GGUF `UD-Q4_K_XL` (2.62 GB), on
`llama.cpp` with the Metal backend** — entirely on the phone. No
backend service exists. That makes the model the single biggest
performance concern in the app, and it touches every axis at once:

- **Model load time.** Reading 2.62 GB of weights into memory takes
  seconds. Load lazily, off the main actor, with a warm-up pass and
  a visible progress state — never on launch.
- **RAM footprint.** Weights plus KV cache can dominate the
  process's memory budget. iOS jetsams (force-kills) memory-hungry
  apps without warning. *Alltag* **caps context far below the
  model's 128K** (letters are short — 4–8K is plenty) to bound the
  KV cache, runs a single inference at a time, and unloads under
  memory pressure.
- **Why Q4 and Metal matter.** **Quantization** (Q4 = 4-bit
  weights) is what makes 2.3B effective parameters fit and run at
  all; full-precision weights would be several times larger and far
  slower. *Alltag* uses a **QAT** (quantization-aware training)
  build, which trains the model to tolerate 4-bit weights —
  recovering most of the accuracy a naive post-training quant would
  lose, at a smaller size. **Metal** moves the matrix math onto the GPU/Neural
  Engine instead of the CPU, which is the difference between a
  usable few-seconds decode and an unusable one. A low-RAM device
  may fall back to a smaller `UD-Q2_K_XL` quant; a too-small device is
  gated out with a clear message rather than crashed.
- **Thermals and battery.** Sustained inference heats the device
  and drains the battery; iOS responds by *throttling* the CPU/GPU,
  which slows the next decode. The Decoder is a short, on-demand
  burst (decode one letter, stop) — not a streaming chatbot — which
  keeps this bounded. Always run inference off the main actor so the
  UI stays at 60/120 Hz while the GPU is busy.

> **Note.** On a backend you would scale a slow model horizontally —
> add pods. On-device there is exactly one "pod," and it is also
> rendering the UI, playing audio, and trying not to get hot. Every
> millisecond and every megabyte is a fixed, non-elastic budget.

### App size and the shipped model

A multi-hundred-megabyte — here, multi-*gigabyte* — model is a real
shipping constraint. You **cannot bundle 2.62 GB into the app
binary**: the App Store cellular-download limit and review friction
make it impractical. *Alltag*'s answer is to **download the model on
first run** — resumable, Wi-Fi-recommended, checksum-verified — and
store it in Application Support, **excluded from iCloud/iTunes
backup** (it is large and re-downloadable). The app binary stays
small; the heavy asset arrives just-in-time. (On-Demand Resources
and `Background Assets` are Apple's alternatives for large bundled
content, but a gated HF/CDN download fits a 3 GB model better.)

## Updates: shipping new versions

Without a server you cannot hotfix; **every change ships through App
Review** (see the previous chapter). Two production concerns
dominate.

### SwiftData store migration

Your users' data lives in a SwiftData store on their device, and an
update must open the *old* store without losing anything. For
additive changes (new optional property, new model) SwiftData does a
**lightweight migration** automatically. For anything structural
(renames, type changes, splits) you must define a
`SchemaMigrationPlan` with explicit stages:

```swift
enum AlltagMigration: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }
    static var stages: [MigrationStage] {
        [.lightweight(fromVersion: SchemaV1.self,
                      toVersion: SchemaV2.self)]
    }
}
```

This is your Flyway/Liquibase — except there is **no DBA to run it
and no staging database to test against.** It executes on the user's
phone, once, irreversibly. Test migrations against a real old store
(seed v1 data, ship v2, assert it survives — *Alltag* already has a
"data survives store reopen" test). A botched migration is data
loss for a paid user with no recovery path.

### Backward compatibility and OS support

*Alltag* targets **iOS 17.0 minimum**. You cannot force anyone to
update the OS, so deciding to raise the floor to iOS 18 strands
every user still on 17 until *they* upgrade. Gate newer APIs with
`if #available(iOS 18, *)` and keep a working path for the minimum.
Treat the minimum-iOS bump as a product decision, not a refactor.

## Accessibility as production quality

On a backend, accessibility is invisible; on a consumer app it is a
correctness requirement — and for an app helping newcomers navigate
German bureaucracy, it is core to the mission. Three pillars:

- **VoiceOver.** Every interactive element needs a meaningful label;
  decorative ones are hidden. Severity pills must announce *meaning*
  ("urgent, reply by June 30"), not color.
- **Dynamic Type.** *Alltag* uses **SF Pro Rounded** via the system
  text styles with **no hard-coded font sizes**, so text scales from
  small up to the largest accessibility sizes. Layouts must not clip
  at XXL — test there.
- **RTL correctness.** Arabic ships in v1, so layout uses
  **leading/trailing**, never left/right, and is verified in a
  pseudo-RTL locale from day one.

### Localization rollout

*Alltag* is built in **German (default) + English first**, with the
remaining seven of nine languages (TR, FR, ES, IT, AR, RU, ZH)
localized near the end via String Catalogs. The i18n and RTL
*plumbing* exists from day one even though the *content* lands late
— so adding a language is a translation pass, not a re-architecture.
Decoder *output* follows the user's chosen app language, which the
on-device model handles directly. Ship DE+EN polished rather than
nine languages half-done.

## Takeaways

- The device is production: no logs, no SSH, no hotfix. Design for
  low crash rates because your ability to react is limited.
- `PrivacyInfo.xcprivacy` + required-reason API codes are mandatory
  at upload; ATT is a no-op for a no-tracking app like *Alltag*.
- Observability is Apple's opt-in Organizer + MetricKit; adding a
  crash SDK would break the *Data Not Collected* promise — a
  conscious tradeoff, not an oversight.
- Profile on device with Instruments; keep the main actor unblocked.
  The on-device LLM (Q4 GGUF on Metal, off the main actor, capped
  context, downloaded not bundled) is the central performance and
  app-size concern.
- Updates ship only through review; SwiftData migrations run once,
  irreversibly, on the user's phone — test them like Flyway you can
  never roll back.
- Accessibility (VoiceOver, Dynamic Type, RTL) is production
  correctness; ship DE+EN well, localize the rest last.

**Next:** Appendix A *Java/Quarkus to Swift/SwiftUI Cheat Sheet*.
