# AGENTS.md

## Project Overview
*Alltag* — an AI-assisted **iOS** app helping foreigners handle bureaucracy and everyday life in Germany.
Persona-aware (Tourist / Student / Worker / Family / Long-term Resident). The anchor feature is the
**Behörden-Brief Decoder**: photograph an official German letter → plain-language explanation + deadline.

## Source-of-truth documents (read before working)
- **`IMPLEMENTATION_PLAN.md`** — the build backlog. Processed **item by item** (stable IDs like `P3-02`). Start here.
- **`../service-alltag-buerokratie-deutschland.md`** — product brief (scope). The plan overrides it where they conflict.
- **`prototype/index.html`** — interactive "Warm Companion" UI/flow reference (not production code).

## Locked decisions (do not re-litigate without an explicit change)
- **iOS-first, SwiftUI**, min **iOS 17.0**.
- **Everything is local.** Documents stored encrypted **on-device only** (Documents/App Support, Keychain key, survives updates — never Caches/tmp). **AI inference is on-device too** (next point). Nothing leaves the phone.
- **On-device LLM: Gemma 4 E2B QAT, GGUF `UD-Q4_K_XL`** (`unsloth/gemma-4-E2B-it-qat-GGUF`, 2.62 GB) via **`llama.cpp` + Metal** (GGUF → not MediaPipe/LiteRT). QAT (quantization-aware training) is both smaller and higher-quality than the old post-training `Q4_K_M`; Unsloth ships only this one precision. 128K context, multimodal. Downloaded on first run, not bundled. No inference backend. Google AI Edge Gallery (`/Users/tklk/Projects/gallery`) runs the **same model (Gemma 4 E2B)** but via **LiteRT-LM** (`.litertlm`) — a candidate alternative runtime to benchmark (plan OQ-14); keep `Core/LLM` runtime-swappable.
- **Pricing:** one-time, fixed, non-consumable purchase that unlocks **100% of functionality**. No subscription/tiers/IAP. Free trial = limited Decoder (≈3/month) as the only gate.
- **Languages:** v1 ships ~9 (DE, EN, TR, FR, ES, IT, AR, RU, ZH). **Build in German (default) + English first; localize the rest near the end.** Build i18n + **RTL** plumbing from day one (Arabic ships in v1).
- **Design:** "Warm Companion" — warm paper, soft teal primary, amber for action, SF Pro Rounded; full Light/Dark/System. Severity color system reused across Decoder/Dates/Vault.
- **IA:** 5 tabs — Home · Docs · Decode (center) · Dates · Settings. All persona tools + cross-persona guides live on **Home**.
- **RDG-safe:** information / translation / organization / process only — **never** personalized legal or tax advice. Always-on disclaimers; route legal items to "consult a lawyer."

## Architecture
- **Boundary-Control-Entity (BCE)** pattern, organized **per feature** (see folder layout in `IMPLEMENTATION_PLAN.md` §2.2).
- On-device model work lives in `Core/LLM`; persistence/crypto in `Core/Persistence`.
- Isolate yearly-changing data (visa thresholds, Chancenkarte points, law text) in versioned content files — never hard-code in views.

## Implementation
- Always use **red/green TDD**. Pure-logic engines (Chancenkarte points, Blue Card thresholds, eligibility checkers, 90-in-180 counter) get exhaustive unit tests.
- Decoder output must use tight structured templates with **validate/repair/retry** and never invent deadlines/obligations; gate Decoder releases on the quality-eval harness (`IMPLEMENTATION_PLAN.md` A-28).
- Every screen must support **Dynamic Type** and **RTL**.
- Work always on the main branch. do not create feature branches.
- Use the KISS (Keep it simple stupid) pattern
- Use the DRY (do not repeat yourself) pattern

## GIT
- The commit message should contain only the implementation and changes. Never refer to an LLM as commiter. Avoid such things like *Co-Authored-By* etc.
 
