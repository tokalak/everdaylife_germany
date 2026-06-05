# Implementation Plan — Alltag (Germany Companion, iOS)

> **Working title:** *Alltag* — an AI-assisted iOS app that helps foreigners handle bureaucracy and everyday life in Germany.
>
> **Source of truth for scope:** [`../service-alltag-buerokratie-deutschland.md`](../service-alltag-buerokratie-deutschland.md) (product brief).
> **Source of truth for look & flows:** [`prototype/index.html`](prototype/index.html) (interactive Warm-Companion prototype — open in a browser).
> **Conventions:** [`AGENTS.md`](AGENTS.md) — Boundary-Control-Entity (BCE) per feature, red/green TDD.

---

## 0. How to use this document

This is the build backlog. It is meant to be **processed item by item, iteratively**.

- Every work item has a stable ID (e.g. `P3-04`) so it can be referenced across sessions.
- Items are checkboxes: `- [ ]` open, `- [x]` done.
- Phases are ordered by dependency. Within a phase, items are roughly ordered but many are parallelizable.
- Each feature is built **BCE-structured** and **test-first** (write the failing test, make it pass, refactor).
- When an item is implemented, tick it and note the PR/commit. Keep the **Open Questions** (§7) updated as answers arrive.

When picking up work: read §1 (locked decisions) and §2 (architecture) first, then continue from the first unchecked item in the lowest open phase.

---

## 1. Locked product decisions

These are settled. Do not re-litigate without an explicit decision change (and update this section + memory if one happens).

| # | Decision | Detail |
|---|---|---|
| D1 | **One app, persona-aware** | Single codebase. One onboarding question ("What's your situation?") drives a persona-specific Home, checklist, and tools. Not separate apps. |
| D2 | **Audience: foreigners in Germany** | Five personas: Tourist, Student, Worker/Freelancer, Family, Long-term Resident. |
| D3 | **iOS-first, SwiftUI** | Android/WhatsApp/Telegram deferred post-V1. |
| D4 | **Everything is LOCAL — storage AND AI inference** | Documents stored encrypted **on-device only**, never uploaded; must survive app updates. **The AI model runs on-device too (D11)** — letter text/images never leave the phone. Fully offline-capable Decoder. Overrides the brief's EU-server hosting *and* its server-side LLM call. No cross-device sync in v1 (iCloud is a later option). |
| D11 | **On-device LLM: Gemma 4 E2B (GGUF Q4_K_M) via llama.cpp** | The Decoder's understanding/translation runs **locally** on **Gemma 4 E2B instruction-tuned, GGUF `Q4_K_M`** ([`unsloth/gemma-4-E2B-it-GGUF`](https://huggingface.co/unsloth/gemma-4-E2B-it-GGUF), **3.11 GB**). Runtime = **`llama.cpp`** with the **Metal** backend (GGUF format → not MediaPipe/LiteRT). Dense, **2.3B effective params**, **128K context**, multimodal (text/image/audio/video). **No inference backend, no per-decode server cost.** Model downloaded on first run, not bundled. Google AI Edge Gallery (`/Users/tklk/Projects/gallery`) runs the **same model generation (Gemma 4 E2B)** but via **LiteRT-LM** (`gemma-4-E2B-it.litertlm`, 2.59 GB, 32K ctx, MTP fast-decode) — a different format/runtime than our GGUF/llama.cpp choice. Runtime choice (llama.cpp vs LiteRT-LM) is settled by the spike — see OQ-14. Quant/variant tradeoffs in OQ-8. |
| D5 | **Pricing: paid app, fixed upfront price, unlocks everything** | A **paid app** — the App Store charges a single upfront price *before download*; once installed, **100% of functionality is available**. **No subscription, no tiers, no in-app purchases, no à-la-carte IAP.** No StoreKit code in the app. (Headline price €29.99 per brief — final number/tier set in App Store Connect.) |
| D6 | **No in-app free tier; the store page is the funnel** | There is **no free trial inside the app** — the Decoder and everything else are fully available on install. The App Store product page (description, screenshots, preview) does the converting; the upfront price is the only gate. Re-downloads restore automatically (Apple-managed), so there is **no in-app restore flow**. |
| D7 | **Languages: v1 ships ~9; localize last** | Build the whole app in **German (default) + English** first. Add the rest **near the end of development**, then ship v1 fully localized. Full set: **DE, EN, TR, FR, ES, IT, AR, RU, ZH**. RTL (Arabic) infrastructure built from day one. |
| D8 | **Design direction: "Warm Companion"** | Warm paper background, soft teal primary, amber for "action," rounded type (SF Pro Rounded), calm and trustworthy. Full light + dark theme. See §3 + prototype. |
| D9 | **Information, not advice (RDG-safe)** | Never give personalized legal/tax advice. Information, translation, organization, process navigation only. Always-on disclaimers; "consult a lawyer" routing on legal items. See [`../regulatory-checklist-rdg-safe.md`](../regulatory-checklist-rdg-safe.md). |
| D10 | **Information architecture: Home-hosted** | 5 tabs: **Home · Docs · Decode (center) · Dates · Settings**. All persona tools and the cross-persona guides live on **Home** (search bar + "Up next" + checklist with deep-links + "Tools for your mode" grid + "Guides" list). No extra tab. |

---

## 2. Architecture & engineering conventions

### 2.1 Platform & stack
- [ ] **A-01** SwiftUI app, **minimum iOS 17.0** (SwiftData, Observation, modern navigation). Consider iOS 26 "Liquid Glass" accents as progressive enhancement only.
- [ ] **A-02** Single Xcode project, Swift Package-based feature modules where practical.
- [ ] **A-03** No third-party UI frameworks for core UI. Networking via `URLSession`/async-await.

### 2.2 BCE structure (per AGENTS.md)
Organize **per feature**, each feature folder split into Boundary / Control / Entity:
- **Boundary** — SwiftUI views + view-facing state (the UI edge) and any external-service clients (API, OCR).
- **Control** — use-cases / interactors orchestrating a feature's logic (e.g. `DecodeLetterUseCase`).
- **Entity** — domain models + persistence (e.g. `StoredDocument`, `Deadline`, `Persona`).

```
Alltag/
  App/                      // entry point, root TabView, DI container
  DesignSystem/             // tokens, components, theme, typography
  Core/
    Persistence/            // SwiftData stack, file store, Keychain, crypto
    LLM/                    // MediaPipe LiteRT engine, model download/manage, prompts
    Localization/           // i18n + RTL helpers, string catalogs
    Notifications/          // local notification scheduling
  Features/
    Onboarding/   {Boundary,Control,Entity}
    Decoder/      {Boundary,Control,Entity}
    Vault/        {Boundary,Control,Entity}
    Calendar/     {Boundary,Control,Entity}
    Home/         {Boundary,Control,Entity}
    Settings/     {Boundary,Control,Entity}
    Personas/     {Boundary,Control,Entity}   // persona model + switching
    Tools/        {Boundary,Control,Entity}   // visa-fit, Chancenkarte, etc.
    Guides/       {Boundary,Control,Entity}
  Resources/                // content JSON, Localizable string catalogs, assets
  Tests/                    // unit + UI tests mirroring feature folders
```

### 2.3 TDD workflow
- [ ] **A-04** Every Control use-case and Entity rule lands **test-first** (red → green → refactor).
- [ ] **A-05** Pure-logic engines (Chancenkarte points, Blue Card thresholds, 90-in-180 counter, working-hours tracker, eligibility checkers) have exhaustive unit tests — these are the highest-risk-for-bugs surfaces.
- [~] **A-06** Snapshot/UI tests for key screens incl. **Dynamic Type XXL** and **RTL** mirroring. *(Harness landed in P1-02: `SnapshotSupport` renders via `ImageRenderer` across a trait matrix (light/dark · Dynamic Type accessibility · RTL) and asserts non-blank output; applied to the whole component library. Extend per-screen as screens land — Decoder result screen covered in P3-03.)* **Harness notes for screen-level renders:** `ImageRenderer` never fires `onAppear` (so `appReveal` content is shown via the `\.revealAnimationDisabled` env flag) and renders **`ScrollView` content blank** (so screens expose a non-scroll content path — e.g. `DecoderResultView(embedInScrollView:)` — for the snapshot to exercise layout).

### 2.4 Data persistence (implements D4)
- [x] **A-07** Structured data (personas, checklist progress, deadlines, document metadata index) in **SwiftData**, store located in **Application Support** (persists across updates). *(`PersistenceController`; `DocumentRecord` is the first model — more entities appended to `schema` as features land.)*
- [x] **A-08** Document blobs (scans, PDFs) written to the **Documents directory** via `FileManager` — never Caches/tmp. *(`EncryptedFileStore`, `Documents/Vault`.)*
- [x] **A-09** Encrypt blobs at rest: per-file encryption with a symmetric key stored in the **Keychain** (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`); set `FileProtectionType.complete`. *(AES-GCM via `FileCryptor`; `KeychainKeyStore`; writes use `.completeFileProtection`.)*
- [x] **A-10** Verify persistence-across-update with an automated test (write → simulate bundle replacement → read). *(`PersistenceControllerTests.testDataSurvivesStoreReopen`.)*
- [ ] **A-11** Exclude document store from iCloud backup *or* document the backup behavior explicitly (privacy decision — see OQ-5).

### 2.5 Localization & RTL (implements D7)
- [x] **A-12** Use **String Catalogs** (`.xcstrings`). All user-facing copy localized from the start (DE + EN populated; other locales stubbed, filled at end). *(`Localizable.xcstrings`, DE source + EN; new copy adds keys here.)*
- [x] **A-13** German is the **default/development** language; English complete in parallel. *(`developmentLanguage: de`; `AppLanguage.default == .de`.)*
- [~] **A-14** Layout uses **leading/trailing** everywhere (never left/right); test every screen in a pseudo-RTL locale from day one. *(Plumbing in place: `AppLanguage.layoutDirection`, root applies `\.layoutDirection`; per-screen RTL snapshot QA is ongoing as screens land — X-02.)*
- [x] **A-15** Decoder output language follows the user's chosen app language. *(`LanguageStore.decoderOutputLanguage`; consumed by the Decoder in P3-02.)*
- [ ] **A-16** Plan a **content-localization pass** as a near-final milestone (Phase 8) for TR, FR, ES, IT, AR, RU, ZH.

### 2.6 Monetization (implements D5/D6)
> **Paid-app model — no in-app purchase code.** The single upfront price is configured in App Store Connect; everything is unlocked on install. There are no StoreKit products, no entitlement checks, and no restore flow in the app.
- [x] **A-17** **Paid app**: set the price tier in App Store Connect (Small Business Program TBD — OQ-2). No StoreKit, no products. *(App Store configuration only — no app code.)*
- [x] **A-18** Everything unlocked on install — **no entitlement checks or gates anywhere** in the app. *(No code; the earlier `DecoderAccessPolicy`/`PurchaseService` scaffold was removed.)*
- [x] **A-19** No in-app restore flow — re-downloads restore the paid app automatically (Apple-managed). *(N/A.)*

### 2.7 Theming
- [x] **A-20** Light/Dark/System theme, user-selectable in Settings, persisted. Tokens in DesignSystem (§3). *(`AppTheme`/`ThemeController`; Settings segmented picker; applied via `preferredColorScheme`.)*

### 2.8 On-device LLM inference (implements D11) — `Core/LLM`
Runtime = **`llama.cpp`** (GGUF, **Metal** backend). Model: `gemma-4-E2B-it-Q4_K_M.gguf` (3.11 GB) from `unsloth/gemma-4-E2B-it-GGUF`. The AI Edge Gallery (`/Users/tklk/Projects/gallery`) runs the **same model (Gemma 4 E2B)** but via **LiteRT-LM** (`.litertlm`, 2.59 GB, 32K ctx, MTP) — a strong alternative runtime to benchmark in the spike (OQ-14). Note its **iOS** allowlist (`ios_1_0_0.json`) currently lists only Gemma 3n, so Gemma-4-on-iOS via LiteRT-LM needs verification.
- [~] **A-21** Integrate **`llama.cpp`** on iOS via its **xcframework / Swift package** with the **Metal** backend; wrap in an `LLMEngine` Control exposing a clean async interface (`generate(prompt:images:) -> AsyncStream<String>`), independent of feature code. (Evaluate a thin wrapper such as a SwiftPM binding vs vendoring llama.cpp directly — OQ-14.) *(`LLMEngine` protocol + `LLMPrompt`/`LLMGenerationOptions`/`LLMError` shipped (`AsyncThrowingStream`); `StubLLMEngine` (streaming/guard/cancellation) backs development. **Vendoring the actual xcframework into `LlamaCppEngine` is the manual device step** — it currently reports `runtimeUnavailable`.)*
- [~] **A-22** **Model delivery:** download `gemma-4-E2B-it-Q4_K_M.gguf` (3.11 GB) on first run — **not bundled** (App Store / cellular limits). Resumable, Wi-Fi-recommended, retryable, progress UI; verify checksum/size. If using **vision**, also fetch the **multimodal projector (`mmproj`)** file (libmtmd) — see OQ-12. *(`ModelDownloading` + `URLSessionModelDownloader` (streamed-to-disk, progress, cancellable) + `ModelVerifier` (size + streamed SHA-256) shipped and tested. Follow-ups: HTTP-Range **resume** across launches + backoff retry (need the real endpoint), Wi-Fi/progress UI (P3-00), and `mmproj` if vision wins OQ-12.)*
- [~] **A-23** Store the model in **Application Support**, **excluded from iCloud/iTunes backup** (large + re-downloadable). Allow user to delete/redownload from Settings; show storage used. *(`ModelStore`: `Application Support/Alltag/Models`, directory + file `isExcludedFromBackup`, `FileProtectionType.complete`, install/`isInstalled`/`remove`/`totalBytesUsed`. The Settings surface (delete/redownload/storage) is P3-09.)*
- [ ] **A-24** **Gemma license / Terms** acceptance flow before download; comply with the Gemma Terms + Prohibited Use Policy and pass-through use restrictions (legal check — OQ-9). Decide model hosting/source (HF `unsloth/gemma-4-E2B-it-GGUF` direct vs self-hosted/CDN mirror — OQ-10).
- [x] **A-25** **Device-capability gate:** check RAM/chip; ~3.11 GB weights + KV cache need a capable device. On unsupported devices, degrade gracefully with clear messaging (the Decoder is the wedge — failure here must be handled, not crash). Define a supported-device matrix (OQ-11). Consider a **smaller quant fallback** (e.g. Q3_K_M ≈2.54 GB) for low-RAM devices (OQ-8). *(`DeviceCapabilityGate` evaluates `ProcessInfo.physicalMemory` against per-quant RAM floors, picks the richest quant that fits, falls back to `Q3_K_M`, else `.unsupported(reason:)` — no crash. RAM floors are approximations isolated in `ModelQuant` content (X-06), pending the OQ-11 matrix.)*
- [~] **A-26** Lifecycle: lazy-load, manage memory (unload under pressure), **cap context** well below 128K to bound KV-cache RAM (letters are short — e.g. 4–8K), warm-up, cancellation, single-inference concurrency guard, thermal/perf handling. *(Context cap carried per spec (`contextWindowCap = 8192`); single-inference guard + cancellation implemented in `StubLLMEngine` and honoured by the `LLMEngine` contract. Memory-pressure unload / warm-up / thermal handling live in the real engine — land with the xcframework.)*
- [ ] **A-27** Prompt + **structured-output** layer: system-prompt templates per task (decode, translate, summarize) in **Gemma chat format**, force JSON-ish output, **validate + repair + retry** (small models drift); optionally constrain with a **GBNF grammar** (llama.cpp) for reliable JSON; never accept a malformed deadline/severity. Unit-tested with fixtures.
- [ ] **A-28** **Quality evaluation harness:** a fixture set of real German Behörden letters with expected fields, run across languages, to measure decode/translation accuracy and catch hallucinations (brief Risk #2). Gate Decoder release on this. Compare **quant levels and E2B vs E4B** (OQ-8).

---

## 3. Design system (Warm Companion)

Mirror the prototype's tokens. Build as reusable SwiftUI components before screens.

- [x] **DS-01** Color tokens (semantic), light + dark: *(Full set in `ColorTokens.swift` — surfaces (paper/paper-sink/card/line), ink (ink/soft/faint), brand (teal/deep/wash + on-primary, amber/wash), and the four-level **severity system** each with a paired **wash**. Aligned exactly to the prototype CSS; light+dark dynamic pairs via trait-aware `UIColor`. Severity domain enum (`Severity.swift`) maps level → color/wash/symbol/label.)*
  - Paper `#FAF8F4` / dark `#1B1916`; Card `#FFFFFF` / `#252320`
  - Ink `#2B2722` / `#F2EEE6`; Ink-soft, Ink-faint
  - Primary **teal** `#2BA39A` (deep `#1C7E76`); **amber** `#E8A13C`
  - **Severity system** (reused everywhere): info green, action amber, urgent red, legal indigo — each with a wash variant.
- [x] **DS-02** Typography scale on **SF Pro Rounded** (rounded design), full **Dynamic Type** support. *(`AppText` role scale (display→pill) in `Typography.swift` — every style built from a *relative* system text style + rounded design + weight, so Dynamic Type scaling is preserved; `.appText(_:)` on `View`/`Text`. `.appFontDesign()` still cascades rounded at the root.)*
- [x] **DS-03** Radii (26/20/14), soft shadows (sm/md/lg), spacing scale. *(`AppRadius` (sm/md/lg/pill), `AppShadow` (sm/md/lg, two-layer warm-tinted via `.appShadow(_:)`), `AppSpacing` (4-pt grid xxxs→xxxl). Value-tested in `DesignTokenTests`.)*
- [x] **DS-04** Components: `Card`, `SeverityPill`, `ChecklistRow`, `ToolTile`, `GuideRow`, `SettingsRow` (icon + title + explanation + value/chevron), `SegmentedControl`, `PrimaryButton`, `DeadlineChip`, `TrustBanner`, `Toast`, `BottomSheet`, `EmptyState`. *(All in `DesignSystem/Components/`. Token-driven, leading/trailing-only (RTL-safe), with previews. `AppSegmentedControl` (generic, matched-geometry thumb), `PrimaryButton`/`SecondaryButtonStyle`, `appToast(_:)` + `appBottomSheet(_:)` view modifiers. New copy added to the String Catalog (severity labels, trust banner, disclaimer; DE+EN).)*
- [x] **DS-05** Motion: gentle staggered reveal on screen load; reduced-motion honored. *(`Motion.swift`: `.appReveal(index:)` fade-and-rise stagger, fully suppressed under `accessibilityReduceMotion`. Toast/segmented transitions also honor reduce-motion.)*
- [x] **DS-06** Reusable `DisclaimerNote` ("information, not legal advice") component (RDG). *(`DisclaimerNote.swift`, legal-indigo tint; default copy localized DE+EN.)*

---

## 4. Phased build plan

### Phase 0 — Foundation
- [x] **P0-01** Create Xcode project, bundle ID, signing, App Store Connect record. *(XcodeGen project; bundle ID `de.everydaygermany.app`; iOS 17.0; German dev language; signing deferred (simulator/CI). App ID registration + App Store Connect record remain manual — see `README.md`.)*
- [x] **P0-02** CI: build + run tests on demand. *(`ios/scripts/ci.sh`: regenerates project + `xcodebuild test` on a simulator. Run locally on demand — no GitHub Actions, so the repo can be pushed with a PAT that lacks `workflow` scope.)*
- [x] **P0-03** SwiftData stack + file store + Keychain/crypto (A-07…A-10) with tests. *(`Core/Persistence`: `PersistenceController` (SwiftData store in Application Support), `EncryptedFileStore` (AES-GCM blobs in Documents, `FileProtectionType.complete`), `KeychainKeyStore` (key with `…AfterFirstUnlockThisDeviceOnly`), `DocumentRecord` metadata model. Tests incl. encrypt-at-rest + survive-store-reopen; Keychain tests `XCTSkip` on unsigned simulator.)*
- [x] **P0-04** ~~StoreKit 2 wrapper + StoreKit test config~~ **Dropped — paid-app model (D5).** No in-app purchase code: the upfront price is set in App Store Connect and everything is unlocked on install. The earlier `Core/Purchases` scaffold (`PurchaseService`, `DecoderAccessPolicy`, `Products.storekit`) and its StoreKit run-scheme config were removed.
- [~] **P0-07** **Runtime decision spike (`Core/LLM`)** — foundational for the Decoder. Both candidates run the **same model, Gemma 4 E2B**:
  - **Candidate A (default):** GGUF `Q4_K_M` (3.11 GB) on **llama.cpp + Metal** — with a **GBNF grammar** for guaranteed-valid JSON.
  - **Candidate B:** `.litertlm` (2.59 GB, MTP fast-decode) on **LiteRT-LM** — the reference project's runtime (verify it works on **iOS**; the gallery's iOS allowlist still lists only 3n).
  - On a **real target device**, load each and decode the **same 5–10 real German Behörden letters** into the Decoder's JSON schema.
  - **Measure:** decode/translation quality, JSON-validity rate, first-token + full-decode latency, peak RAM, model+download size.
  - **Decision rule:** **default to Candidate A (llama.cpp/GGUF)** for its GBNF-guaranteed structured output and proven iOS-Metal maturity. **Switch to B only if** the spike shows B runs well on iOS *and* delivers a materially better quality+latency+size result. Record the verdict and rationale here, then close **OQ-14**.
  - Build the chosen runtime behind the `LLMEngine` wrapper (A-21) so the decision stays swappable; wire model download/management + capability gate (A-22…A-26) with a round-trip test.

  **Status — code foundation shipped; on-device benchmark is the remaining manual step.** The `Core/LLM` swappable foundation is built and fully unit-tested (64 tests green):
  - `LLMEngine` protocol + `LLMPrompt`/`LLMGenerationOptions` (incl. GBNF `grammar` hook)/`LLMError` (A-21); a deterministic `StubLLMEngine` (streaming, single-inference guard, cancellation) so Decoder work (P3-02) proceeds before the runtime binary lands; `LlamaCppEngine` as the explicit integration seam (reports `runtimeUnavailable` until the xcframework is vendored).
  - Model layer: `LLMRuntime` + `RuntimeDecision` (records the default), `ModelQuant`/`LLMModelSpec`/`LLMModelCatalog` (Candidate A `Q4_K_M` default, `Q3_K_M` low-memory fallback, Candidate B `.litertlm` recorded), `DeviceCapabilityGate` (RAM → quant or unsupported, A-25), `ModelStore` (App Support/Models, excluded from backup, install/size/remove, A-23), `ModelDownloading` + `URLSessionModelDownloader` + `ModelVerifier` (size+SHA-256, A-22), and `ModelProvisioner` orchestrating gate→present?→download→verify→install as an event stream — exercised by a **round-trip test** with a fake downloader. Wired into `AppEnvironment` via `LLMService`.
  - **Verdict (default, closes OQ-14's default):** **Candidate A — llama.cpp/GGUF** per the decision rule. Recorded in `RuntimeDecision.current` (`benchmarkComplete = false`).
  - **Remaining (manual, device-only):** the actual benchmark — load each runtime on a real iPhone, decode the 5–10 letters, measure quality/latency/RAM — cannot run in CI/Simulator (needs a physical device + a ~3 GB model). It vendors the `llama.cpp` xcframework into `LlamaCppEngine` (the only file that changes to activate real inference) and may flip the verdict per the rule. Gemma-license acceptance + readiness UI are **P3-00**.
  - **What does NOT yet work end-to-end (scope clarification).** P0-07 is the *foundation*, not the user-facing "scan a letter → get plain text" flow. In the **Simulator today** you get the download/verify/store/capability machinery and a `StubLLMEngine` (deterministic, not real inference) — there is **no capture, no OCR, and no real LLM output**. Reaching a working scan→explain demo requires, in addition to P0-07: (1) **capture + OCR** — note that turning an image into text is **Apple Vision OCR (P3-01)**, a *separate* step from the LLM; the Gemma model *explains* already-extracted text, it does not read pixels (unless vision/`mmproj` wins OQ-12); (2) the **Decoder UI flow** P3-00…P3-03 (the `Decoder` tab is still a `PlaceholderScreen`); (3) the vendored **llama.cpp xcframework** (A-21); and (4) a **physical device** — real inference never runs in the Simulator. Until then, Decoder feature work (P3-02) builds against `StubLLMEngine`.
- [x] **P0-05** Localization + RTL scaffolding (A-12…A-15); DE default. *(`Core/Localization`: `AppLanguage` (9 langs, DE default, only DE+EN selectable until Phase 8, AR=RTL), `LanguageStore` (persisted; exposes `locale`/`layoutDirection`/`decoderOutputLanguage`), `Localizable.xcstrings` String Catalog with DE source + EN. Root applies `\.locale` + `\.layoutDirection`.)*
- [x] **P0-06** Root `TabView` shell with 5 tabs (placeholder screens) and theme switching (A-20, DS-01/02). *(5-tab `RootView` (Home·Docs·Decode·Dates·Settings) with per-feature Boundary placeholders; `AppTheme`/`ThemeController` (Light/Dark/System, persisted) applied via `preferredColorScheme`; `AppEnvironment` DI container injects persistence/purchases/language/theme; foundation `AppColor` tokens (DS-01) + rounded type (DS-02). Settings exposes live Appearance + Language pickers. Full token set/components remain Phase 1.)*

### Phase 1 — Design system
- [x] **P1-01** Implement all tokens (DS-01…DS-03). *(`DesignSystem/`: `ColorTokens` (full semantic set + washes), `Severity` (domain enum → tokens), `Typography` (`AppText` Dynamic-Type-aware rounded scale), `Radii`, `Shadows`, `Spacing`, `Motion`. Token values pinned by `DesignTokenTests`.)*
- [x] **P1-02** Implement component library (DS-04…DS-06) with snapshot tests. *(13 components + `DisclaimerNote` in `DesignSystem/Components/`. Snapshot coverage = `ComponentRenderTests` via `ImageRenderer` across a trait matrix — light/dark, Dynamic Type **accessibility size**, and **RTL** (A-06/X-02) — asserting non-blank, correctly-sized renders (no third-party snapshot lib / reference images, per A-03). Full suite: 83 tests green, 2 Keychain skips on simulator.)*

### Phase 2 — Onboarding
- [x] **P2-01** Screen 1: language pick (DE/EN selectable now; full list rendered, others enabled in Phase 8). *(`LanguageStepView`: all 9 `AppLanguage` rendered; only `selectable` (DE/EN) tappable, the rest disabled with a "Soon" badge. Selection drives the live `LanguageStore` so the rest of onboarding re-localizes instantly.)*
- [x] **P2-02** Screen 2: **persona pick** (5 illustrated cards) — the key decision; writes active persona. *(`Persona` entity (5 audiences, D2) + `PersonaStore` (UserDefaults-persisted active persona). `PersonaStepView`: 5 selectable cards (SF-Symbol "illustration" + accent from the DS palette), `Continue` gated on a selection. Custom illustrations can replace the symbols later.)*
- [x] **P2-03** Screen 3: notification permission request. *(`Core/Notifications/NotificationAuthorizing` seam (`SystemNotificationAuthorizer` over `UNUserNotificationCenter`, stubbed in tests). `NotificationStepView` explains the value + on-device privacy (`TrustBanner`), requests permission, and finishes either way — permission is never a hard gate.)*
- [x] **P2-04** Persist onboarding completion; route to Home. *(`OnboardingController` (3-step nav + persisted `hasCompleted`). `AppFlowView` is the top-level router: onboarding until complete, then the 5-tab `RootView`; `AlltagApp` now mounts it. Wired into `AppEnvironment` (personas/onboarding/notifications). 17 tests incl. nav/persistence/routing + per-screen render snapshots across light/dark · Dynamic Type · RTL; full suite 100 green.)*

### Phase 3 — Shared core (always present)
- [x] **P3-00** **Decoder — model readiness**: first-use download/acceptance flow (A-22/A-24), progress + offline-ready state; gate Decode entry on model present + device capable (A-25). *(`DecoderReadinessController` (`@Observable`) maps `ModelProvisioner`'s event stream to a single `DecoderReadiness` state — consent → checking → downloading(fraction) → verifying → ready, plus `unsupported(reason)` and retryable `failed`. **Gemma terms acceptance gate** (A-24) persisted once before the ~3 GB download. `DecoderReadinessView` renders each state (offline-ready reassurance, progress, cancel/retry). Fully injected → unit-tested with a fake downloader (consent/skip-consent/unsupported/failure branches). Wired into `AppEnvironment`.)*
- [x] **P3-01** **Decoder — capture**: camera + Apple Vision document scan, on-device OCR (robust text extraction). Evaluate Gemma 3n **vision** input as alternative/fallback to OCR (OQ-12). *(`TextRecognizing` seam + `VisionTextRecognizer` (`VNRecognizeTextRequest`, `.accurate`, DE+EN languages, on-device) + `DocumentScannerView` (`VNDocumentCameraViewController` wrapper → JPEG pages; `isSupported` gates the Simulator/camera-less case). Multi-page join logic unit-tested via a stub recognizer; Vision accuracy itself is deferred to the A-28 eval harness. `NSCameraUsageDescription` added. **OCR→text is the default** (vision/`mmproj` remains OQ-12).)*
- [x] **P3-02** **Decoder — explain (ON-DEVICE)**: local Gemma call via `Core/LLM` → structured output (summary, asks, deadline, severity, response template, disclaimer flag). Tight schema + validate/repair (A-27); log locally for user review. **No network.** *(`DecodedLetter` entity; `DecoderPrompt` (system template in the user's output language + **GBNF grammar** for guaranteed JSON, A-15/A-27); `DecodedLetterParser` (extracts the first balanced `{…}` ignoring fences/prose, repairs each field — unknown severity→`.info`, **never invents a deadline**, legal⇒needsLawyer, blank reply→nil — rejects only on missing summary); `DecodeLetterUseCase` runs the engine with **one repair retry** then parses. 21 tests against scripted stub engines. Runs on `StubLLMEngine` until the llama.cpp xcframework is vendored — see P0-07.)*
- [x] **P3-03** **Decoder — result screen**: severity pill, plain summary, deadline chip → add to calendar, asks list, reply template (copy/share), collapsible original German, save-to-Vault, "talk to a lawyer" on legal items. *(`DecoderController` phase machine (idle→recognizing→decoding→result/failed, every failure mapped to an actionable `DecoderFailure`); `DecoderView` two-layer gate (readiness → capture→OCR→explain→result flow) with scan sheet + working/error states; `DecoderResultView` renders the full result (severity pill, summary, RDG note, deadline card w/ add-to-calendar, numbered asks, copyable German reply, collapsible original, share via reusable `ShareSheet`, lawyer note on legal). Calendar/Vault actions are injected closures (toast until P3-08/P3-05). Per-screen render-smoke across light/dark · Dynamic Type · RTL (A-06/X-02). DE+EN copy added. **Note:** real scan→explain needs a device + the vendored runtime (P0-07); the Simulator shows the "needs a camera" state.)*
- [x] **P3-04** ~~Decoder — free-tier gate~~ **Dropped (D5/D6).** No monthly counter and no paywall — the Decoder is fully available in the paid app.
- [x] **P3-05** **Vault**: list/grid of documents, categories, per-doc expiry, add/scan/import, PDF export/share, trust banner ("stored only on this device"). *(`DocumentCategory` enum (identity/official/finance/insurance/housing/other; typed accessor + `daysUntilExpiry` in an extension on `DocumentRecord`); `VaultStore` (`@Observable`) over `EncryptedFileStore` (AES-GCM blobs) + SwiftData index — add/remove/grouped/`data(for:)`/`totalBytesUsed`, encrypt-round-trip tested. `VaultView`: category-grouped list, trust banner, add menu (**scan** via `DocumentScannerView` → `DocumentPDF.make`, **import** via `.fileImporter` for PDF/image), swipe delete/share, export through `ShareSheet` (temp file). `AddDocumentSheet` (name/category/expiry) + `DocumentRow` (render-tested across categories/expiry · light/dark · Dynamic Type · RTL). Decoder "save to Vault" wired (renders OCR text to PDF). `EncryptedFileStore.ephemeral()` added for DI/tests/previews.)*
- [x] **P3-06** **Vault** expiry notifications at 60/30/7 days. *(On a document with an expiry, `VaultStore` schedules expiry reminders at **60/30/7** via the shared `ReminderScheduling` seam (prefix `expiry`) **and** upserts a `.vault` `Deadline` so it shows in the Dates agenda (P3-08) — with `DeadlineStore` suppressing its own 14/7/1 reminders for `.vault` sources to avoid double-reminding. Verified against the recording scheduler.)*
- [x] **P3-07** **Calendar/Dates**: agenda list grouped by urgency, countdowns, severity stripes, manual add, mark done. *(`Deadline` `@Model` (severity/source stored as raw strings, typed accessors in an **extension** so the macro doesn't persist them); `DeadlineUrgency` pure day-math — `daysUntil`/`bucket`/`grouped` (overdue·today·this-week·later·done), exhaustively unit-tested; `DeadlineStore` (`@Observable`) CRUD + grouping. `DatesView` grouped agenda (severity stripe per row, localized day countdowns, swipe to done/delete) + `AddDeadlineSheet` manual entry + empty state. `DeadlineRow` render-tested across severities/done · light/dark · Dynamic Type · RTL.)*
- [x] **P3-08** **Calendar** auto-population from decoded letters + vault expiries; reminders at 14/7/1 day. *(`ReminderScheduling` seam in `Core/Notifications` (`ReminderRequest` + `SystemReminderScheduler` — fires at 9am, `offsetsInDays` = `[14,7,1]` for deadlines / `[60,30,7]` for expiries; deterministic identifiers for replace/cancel). `DeadlineStore` (re)schedules on add/restore, cancels on done/delete — verified against a recording stub. `upsert(source:sourceId:)` dedupes auto-populated entries. Decoder "add to calendar" wired → `deadlines.add(source: .decoded)`; Vault expiry population lands with P3-06.)*
- [x] **P3-09** **Settings** (native grouped list, D10): Appearance (Light/Dark/System), language, my mode, reminders, document storage explainer, export data, delete all data (GDPR), help, about/legal. Each row has a speaking name + one-line explanation. *(`SettingsView` grouped `List` — Appearance (segmented theme), Your setup (language + **my mode** persona picker + Reminders → iOS Settings), Documents & data (storage explainer with live byte total from Vault+model, **Export my data**, **Delete all my data** with destructive confirm), About (help → mailto, About & legal → `AboutView` with the RDG disclaimer + version). Every row uses the speaking icon+title+explanation pattern. `DataManagementController` (GDPR `deleteAllData` via the stores; `exportItems` → summary `.txt` + each decrypted doc as temp files for a share sheet) + pure `DataExport` formatting — unit-tested. Exposed on `AppEnvironment.dataManagement`.)*

### Phase 4 — Persona framework + Worker (deepest)
- [x] **P4-01** Persona engine: data model supporting one active persona + preserved "past situations"; switch without losing progress (data model supports multiple simultaneous personas for V1.1, surface one now). *(`PersonaStore` now tracks `engagedPersonas` (first-seen order, persisted) + `pastPersonas`; `select` records each persona the first time it's seen and never clears the others. Progress lives in `ChecklistStore` keyed by **(persona, itemId)** over a new `ChecklistProgress` `@Model` (added to the persistence schema), so switching mode is lossless — the existing Settings "my mode" picker already switches via `select`, so it's lossless for free. Only completed items are stored; counts are taken against the live catalog so a content edit never strands rows. GDPR delete-all clears checklist progress too. Tests: engaged/past + persistence, toggle/reload/per-persona isolation/clamping.)*
- [x] **P4-02** **Home** layout (D10): greeting, **"Mode: <persona>"** label, progress ring, search bar, "Up next" card, checklist (deep-links into tools/guides), "Tools for your mode" grid, "Guides" list. *(`HomeView`: time-of-day greeting + mode chip + `ProgressRing` (new DS component) bound to checklist fraction; search entry (across guides/tools is P6-G6 → "coming soon" toast for now); "Up next" card from the soonest pending `DeadlineStore` entry, deep-linking to the Dates tab via a `selection` binding; persona checklist with per-persona ticking; tools grid; cross-persona guides. Tool/guide taps surface a "coming soon" toast until the Phase-6 engines/reader land. `embedInScrollView:` snapshot seam; render-smoke across light/dark · Dynamic Type · RTL (A-06/X-02) incl. the defensive no-mode state.)*
- [x] **P4-03** Worker checklist content (Anmeldung, bank, health insurance, tax-ID, freelance registration, …). *(Versioned content in `PersonaCatalog` (X-06): 7 worker steps (Anmeldung → bank → health → Steuer-ID → freelance registration → liability → broadcast fee), stable ids, optional deep-links. Other personas return empty until Phase 5; DE+EN copy in the String Catalog. Tests pin uniqueness/order + that deep-links reference real tools/guides.)*
- [x] **P4-04** Worker tools wired into Home grid (engines built in Phase 6). *(`PersonaTool`/`Guide` content + 6 worker tiles (visa-fit, Blue Card, Chancenkarte (badged), bank, health, tax-ID) and the 5 cross-persona guides, rendered via `ToolTile`/`GuideRow`. The interactive engines are **Phase 6** (P6-W*/P6-G*) — taps toast "coming soon" for now.)*

### Phase 5 — Remaining personas
- [ ] **P5-01** Tourist: checklist + Home.
- [ ] **P5-02** Student: checklist + Home.
- [ ] **P5-03** Family: checklist + Home.
- [ ] **P5-04** Long-term Resident: checklist + Home.
- [ ] **P5-05** Persona-switching UI in Settings ("My mode") with progress preservation + "Past situations".

### Phase 6 — Tools (interactive engines) & Guides
Engines are pure-logic + tested (A-05). Each carries the RDG disclaimer.

**Cross-persona guides (all 5 ship in V1):**
- [ ] **P6-G1** Residence permit (Aufenthaltstitel)
- [ ] **P6-G2** Registering a business (Gewerbe vs Freiberufler)
- [ ] **P6-G3** How taxes work
- [ ] **P6-G4** Getting health insurance
- [ ] **P6-G5** Recognising a foreign diploma (Anerkennung)
- [ ] **P6-G6** Guide reader screen + in-app search across guides/tools

**Worker tools:**
- [ ] **P6-W1** Visa-fit tool
- [ ] **P6-W2** Blue Card threshold checker (2026 numbers)
- [ ] **P6-W3** **Chancenkarte points calculator** *(prototyped — port the logic & UX from prototype, then verify point values, OQ-1)*
- [ ] **P6-W4** Bank account comparison (affiliate)
- [ ] **P6-W5** GKV vs PKV decision tree (affiliate)
- [ ] **P6-W6** Tax-ID & Steuernummer organizer
- [ ] **P6-W7** Freelance registration sub-flow

**Tourist tools:**
- [ ] **P6-T1** Visa-need decision tool
- [ ] **P6-T2** Embassy document checklist
- [ ] **P6-T3** Verpflichtungserklärung explainer
- [ ] **P6-T4** Travel insurance comparison (affiliate)
- [ ] **P6-T5** 90-in-180-days counter
- [ ] **P6-T6** Pre-arrival survival kit

**Student tools:**
- [ ] **P6-S1** Pre-arrival checklist by nationality
- [ ] **P6-S2** Blocked account (Sperrkonto) comparison (affiliate)
- [ ] **P6-S3** Student health insurance comparison (affiliate)
- [ ] **P6-S4** Anmeldung guide (shared with Worker)
- [ ] **P6-S5** Working-hours tracker
- [ ] **P6-S6** Post-study transition checklist

**Family tools:**
- [ ] **P6-F1** Family-reunification visa checklist
- [ ] **P6-F2** A1 test booking guide
- [ ] **P6-F3** Sponsor document pack
- [ ] **P6-F4** Post-arrival checklist
- [ ] **P6-F5** Kindergeld application guide
- [ ] **P6-F6** Kita/school enrollment basics
- [ ] **P6-F7** Birth registration (Standesamt) sub-flow

**Long-term Resident tools:**
- [ ] **P6-R1** Niederlassungserlaubnis eligibility checker
- [ ] **P6-R2** Einbürgerung eligibility checker (2024 reform)
- [ ] **P6-R3** Einbürgerungstest practice (≈300 public-domain questions)
- [ ] **P6-R4** Renewal tracker (pulls from Vault expiries)
- [ ] **P6-R5** Family-reunification quick guide

- [ ] **P6-A1** Affiliate link integration (always 3+ ranked options, transparent; per §7 of brief).

### Phase 7 — Monetization (App Store config only)
> Paid-app model (D5): no in-app paywall, entitlement, or restore work. This phase is just App Store Connect setup.
- [ ] **P7-01** Configure the paid-app **price tier** in App Store Connect; confirm Small Business Program enrollment (OQ-2). Price display/localization is handled by the App Store automatically.
- [x] **P7-02** ~~Entitlement edge cases (refund, restore, family sharing)~~ **Dropped (D5)** — Apple-managed for a paid app; nothing in-app.

### Phase 8 — Localization (the deferred-content milestone, D7)
- [ ] **P8-01** Freeze UI copy; extract all strings.
- [ ] **P8-02** Translate to TR, FR, ES, IT, AR, RU, ZH.
- [ ] **P8-03** Full RTL QA pass (Arabic) across every screen.
- [ ] **P8-04** Localized Decoder output prompts/quality check per language.
- [ ] **P8-05** Localized App Store listings + ASO per language; Custom Product Pages per persona.

### Phase 9 — Compliance, polish, launch
- [ ] **P9-01** Lawyer review of all wording (RDG) — gate before submission.
- [ ] **P9-02** GDPR/DSGVO audit: consent flows, data export, deletion, processing records.
- [ ] **P9-03** Per-feature disclaimer system verified.
- [ ] **P9-04** Accessibility pass (VoiceOver, Dynamic Type, contrast, reduced motion).
- [ ] **P9-05** TestFlight beta (50–100 newcomers across personas); fix content + bugs.
- [ ] **P9-06** Soft launch (one country) → App Store launch.

---

## 5. Cross-cutting requirements (apply to every item)

- [ ] **X-01** Accessibility: VoiceOver labels, Dynamic Type to XXL, 4.5:1 contrast (both themes), reduced-motion.
- [ ] **X-02** RTL correctness (Arabic) — structural from day one.
- [ ] **X-03** Privacy: no document leaves the device; minimal analytics; clear consent.
- [ ] **X-04** RDG/StBerG safety: information-not-advice framing + disclaimers on anything legally/tax consequential; lawyer-routing on legal items.
- [ ] **X-05** Robust empty states that teach the next action.
- [ ] **X-06** Yearly-maintenance hooks: thresholds/point values/law text isolated in versioned content files (not hard-coded in views) so they can be updated without code churn.
- [ ] **X-07** Decoder safety: tight output templates + validate/repair (A-27), log every decode locally for user review, never invent deadlines/obligations. **Heightened with a small on-device model** — pair with the A-28 eval gate.

---

## 6. Feature inventory snapshot

| Area | Items | Status |
|---|---|---|
| On-device AI | Gemma 4 E2B (GGUF Q4_K_M, 3.11 GB) via llama.cpp/Metal, model download/manage | `Core/LLM` foundation built (P0-07): swappable `LLMEngine`, download/verify/store, capability gate, round-trip test. Real llama.cpp xcframework + on-device benchmark = manual device step |
| Shared core | Decoder (local inference), Vault, Calendar, Settings | **Phase 3 complete (P3-00…09):** Decoder readiness→capture→explain→result (on `StubLLMEngine` pending the vendored runtime); Calendar/Dates (deadlines, urgency agenda, 14/7/1 reminders, decoded-letter auto-populate); Vault (encrypted docs, scan/import, PDF export, 60/30/7 expiry reminders + agenda); Settings (grouped list, GDPR export/delete, about/legal). |
| Persona engine + Home / IA | Active + past personas, per-persona checklist progress, Home (greeting, mode, ring, up-next, checklist, tools grid, guides) | **Phase 4 complete (P4-01…04):** `PersonaStore` past-situations + lossless mode switching; `ChecklistStore`/`ChecklistProgress` per-persona progress; `HomeView` + `ProgressRing`; Worker checklist/tools + 5 guides in versioned `PersonaCatalog`. Tool engines + guide reader = Phase 6. **188 tests green** |
| Worker | 7 tools — Chancenkarte calc fully prototyped | Tiles wired into Home (P4-04); engines = Phase 6. Chancenkarte: prototyped |
| Tourist/Student/Family/Resident | tools per §4 Phase 6 | Mapped, not built |
| Guides | 5 cross-persona | Listed, not built |
| Theming | Light/Dark/System Warm Companion | Prototyped (HTML) |
| Monetization | Paid app (fixed upfront price), everything unlocked | App Store config (no in-app code) |
| Localization | DE+EN dev → 9 at launch | Infra only |

The HTML prototype (`prototype/index.html`) is the **visual + interaction reference** for porting to SwiftUI. It is not production code.

---

## 7. Open questions / to verify before/while building

- **OQ-1 (must-verify):** Exact **Chancenkarte point values** and **Blue Card 2026 thresholds** — the prototype uses credible approximations only. Confirm against current BAMF/Make-it-in-Germany before shipping these engines. (Ties to X-06.)
- **OQ-2:** Final **price** and whether the **Small Business Program** (15%) applies.
- **OQ-3: ✅ RESOLVED** — no free tier. Paid-app model (D5/D6): everything unlocks on install, so there is no Decoder cap to tune.
- **OQ-4: ✅ RESOLVED** — inference runs **on-device** (Gemma 4 E2B via llama.cpp, D11). No letter text or image leaves the phone; no EU-inference question. This was the biggest risk in the prior plan; the local-model decision closes it and strengthens the privacy/GDPR story.
- **OQ-5:** iCloud backup of the **document store** — include or exclude (A-11). (The **model file** is already excluded, A-23.)
- **OQ-6:** Which 3 cities to deepen Anmeldung guidance for first; soft-launch country; affiliate partners (per brief §13).
- **OQ-7:** Minimum iOS version final call (proposed 17.0; gallery also requires 17+).
- **OQ-8:** **Quant level + E2B vs E4B** — `Q4_K_M` (3.11 GB) is the chosen default. Does it give acceptable German-letter decode/translation quality across all 9 languages, or do we need a higher quant (Q5/Q6) or **E4B** (more quality, larger, more RAM, fewer devices)? And do low-RAM devices need a smaller quant (Q3_K_M ≈2.54 GB)? Decide via the A-28 eval harness; possibly ship a device-adaptive quant.
- **OQ-9:** **Gemma license** review for commercial distribution inside a paid app (Prohibited Use Policy, attribution, pass-through restrictions) — fold into the lawyer review (P9-01).
- **OQ-10:** **Model hosting & download source** — HuggingFace gated (`google/gemma-3n-E2B-it-litert-preview`) vs a self-hosted/CDN mirror; auth, versioning, and update strategy.
- **OQ-11:** **Supported-device matrix** — minimum chip/RAM to run E2B acceptably; messaging + fallback for older iPhones (A-25).
- **OQ-12:** **OCR vs vision** — Apple Vision OCR→text (reliable, lower memory, no extra files) vs feeding the letter image to Gemma 4's vision path (needs the **`mmproj`** projector + llama.cpp `libmtmd`, more RAM). Decide per quality/perf from A-28; OCR→text is the likely default for dense official letters.
- **OQ-13:** **"5-second" promise** — measure real first-token + full-decode latency per device on llama.cpp/Metal; set honest UX expectations and a good progress experience.
- **OQ-14: ◑ DEFAULT RECORDED (benchmark pending)** — **Runtime: llama.cpp/GGUF vs LiteRT-LM/`.litertlm`** — both run **Gemma 4 E2B**. llama.cpp = GBNF-guaranteed JSON, quant flexibility, iOS-Metal maturity, independence from Google's iOS release cadence (3.11 GB). LiteRT-LM (the reference's runtime) = smaller (2.59 GB), MTP fast-decode, integrated multimodal, Google-maintained — **but Gemma-4-on-iOS unproven in this snapshot** (iOS allowlist still 3n). **Default = Candidate A (llama.cpp/GGUF)** per the P0-07 decision rule, recorded in `RuntimeDecision.current` and held swappable behind `LLMEngine`. **Remaining:** the on-device benchmark on the same German letters (manual, device-only) which may flip it; pin the llama.cpp xcframework/SwiftPM version when vendoring.

> ✅ **The local-model decision (D11) resolves the prior OQ-4 contradiction.** With storage *and* inference on-device, "your data never leaves this device" is now literally true end-to-end — a stronger claim than the brief's. The new risks are practical (model size, device support, small-model quality), tracked as OQ-8…OQ-13 and the A-28 eval gate. Note the brief's "~€0.02–0.10 per Decoder" server cost **disappears**, improving unit economics.

---

## 8. Suggested iteration order (fast path to a usable build)

1. Phase 0 + 1 (foundation + design system) — **incl. `Core/LLM` engine + model download (P0-07)**, since the Decoder depends on it
2. Onboarding (P2) → Home shell with **Worker** persona (P4-01/02)
3. **Decoder** end-to-end (P3-00…03) on local Gemma 3n + **run the A-28 quality eval** — the wedge feature
4. Vault + Calendar (P3-05…08) + Settings (P3-09)
5. App Store pricing config (P7-01) — paid app, no in-app gate
6. Worker tools incl. Chancenkarte (P6-W*) + the 5 guides (P6-G*)
7. Remaining personas (P5) + their tools (P6)
8. Localization (P8) → Compliance & launch (P9)

This yields a demoable "core + Worker" app early, then widens to all personas, then localizes last (per D7).
