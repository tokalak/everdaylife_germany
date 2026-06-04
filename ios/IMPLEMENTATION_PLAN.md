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
| D4 | **Storage is LOCAL-ONLY** | Documents stored encrypted **on-device only**, never uploaded. Overrides the brief's EU-server hosting. Must survive app updates. No cross-device sync in v1 (iCloud is a later option). |
| D5 | **Pricing: one-time, fixed, unlocks everything** | A single non-consumable purchase. **No subscription, no tiers, no à-la-carte IAP.** After purchase, **100% of functionality is available**. (Headline price €29.99 per brief — final number set in App Store Connect.) |
| D6 | **Free trial as the funnel** | Before purchase: limited **Behörden-Brief Decoder** (3 decodes/month) + full Vault/Calendar/checklists/tools browsing. The purchase removes the Decoder cap and is the only gate. (Confirm exact free limit in beta — see OQ-3.) |
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
    Localization/           // i18n + RTL helpers, string catalogs
    Purchases/              // StoreKit 2 wrapper
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
- [ ] **A-06** Snapshot/UI tests for key screens incl. **Dynamic Type XXL** and **RTL** mirroring.

### 2.4 Data persistence (implements D4)
- [ ] **A-07** Structured data (personas, checklist progress, deadlines, document metadata index) in **SwiftData**, store located in **Application Support** (persists across updates).
- [ ] **A-08** Document blobs (scans, PDFs) written to the **Documents directory** via `FileManager` — never Caches/tmp.
- [ ] **A-09** Encrypt blobs at rest: per-file encryption with a symmetric key stored in the **Keychain** (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`); set `FileProtectionType.complete`.
- [ ] **A-10** Verify persistence-across-update with an automated test (write → simulate bundle replacement → read).
- [ ] **A-11** Exclude document store from iCloud backup *or* document the backup behavior explicitly (privacy decision — see OQ-5).

### 2.5 Localization & RTL (implements D7)
- [ ] **A-12** Use **String Catalogs** (`.xcstrings`). All user-facing copy localized from the start (DE + EN populated; other locales stubbed, filled at end).
- [ ] **A-13** German is the **default/development** language; English complete in parallel.
- [ ] **A-14** Layout uses **leading/trailing** everywhere (never left/right); test every screen in a pseudo-RTL locale from day one.
- [ ] **A-15** Decoder output language follows the user's chosen app language.
- [ ] **A-16** Plan a **content-localization pass** as a near-final milestone (Phase 8) for TR, FR, ES, IT, AR, RU, ZH.

### 2.6 Monetization (implements D5/D6)
- [ ] **A-17** **StoreKit 2**, one **non-consumable** product (full unlock).
- [ ] **A-18** Entitlement check gates only the Decoder monthly cap; everything else stays open.
- [ ] **A-19** Restore purchases; handle Ask-to-Buy/family sharing per Apple guidelines.

### 2.7 Theming
- [ ] **A-20** Light/Dark/System theme, user-selectable in Settings, persisted. Tokens in DesignSystem (§3).

---

## 3. Design system (Warm Companion)

Mirror the prototype's tokens. Build as reusable SwiftUI components before screens.

- [ ] **DS-01** Color tokens (semantic), light + dark:
  - Paper `#FAF8F4` / dark `#1B1916`; Card `#FFFFFF` / `#252320`
  - Ink `#2B2722` / `#F2EEE6`; Ink-soft, Ink-faint
  - Primary **teal** `#2BA39A` (deep `#1C7E76`); **amber** `#E8A13C`
  - **Severity system** (reused everywhere): info green, action amber, urgent red, legal indigo — each with a wash variant.
- [ ] **DS-02** Typography scale on **SF Pro Rounded** (rounded design), full **Dynamic Type** support.
- [ ] **DS-03** Radii (26/20/14), soft shadows (sm/md/lg), spacing scale.
- [ ] **DS-04** Components: `Card`, `SeverityPill`, `ChecklistRow`, `ToolTile`, `GuideRow`, `SettingsRow` (icon + title + explanation + value/chevron), `SegmentedControl`, `PrimaryButton`, `DeadlineChip`, `TrustBanner`, `Toast`, `BottomSheet`, `EmptyState`.
- [ ] **DS-05** Motion: gentle staggered reveal on screen load; reduced-motion honored.
- [ ] **DS-06** Reusable `DisclaimerNote` ("information, not legal advice") component (RDG).

---

## 4. Phased build plan

### Phase 0 — Foundation
- [ ] **P0-01** Create Xcode project, bundle ID, signing, App Store Connect record.
- [ ] **P0-02** CI: build + run tests on PR.
- [ ] **P0-03** SwiftData stack + file store + Keychain/crypto (A-07…A-10) with tests.
- [ ] **P0-04** StoreKit 2 wrapper + StoreKit test config (A-17…A-19).
- [ ] **P0-05** Localization + RTL scaffolding (A-12…A-15); DE default.
- [ ] **P0-06** Root `TabView` shell with 5 tabs (placeholder screens) and theme switching (A-20, DS-01/02).

### Phase 1 — Design system
- [ ] **P1-01** Implement all tokens (DS-01…DS-03).
- [ ] **P1-02** Implement component library (DS-04…DS-06) with snapshot tests.

### Phase 2 — Onboarding
- [ ] **P2-01** Screen 1: language pick (DE/EN selectable now; full list rendered, others enabled in Phase 8).
- [ ] **P2-02** Screen 2: **persona pick** (5 illustrated cards) — the key decision; writes active persona.
- [ ] **P2-03** Screen 3: notification permission request.
- [ ] **P2-04** Persist onboarding completion; route to Home.

### Phase 3 — Shared core (always present)
- [ ] **P3-01** **Decoder — capture**: camera + Apple Vision document scan, on-device OCR.
- [ ] **P3-02** **Decoder — explain**: server LLM call → structured output (summary, asks, deadline, severity, response template, disclaimer flag). Tight output schema; log for review.
- [ ] **P3-03** **Decoder — result screen**: severity pill, plain summary, deadline chip → add to calendar, asks list, reply template (copy/share), collapsible original German, save-to-Vault, "talk to a lawyer" on legal items.
- [ ] **P3-04** **Decoder — free-tier gate**: 3/month counter; paywall sheet at the wall (D6).
- [ ] **P3-05** **Vault**: list/grid of documents, categories, per-doc expiry, add/scan/import, PDF export/share, trust banner ("stored only on this device").
- [ ] **P3-06** **Vault** expiry notifications at 60/30/7 days.
- [ ] **P3-07** **Calendar/Dates**: agenda list grouped by urgency, countdowns, severity stripes, manual add, mark done.
- [ ] **P3-08** **Calendar** auto-population from decoded letters + vault expiries; reminders at 14/7/1 day.
- [ ] **P3-09** **Settings** (native grouped list, D10): Appearance (Light/Dark/System), language, my mode, reminders, document storage explainer, export data, delete all data (GDPR), restore purchase, help, about/legal. Each row has a speaking name + one-line explanation.

### Phase 4 — Persona framework + Worker (deepest)
- [ ] **P4-01** Persona engine: data model supporting one active persona + preserved "past situations"; switch without losing progress (data model supports multiple simultaneous personas for V1.1, surface one now).
- [ ] **P4-02** **Home** layout (D10): greeting, **"Mode: <persona>"** label, progress ring, search bar, "Up next" card, checklist (deep-links into tools/guides), "Tools for your mode" grid, "Guides" list.
- [ ] **P4-03** Worker checklist content (Anmeldung, bank, health insurance, tax-ID, freelance registration, …).
- [ ] **P4-04** Worker tools wired into Home grid (engines built in Phase 6).

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

### Phase 7 — Monetization polish
- [ ] **P7-01** Paywall presentation at the wall + from Settings; price localization.
- [ ] **P7-02** Entitlement edge cases (refund, restore, family sharing).

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
- [ ] **X-07** Decoder safety: tight output templates, log every decode for review, never invent deadlines/obligations.

---

## 6. Feature inventory snapshot

| Area | Items | Status |
|---|---|---|
| Shared core | Decoder, Vault, Calendar, Settings | Prototyped (HTML) |
| Home / IA | Search, Up-next, checklist, tools grid, guides | Prototyped (HTML) |
| Worker | 7 tools — Chancenkarte calc fully prototyped | Chancenkarte: prototyped |
| Tourist/Student/Family/Resident | tools per §4 Phase 6 | Mapped, not built |
| Guides | 5 cross-persona | Listed, not built |
| Theming | Light/Dark/System Warm Companion | Prototyped (HTML) |
| Monetization | One-time unlock + free Decoder cap | Paywall prototyped |
| Localization | DE+EN dev → 9 at launch | Infra only |

The HTML prototype (`prototype/index.html`) is the **visual + interaction reference** for porting to SwiftUI. It is not production code.

---

## 7. Open questions / to verify before/while building

- **OQ-1 (must-verify):** Exact **Chancenkarte point values** and **Blue Card 2026 thresholds** — the prototype uses credible approximations only. Confirm against current BAMF/Make-it-in-Germany before shipping these engines. (Ties to X-06.)
- **OQ-2:** Final **price** and whether the **Small Business Program** (15%) applies.
- **OQ-3:** Free-tier Decoder limit — test 2/3/5 in beta (D6).
- **OQ-4:** **LLM provider** + EU data-processing for the Decoder explanation step (OCR is on-device; the explanation call still sends letter text off-device — reconcile with the local-only stance and GDPR; this is a notable nuance vs D4 since the *document image* stays local but extracted *text* is sent for explanation).
- **OQ-5:** iCloud backup of the document store — include or exclude (A-11).
- **OQ-6:** Which 3 cities to deepen Anmeldung guidance for first; soft-launch country; affiliate partners (per brief §13).
- **OQ-7:** Minimum iOS version final call (proposed 17.0).

> ⚠️ **OQ-4 is important and partly contradicts D4.** Local-only storage protects the *stored documents*, but the Decoder still transmits the *letter's text* to an LLM to produce the explanation. Decide and document: EU-hosted/EU-resident inference, retention policy, and user consent. Update D4/§2.4 once resolved.

---

## 8. Suggested iteration order (fast path to a usable build)

1. Phase 0 + 1 (foundation + design system)
2. Onboarding (P2) → Home shell with **Worker** persona (P4-01/02)
3. **Decoder** end-to-end (P3-01…04) — the wedge feature
4. Vault + Calendar (P3-05…08) + Settings (P3-09)
5. Monetization gate (P3-04/P7)
6. Worker tools incl. Chancenkarte (P6-W*) + the 5 guides (P6-G*)
7. Remaining personas (P5) + their tools (P6)
8. Localization (P8) → Compliance & launch (P9)

This yields a demoable "core + Worker" app early, then widens to all personas, then localizes last (per D7).
