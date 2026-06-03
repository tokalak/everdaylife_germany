# Service für Alltag und Bürokratie in Deutschland

A product brief for an AI-assisted iOS app that helps foreigners live in, travel to, study in, or work in Germany — covering both bureaucracy (the paperwork) and Alltag (everyday life).

Written in plain language so that a smart teenager with coding skills but no business background can follow. Jargon gets defined the first time it appears.

---

## 0. The Pitch in Two Minutes

Germany is one of the richest countries in Europe and has a chronic shortage of skilled workers. To fix that, it lets foreigners move there to work, study, and build a life. But Germany is famous for bureaucracy — paperwork that is slow, in German, full of legal terms, and unforgiving if you miss a deadline.

Every newcomer hits the same wall:

- A letter arrives in the mail. It's in German. It looks important. They have no idea what it says.
- They need to register their address ("Anmeldung") within 14 days, but the city office ("Bürgeramt") has no appointment slots for two months.
- They want to open a bank account, but the bank needs the Anmeldung. The Anmeldung needs an address. The address needs a rental contract. The rental contract needs a credit score (Schufa) which doesn't exist yet because they just arrived.
- A doctor visit needs health insurance. Picking the right one is a 60-page comparison they can't read.

About 1.5 million people move to Germany every year. They google for help. They land on a handful of blogs ([AllAboutBerlin](https://allaboutberlin.com), [SimpleGermany](https://www.simplegermany.com)), a government NGO site ([Handbook Germany](https://handbookgermany.de/en)), and the official portal ([Make-It-In-Germany](https://www.make-it-in-germany.com/en)). All good — but none are a product that holds your hand through actual paperwork, scans your letters, and remembers your deadlines.

**The opportunity:** build that product as a focused iOS app with a one-time price newcomers can absorb without thinking — €29.99 lifetime, unlimited use, no subscription.

**Why now:** AI can now translate a photograph of an official German letter into plain English in 5 seconds. Two years ago that didn't work. Today it does. That single feature is the wedge.

---

## 1. Is the Idea Any Good? An Honest Critique

**The short answer: yes, but it's harder than it looks.**

The pain is real, well-documented, and unmet. You can confirm this in five minutes by reading any of these:

- The subreddit [r/germany](https://www.reddit.com/r/germany/) is essentially a 24/7 stream of "I got this letter, what does it mean?" and "how do I do X."
- [AllAboutBerlin](https://allaboutberlin.com) has been the de facto Berlin-newcomer manual in English for almost a decade because one Canadian (Nicolas Bouliane) writes better practical guides than the German government does.
- The German federal agency for migration ([BAMF](https://www.bamf.de)) publishes its own research reports admitting that newcomers struggle with basic processes.
- Multiple venture-funded startups already exist in this space — a market signal that money has been invested here.

Three things in the naive version of this idea need fact-checking:

**"It's a multi-billion-euro market."** Half true. Add up everything adjacent — relocation services, immigration law, tax filing software, expat insurance, language schools — across all of Europe, and it's many billions. But "bureaucracy concierge" by itself is probably under a billion today. The biggest dedicated player ([Localyze](https://localyze.com)) has raised about $50 million total. Pitch this as "a real, growing, defensible business in a multi-billion adjacent space," not "the next $10B startup."

**"AI plus human experts."** Right model. Pure AI is dangerous here — there have already been cases in the US where lawyers used ChatGPT for asylum filings and the AI invented fake case citations, which got real people hurt. Pure humans don't scale. AI does the volume work; humans handle the edge cases and the legally-consequential moments.

**"We won't give legal advice."** Good awareness, but Germany's rules are stricter than people realize. The Rechtsdienstleistungsgesetz (RDG) — Legal Services Act — defines what counts as legal advice. Filling out a visa form for someone after analyzing their personal situation can count, even if you don't call yourself a lawyer. See *regulatory-checklist-rdg-safe.md* for details.

**"Translating government letters."** This is the single most emotionally powerful feature in the entire product. People pay random Fiverr translators €20–50 per letter today. They will absolutely pay you for a faster, safer, unlimited version.

### What the original pitch underestimates

1. **The market is crowded, not empty.** Localyze, [Expatrio](https://expatrio.com), [Feather](https://feather-insurance.com), [Taxfix](https://taxfix.de), [Expats.de](https://expats.de), Handbook Germany, Make-It-In-Germany, every German bank's "welcome" page, plus thousands of immigration lawyers and tax advisors. "Be different" is not optional.

2. **Distribution is harder than the product.** Newcomers have no idea your brand exists. Direct-to-consumer ads are expensive — "high CAC" (Customer Acquisition Cost). For a €29.99 one-time purchase you can't spend €80 per customer. Realistic D2C playbook is content/SEO over 2+ years, plus diaspora word-of-mouth.

3. **Trust is a huge barrier.** Foreigners have often been burned by shady "visa consultants" in their home countries. Building trust takes years.

4. **The data is dangerous.** Passport scans, residence permit numbers, salary info — under GDPR (called DSGVO in German), some of this is "special category data" with extra-strict rules. One breach kills the business.

5. **Rules change yearly.** Salary thresholds for the Blue Card go up every year. The Chancenkarte (Opportunity Card) only exists since 2024. Someone has to keep the product accurate — a permanent cost.

---

## 2. The Competitive Landscape

Three categories of players already exist: independent content sites, free government/NGO portals, and venture-funded startups.

### Independent content sites

**[AllAboutBerlin](https://allaboutberlin.com)** — The gold standard. Run by Nicolas Bouliane. A personal blog grown into the most trusted Berlin-newcomer manual in English. Famous freelance tax calculator. One person, Berlin-focused. He won't build SaaS; you won't out-write him. Potential partner, not competitor.

**[SimpleGermany](https://www.simplegermany.com)** — Founded 2020 by Jen (Guatemala) and Yvonne (Germany). Heavy on YouTube, 8M+ views, ~4M annual website readers. Sells premium courses, templates, e-books. Content brand, not a product company. Potential partner.

**Reddit [r/germany](https://www.reddit.com/r/germany/)** — ~600,000 members. The world's largest unmoderated FAQ for living in Germany. The same questions repeat — every repeat question is a product opportunity.

### Free government and NGO portals

**[Handbook Germany](https://handbookgermany.de/en)** — EU- and German-federal-funded, multilingual (Arabic, Farsi, Pashto, Turkish, English, French, German, Ukrainian). Encyclopedia, not assistant. No personalization, no tools.

**[Make-It-In-Germany](https://www.make-it-in-germany.com/en)** — The official federal portal for skilled workers, students, and trainees. Authoritative but slow to update and not personalized.

**[BAMF](https://www.bamf.de)** — The agency handling asylum, integration courses, and citizenship. Authoritative source you link to, not replace.

### Venture-funded startups

**[Localyze](https://localyze.com)** — Hamburg, ~$50M raised. B2B-only, sells to HR departments. Customers include Delivery Hero and Personio. Strong on relocation workflows, weak on what happens after the first 30 days.

**[Expatrio](https://expatrio.com)** — Berlin, ~200,000 users. Bundles a blocked account (Sperrkonto), health insurance, and a German bank account. ~€5/month. Strong pre-arrival, weak post-arrival.

**[Fintiba](https://www.fintiba.com)** — Frankfurt. 300,000+ students. Same niche as Expatrio. Deep moat with Chinese students.

**[Coracle](https://www.coracle.de)** — Same niche, ~20,000 students/year. Multilingual.

**[Feather](https://feather-insurance.com)** — Berlin. Modern, trusted insurance broker for expats. Insurance only.

**[Taxfix](https://taxfix.de)** — German tax filing app. €39.99 self-serve, €99.99 with expert. Site in German limits foreign-language reach.

**[Expats.de](https://expats.de)** — Berlin since 2014. Bureaucracy translation, checklists. 35,000+ customers. Less automated.

### What this map tells you

Content sites have the audience but no product. Government sites have authority but no tools. Each startup solves a narrow slice — Localyze for big employers, Expatrio/Fintiba/Coracle for pre-arrival students, Feather for insurance, Taxfix for taxes.

**Nobody has yet built the thing that combines multilingual AI letter decoding with end-to-end newcomer support across all five customer types.** That gap is the product opportunity.

---

## 3. The Customer: Five Personas

The product helps five kinds of people. All have overlapping problems, but urgency and willingness to pay differ.

| Persona | Pain before arrival | Pain after arrival | One-time payment fit |
|---|---|---|---|
| **Tourist (Schengen visa)** | Embassy appointment waits (3–6 months in Lagos, Istanbul, Delhi, Tehran), paperwork, invitation letters, appeals | Short stay; mostly done | €29.99 lifetime is impulse-priced |
| **Student** | uni-assist portal, blocked account, language tests, student visa | Anmeldung, health insurance, working-hour rules, post-study visa | €29.99 buys 4–6 years of help — excellent value |
| **Worker / freelancer** | Choosing the right visa (Blue Card vs Skilled Worker vs Chancenkarte), degree recognition, employer paperwork | Anmeldung, tax ID, health insurance, building Schufa, freelance registration | Highest-ARPU-equivalent persona; €29.99 is cheap relative to the stakes |
| **Long-term resident** | (Already here) | Permanent residence, citizenship, family reunification, renewals | €29.99 covers a multi-year journey to citizenship |
| **Family joining a resident** | A1 German, income proof, accommodation | Daycare, school, Kindergeld, Elterngeld | Stressful moment, €29.99 absorbs easily |

A few German terms used throughout this document:

- **Anmeldung**: registering your address with the city. Required within 14 days of moving in. Without it you can't get a tax ID, can't open most bank accounts, can't sign a phone contract. It is the master key.
- **Schufa**: Germany's main credit score agency. Landlords and banks ask for a "Schufa-Auskunft" before they trust you.
- **Kindergeld**: monthly cash payment from the state for every child (~€250/month).
- **Elterngeld**: parental leave pay — replaces ~67% of salary for up to 14 months after birth.
- **Behörde**: government office. **Brief**: letter. A "Behörden-Brief" is an official letter from any government agency.

---

## 4. The Legal Boundary (Short Version)

The full version is *regulatory-checklist-rdg-safe.md*. The headline:

In Germany, "legal advice" can only be given by licensed lawyers (Rechtsanwälte). "Tax advice" can only be given by licensed tax advisors (Steuerberater). Both rules are strict. Filling out a visa application for someone after analyzing their personal situation can technically count as illegal legal advice, with fines up to €5,000 per violation.

What's safe:

- **Information**: "Here are the criteria for the Blue Card." (Factual, not personalized.)
- **Translation**: Of letters and documents, with a disclaimer that this is not legal interpretation.
- **Organization**: Document vault, deadline reminders, expiry alerts.
- **Form-filling tools**: Where the user enters their own data, the AI helps, and the user signs and submits. Never "we'll submit it for you."
- **Process navigation**: "Step 1, Step 2, Step 3." Not "you should choose option A."
- **Referral**: Send the user to a real lawyer or tax advisor for the actual advice (deferred to post-V1).

Phrasing matters. *"You should apply for the Blue Card"* = illegal. *"Your salary meets the Blue Card threshold. Here are the criteria. To choose the best route, consult an immigration lawyer."* = fine.

Three things to do before launch:

1. Hire a lawyer who specializes in this area (*Berufsrecht* and *IT-Recht*) to review every feature's wording.
2. Set up data infrastructure so all personal data stays in the EU from day one.
3. Build a clear disclaimer that says "this is information, not advice — talk to a licensed pro" without scaring users away.

---

## 5. Strategic Decisions

These are the high-level scope choices, with reasoning. They define what V1 is — and equally important, what it isn't.

### One app, persona-aware. Not multiple apps.

Splitting into separate apps per persona (tourist app, student app, worker app) was considered and rejected. Reasons:

- The killer feature (Behörden-Brief Decoder) is identical across personas.
- The natural customer lifecycle is student → worker → long-term resident → citizen. Separate apps lose the user at every transition.
- Engineering, compliance, and lawyer-review costs duplicate per app for ~1× the value.
- One brand earning trust over years beats four sub-scale brands.

Instead: **one app, one onboarding question ("What's your situation in Germany?"), persona-specific home screen and checklist underneath**. The user can switch persona in Settings at any time without losing prior progress.

### Foreigners only. Not native Germans.

Broadening to "anyone in Germany who finds paperwork annoying" was considered and rejected. Reasons:

- The Decoder's emotional power comes from the user not being able to read the letter at all. Germans can read it; they just don't enjoy it.
- The German market for "bureaucracy help" is already saturated: Taxfix, Smartsteuer, Sevdesk, Kontist, Check24, Verivox, plus every bank's app and ELSTER itself.
- Germans culturally don't pay for "explain my letter" — they ask family or use Verbraucherzentrale.
- Targeting both audiences dilutes positioning, marketing, and onboarding.

A small fraction of native Germans (young first-apartment renters, returning expats, digitally-overwhelmed elderly) might still use the app — they can, but the product isn't redesigned for them.

### iOS-first. Android, WhatsApp, Telegram all deferred.

- **iOS-first** because App Store users have ~2× the per-user revenue of Google Play and skew higher-income. For the worker persona specifically (Blue Card, €60k+) this is the right channel.
- **Android, WhatsApp, Telegram are deferred to post-launch.** The honest cost: large parts of the Turkish, Arabic, Vietnamese, Russian, Ukrainian, and Iranian diaspora populations primarily use WhatsApp or Telegram and rarely pay for iOS apps. These are the cheapest channels to add later and the most important post-V1 expansion.

### Lifetime €29.99, unlimited. No subscription, no tiers.

A subscription model (€9/€19/€49 monthly tiers) was considered and rejected. Reasons:

- The product is occasional but high-stakes. Users open it when a letter arrives, when they move, when a deadline pops up — not daily. After the chaotic first 90 days, monthly users will look at their bank statement and cancel.
- Subscription fatigue is a real cancellation driver in Germany.
- A single one-time price is faster to ship, easier to market, and accepted in countries where ongoing subscriptions are mistrusted (Turkey, Iran).

€29.99 (vs. €9.99–14.99) is chosen because the per-use AI inference cost (~€0.02–0.10 per Decoder call) and the ongoing maintenance burden (yearly law changes, content updates, lawyer reviews) need real margin. After Apple's 30% cut you net ~€21. That funds the business; €9.99 lifetime does not.

The price still anchors well against the alternative: one Fiverr translation costs €20–50 once. Lifetime everything for €29.99 is an obvious deal.

### B2B deferred. Marketplaces deferred. Slot monitoring deferred.

Each is genuinely valuable and likely the right next step after V1 proves out. But:

- B2B sales cycles are 3–6 months. Wrong for an MVP testing the basic thesis.
- Marketplaces (lawyer / Steuerberater / sworn translator referrals) need users first.
- Slot monitoring (Bürgeramt appointments, Ausländerbehörde) is fragile, hard to maintain, and operationally risky.

See section 11 for the post-V1 roadmap.

---

## 6. The V1 Product

A lean iOS app shipping in 8–10 weeks. One backend, one codebase, persona-aware UX.

### Shared core (always present)

**Behörden-Brief Decoder.** The anchor feature. User photographs any official letter from the tax office (Finanzamt), immigration office (Ausländerbehörde), health insurance (Krankenkasse), unemployment office (Jobcenter), TV/radio fee (Rundfunkbeitrag), or city office (Bürgeramt). Output: plain-language summary in the user's language, what the letter asks for, deadline added to the in-app calendar, severity flag (information / action required / urgent / legal), suggested response template, and "talk to a lawyer" disclaimer button on legally-consequential items. Unlimited use included with the €29.99 lifetime purchase. OCR runs on-device (Apple Vision); the explanation step uses a server-side LLM call.

**Document Vault.** Encrypted storage for passport, residence permit, health insurance card, driver's license, certificates of degree recognition, insurance policies, contracts. Categorized. Expiry date per document. Push notifications at 60, 30, 7 days before expiry. Hosted in the EU (non-negotiable). Export and share as PDF.

**Deadline calendar.** Auto-populated from decoded letters, checklist items, and vault expiries. Manual add supported. Push notifications at 14, 7, 1 day before. Mark as done.

**Languages.** Interface and Decoder output in 8 languages at launch: English, German, Arabic, Turkish, Russian, Ukrainian, Farsi, Spanish. Additional languages (Vietnamese, Chinese, French, Hindi) post-launch.

**Onboarding.** Three screens: language pick → persona pick → notification permission. Persona pick is the single most consequential UX choice — the home screen and active checklist follow from it.

**Settings.** Change language, change persona (preserves progress), notification preferences, vault export, GDPR controls, contact/support, restore purchase.

### Essential process guides (V1, cross-persona)

These are the five questions newcomers ask most often. **All five ship in V1.** Each is an information-and-process guide: factual steps, document lists, costs, and links to the correct Behörde — never personalized legal or tax advice (see section 4). They are reachable from in-app search and surfaced inside the relevant persona checklists, so the same guide serves a student, a worker, and a long-term resident without duplication.

1. **How do I get a residence permit? (Aufenthaltstitel)** Step-by-step of applying at the Ausländerbehörde after arrival: confirming which permit fits (links to the Worker visa-fit tool and the Long-term resident eligibility checkers), booking the appointment, the document set, the fee, and the Fiktionsbescheinigung — the interim certificate that keeps your stay legal while the application is processed — plus typical timelines. Info-only; choosing *which* route is framed as "here are the criteria — consult an immigration lawyer," per section 4.

2. **How do I register a business? (Gewerbeanmeldung vs. Freiberufler)** Explains the fork most newcomers get wrong: a trade business (Gewerbe → register at the Gewerbeamt) versus a freelance profession (Freiberufler → register only with the Finanzamt). Document list, where to go, costs, and what follows (the Finanzamt's Fragebogen zur steuerlichen Erfassung, possible IHK membership, trade tax / Gewerbesteuer). Connects to the freelancer sub-flow in the Worker persona.

3. **How do taxes work?** A plain-language map of the German tax system for a newcomer: income tax (Lohnsteuer / Einkommensteuer), the tax classes (Steuerklassen), the difference between the lifelong Steuer-ID and the business Steuernummer (links to the Worker Tax-ID organizer), when you must file a return (Steuererklärung), church tax (Kirchensteuer), VAT basics for freelancers, and where ELSTER fits. Explainer only — actual tax advice is reserved for a Steuerberater (referral deferred to post-V1).

4. **How do I get health insurance?** The public-vs-private (GKV vs. PKV) decision, who is required to be insured, how to enroll and what you need (Anmeldung, employer or residence status), and provider comparison — links to the Worker health-insurance decision tree and the Student insurance comparison. Affiliate signup links where available.

5. **How do I recognize my foreign diploma? (Anerkennung)** When recognition is mandatory (regulated professions — doctor, nurse, teacher, engineer) versus optional, the official anerkennung-in-deutschland.de portal and its "Anerkennungsfinder," which authority is responsible, document and certified-translation requirements, the Defizitbescheid concept (partial recognition with conditions), and how recognition unlocks visa routes (links to the Worker visa-fit tool).

### Per-persona V1 feature set

Each persona's checklist sits on top of the shared core. Items below are *additional* to Decoder, Vault, and Calendar.

#### Tourist (Schengen visa)

1. **Visa-need decision tool.** Inputs: nationality + purpose + duration + EU-residence status. Output: visa needed / visa-free / specific visa type. Static decision tree.
2. **Embassy document checklist** by visa type. Itinerary template, hotel/flight hold guidance, proof-of-funds requirements, photo specifications.
3. **Verpflichtungserklärung explainer.** What the formal invitation letter is, when the German host needs to sign one, where they go (their local Ausländerbehörde), what it commits them to.
4. **Travel insurance comparison** (Hanse Merkur, ADAC, Allianz — must meet the €30k minimum coverage). Affiliate links.
5. **90-in-180-days counter.** User enters past Schengen-area trip dates; app calculates remaining days.
6. **Pre-arrival survival kit.** SIM card primer, Deutschlandticket, cash-vs-card culture, Sunday closure rule, basic survival phrases.

#### Student

1. **Pre-arrival checklist by nationality** (top non-EU sources at launch: India, China, Vietnam, Iran, Türkiye, Nigeria). Includes uni-assist guidance (link, not integration), APS for the four countries that need it, language test choice.
2. **Blocked account (Sperrkonto) comparison.** Fintiba vs. Expatrio vs. Coracle vs. Deutsche Bank. Current amount (€11,904 for 2026). Affiliate signup links.
3. **Student health insurance comparison.** TK, AOK, Barmer, DAK. Affiliate signup links.
4. **Anmeldung guide.** Shared with worker persona. City-by-city for Berlin, Munich, Hamburg, Frankfurt, Cologne — required documents, what the Wohnungsgeberbestätigung is, who signs it. Info-only; appointment-slot monitoring is post-V1.
5. **Working-hours tracker.** Manual entry of working days; warns at 100/140 full days or 200/280 half-days. Resets January 1.
6. **Post-study transition checklist.** Activates when graduation date is entered. Covers the 18-month job-seeking visa, switching to Blue Card or Skilled Worker when a job is found.

#### Worker / Freelancer

Highest-stakes persona; deepest polish here.

1. **Visa-fit tool.** Inputs: salary, education level, country of degree, German level, age, prior Germany time. Output: best-fit visa(s) — Blue Card / Skilled Worker §18a / §18b / Chancenkarte / Job-seeker — with reasons.
2. **Blue Card threshold checker.** Current 2026 numbers for general professions and shortage occupations. User enters annual salary; app says yes / no / borderline.
3. **Chancenkarte points calculator.** Full point system: qualification, work experience, German language level, age, prior connection to Germany.
4. **Anmeldung guide.** Shared with student persona.
5. **Bank account comparison.** N26, DKB, Commerzbank, Sparkasse, C24 — including which accept users pre-Anmeldung. Affiliate.
6. **Health insurance decision tree.** GKV (public) vs. PKV (private) decision first, then GKV provider comparison (TK, AOK, Barmer, DAK). Affiliate where possible.
7. **Tax ID & Steuernummer organizer.** Explains the difference (Steuer-ID is lifelong personal; Steuernummer is for your business and changes when you move). Tracks when Steuer-ID arrived (auto-mailed ~90 days post-Anmeldung). Lost-ID request guide.
8. **Freelance registration sub-flow** (for freelancers only). Fragebogen zur steuerlichen Erfassung walkthrough, VAT decision (Kleinunternehmerregelung vs. regular), KSK (Künstlersozialkasse) eligibility check.

#### Family member (joining a resident)

1. **Family-reunification visa checklist.** Sponsor income proof, accommodation requirements, A1 German requirement (with exemptions for EU spouses, high-skill exemption, etc.).
2. **A1 test booking guide.** Goethe-Institut, telc, ÖSD — where to take it in the home country, cost, what's tested.
3. **Sponsor document pack.** What the German-side spouse needs to provide. Income certification template, accommodation confirmation.
4. **Post-arrival checklist.** Anmeldung (shared), opening a bank account, getting the family card (Aufenthaltskarte) at Ausländerbehörde.
5. **Kindergeld application guide.** Familienkasse form walkthrough; explains retroactive 6-month claims.
6. **Kita/school enrollment basics.** Generic guide plus links to the top-5 cities' enrollment portals. Explains Willkommensklassen for non-German-speaking children.
7. **Birth registration (Standesamt) sub-flow** — activates when user marks "expecting" or "new child."

#### Long-term resident

Lowest urgency, highest LTV — they stay for years.

1. **Niederlassungserlaubnis eligibility checker.** Inputs: years in Germany, visa type, German level, pension contributions. Tells user whether they qualify and what's missing.
2. **Einbürgerung eligibility checker.** Reflects the 2024 reform — 5 years standard, 3 years exceptional integration, dual citizenship now allowed, B1 or C1 requirement.
3. **Einbürgerungstest practice tool.** All ~300 official questions, multiple-choice mode, mark-incorrect-for-review, simulated test mode. (Questions are public domain — published by the Bundeszentrale für politische Bildung.)
4. **Renewal tracker.** Residence permit, passport, driver's license, Aufenthaltstitel card. Pulls from vault expiries; sends 90 / 60 / 30 / 7-day notifications.
5. **Family-reunification quick guide.** For long-term residents bringing a spouse / parent / child later. Shares logic with the family persona.

### Persona switching

Settings → "My situation" → list of all five personas with the current one checked.

- Switching does **not** delete previous checklist progress — it is preserved and accessible from "Past situations" in the same settings screen.
- Home screen, deadline list, and prompts reorder based on the active persona.
- Vault, Decoder, and Calendar remain persona-agnostic and always present.
- Why preserve progress: the natural lifecycle is student → worker → long-term resident → citizenship applicant. A student who graduates and switches to "worker" shouldn't lose their checklist history.

**Multiple simultaneous personas** (a worker who also has family joining) is a real use case but defers to V1.1. For V1, the data model supports it from day one — when a user switches, they're prompted "keep your old checklist accessible? (yes)" — but the UI only surfaces one active persona at a time.

---

## 7. Pricing & Revenue

### The headline price

**€29.99 lifetime, single tier, unlimited use, no subscription.**

After Apple's 30% cut (or 15% under the Small Business Program if you qualify) you net ~€21–25 per sale. This needs to fund: per-Decoder inference cost (~€0.02–0.10), EU hosting, yearly content maintenance, lawyer reviews of wording, customer support.

### Why not subscription

The product is occasional but high-stakes. Newcomers open it 2–5 times a month after the initial 90-day storm. Monthly subscriptions to occasional-use products churn fast — every cancellation reflex ("do I still need this?") fires monthly. A one-time price has no cancellation reflex.

### Why not €9.99 or €14.99 lifetime

At €9.99 you net ~€7 per sale. With per-use AI inference cost, EU hosting, compliance person, and lawyer reviews to fund, you'd need ~100,000 paying customers just to break even on a small team. At €29.99 the math works at ~25,000 paying customers — achievable in years 2–3.

The price still undercuts every alternative: one Fiverr translation is €20–50 once, one immigration lawyer hour is €200+, one Steuerberater consultation is €100+.

### Free tier

3 Behörden-Brief Decoder uses per month, free forever. Vault, calendar, and persona checklists are also free. The €29.99 purchase unlocks unlimited Decoder use. This is the customer-acquisition engine: low-friction trial, viral moment (people show decoded letters to friends), low conversion friction at the wall.

### Secondary revenue: affiliate

Affiliate links sit inside the checklists where the recommendation is already useful:

- **Travel insurance** (tourist): Hanse Merkur, ADAC, Allianz — ~€20–60 per signup.
- **Blocked account** (student): Fintiba, Expatrio, Coracle — ~€30–80 per signup.
- **Student health insurance**: TK, AOK, Barmer, DAK — ~€30–80 per signup.
- **Bank account** (worker): N26, DKB, C24 — ~€30–80 per signup.
- **Public/private health insurance** (worker): ~€50–200 per policy.

Conservatively €15–40 of additional revenue per active user over their lifetime, on top of the €29.99 purchase. Affiliate placement always presents 3+ options ranked transparently; no exclusive deals.

### What's deliberately not in V1

- **No B2B-employer sales** (post-V1, see section 11).
- **No marketplaces** (lawyer, Steuerberater, sworn translator referrals — post-V1).
- **No concierge/done-for-you tier** (post-V1).
- **No WhatsApp/Telegram channel** (post-V1; see section 11).

---

## 8. Competitor Map

| Competitor | What they do well | Gap to exploit |
|---|---|---|
| **[Localyze](https://localyze.com)** | B2B for big employers; well-funded | Not D2C; built for HR workflows; weak after first 30 days |
| **[Expatrio](https://expatrio.com)** | Student blocked account + insurance bundle | Narrow product; weak post-arrival |
| **[Feather](https://feather-insurance.com)** | Modern, trusted insurance comparison | Insurance only |
| **[SimpleGermany](https://www.simplegermany.com)** | Trusted bilingual content brand | Content, not a product |
| **[AllAboutBerlin](https://allaboutberlin.com)** | Highest-trust content brand in Berlin | Berlin only; one person; no SaaS |
| **[Handbook Germany](https://handbookgermany.de/en)** | Free, multilingual, official-feel | Government tone; no personalization; no tools |
| **[Make-It-In-Germany](https://www.make-it-in-germany.com/en)** | Official government info | Bureaucratic UX; no automation |
| **[Expats.de](https://expats.de)** | Concierge-style document handling | Sub-scale; limited automation |
| **[Fintiba](https://www.fintiba.com) / [Coracle](https://www.coracle.de)** | Blocked accounts at scale | Narrow product |
| **[N26](https://n26.com) / Bunq** | Easy bank onboarding for foreigners | Banking only |
| **[Taxfix](https://taxfix.de)** | German tax filing app | German-language only; tax-residents only |

### Differentiation thesis

1. **Multilingual AI letter decoding, unlimited.** Nobody has nailed this. It's the wedge.
2. **One app covering all five personas with a single onboarding question.** Competitors cover one slice; we cover the lifecycle.
3. **One-time €29.99 price** is novel in a subscription-dominated category — friendlier to users who mistrust ongoing charges.
4. **Honest about scope.** No B2B in V1, no marketplace in V1, no fake "AI lawyer." Information + organization + translation, with referrals deferred until the user base earns them.

---

## 9. Distribution at Launch

Since V1 is D2C and iOS-only, the channels are limited and content-heavy:

1. **SEO content in user languages.** The AllAboutBerlin playbook — write the best practical guides in the user's language, rank on Google, convert. 2+ year horizon. See *seo-content-plan-multilingual.md*.
2. **App Store Optimization (ASO).** Subtitle and keyword field tuned per language. Localized listings per major language. Custom Product Pages (Apple feature since iOS 15) per persona — drive ads to persona-specific pages.
3. **Diaspora communities.** r/germany, Turkish/Russian/Iranian Facebook groups, Reddit communities by nationality, Discord servers for international students. Free, slow, high-trust.
4. **Influencer partnerships.** SimpleGermany YouTube collaborations, mentions on AllAboutBerlin (Nicolas occasionally links to tools he likes).
5. **Referral program.** Newcomers refer next newcomers. Code per user, small in-app reward.

What's notably absent: paid acquisition. At €29.99 lifetime, the CAC math for Google or Meta ads barely works. Paid ads are a post-launch experiment, not a launch dependency.

---

## 10. The 12-Week MVP Plan

### Weeks 1–2: Foundation

- Apple Developer account, App Store Connect setup, EU data residency confirmed
- Backend skeleton (Node or Go), Postgres in EU region, S3-equivalent encrypted storage in EU
- Auth (Sign in with Apple + email)
- StoreKit 2 integration for the €29.99 non-consumable in-app purchase

### Weeks 3–4: Shared core

- Behörden-Brief Decoder: camera capture, Apple Vision OCR, LLM call, structured output
- Document Vault: encrypted storage, categories, expiry tracking
- Deadline calendar: auto-population from Decoder, manual add, notifications
- Language switcher (8 languages)

### Weeks 5–7: Persona checklists

- Onboarding flow (language → persona → notifications)
- Five persona checklists (content, not engines) — built as static JSON with translation
- Five essential cross-persona process guides (residence permit, business registration, taxes, health insurance, diploma recognition)
- Persona switching in settings with progress preservation
- Affiliate link integration

### Weeks 8–9: Polish & legal

- Lawyer review of all wording (RDG compliance)
- GDPR audit — data processing agreements, consent flows, deletion
- Disclaimer system per feature
- App Store screenshots, listing copy in 8 languages
- Custom Product Pages per persona

### Weeks 10–12: Beta and launch

- TestFlight with 50–100 invited newcomers across all five personas
- Bug fixing, content corrections
- Soft launch in one country (Türkiye, India, or Iran — the user funnels with highest known pain)
- App Store launch
- Begin SEO content publishing

### 6-month milestones

- 10,000 free users.
- 1,000 paying customers (€29.99 lifetime).
- 5,000 Behörden-Briefe decoded.
- 500 affiliate signups across all partners.
- EU-only data infrastructure validated by external GDPR audit.
- Decision point: ship Android? Add WhatsApp/Telegram? Begin B2B?

---

## 11. What's Deferred Post-V1

Ordered roughly by likely value if V1 traction validates the thesis.

1. **Android.** ~65% of the German smartphone market. Required to reach the full diaspora audience.
2. **WhatsApp bot.** Reaches Turkish, Arabic, Vietnamese, Indian, Brazilian, African newcomers who live inside WhatsApp.
3. **Telegram bot.** Reaches Russian, Ukrainian, Iranian/Farsi-speaking newcomers.
4. **B2B-employer channel.** €500–2,000 per relocating employee. Highest-value channel per logo. See *b2b-employer-sales-motion.md*.
5. **Marketplaces.** Lawyer / Steuerberater / sworn translator referrals with platform fee or commission.
6. **Concierge tier.** Human-handled paperwork. €200–800 per case.
7. **Bürgeramt slot monitoring.** Berlin, Munich, Hamburg, Frankfurt — the four worst cities. Fragile but high-value.
8. **Doctolib integration.** Direct doctor appointment booking from inside the app.
9. **Form autofill engine.** RDG-risky; needs lawyer-reviewed wording before shipping. High user value.
10. **Alltag (everyday life) features.** Healthcare navigation, housing, transport, shopping rights, cultural norms. Massive surface area; add the most-requested features first based on usage data.
11. **University B2B partnerships.** International student offices.

The discipline of *not* building these in V1 is the most important strategic decision in this plan.

---

## 12. Risks and Mitigations

1. **The German legal advice rules (RDG and StBerG).** Existential. Every feature reviewed for safe wording. Audited annually. See *regulatory-checklist-rdg-safe.md*.

2. **AI hallucinating in immigration context.** If the Decoder confidently says "you have to do X by Friday or you'll be deported" and it's wrong, real harm happens. Mitigations: tight output templates, always-on disclaimer, route anything legally consequential to a human lawyer (post-V1), log every decoded letter for review.

3. **Government TOS for slot monitoring.** Not in V1, so not a launch risk. When added: "monitor and alert" (legal), never "auto-book on the user's behalf" (likely TOS violation).

4. **Data security.** Passport scans, salary slips, residence permits are extra-sensitive under EU law. Mitigations: EU hosting only, encryption everywhere, eventual SOC2 or ISO 27001 certification.

5. **Maintenance load.** Immigration law and benefit thresholds change yearly. Dedicated compliance person required — not optional.

6. **Trust building.** Foreigners have been burned by shady consultants. Brand, transparent pricing, real testimonials, and clear "this is not legal advice" framing pay off slowly but they pay off.

7. **Government portals improving.** BAMF and Make-It-In-Germany keep adding features. Stay ahead on personalization, language coverage, and UX quality — three areas where the government will never beat a focused product.

8. **CAC at €29.99 ASP.** No room for expensive paid acquisition. The plan depends on SEO, diaspora word-of-mouth, and ASO. If these don't compound by month 9–12, revisit pricing model or add B2B early.

9. **Apple rejection risk.** "This is information, not legal advice" disclaimers must be clear; the app must not appear to give regulated advice. Pre-submission review with the lawyer is mandatory.

---

## 13. Open Questions

These remain undecided and should be resolved in the first few weeks of building.

- Which **launch country** for the soft-launch? Türkiye (large diaspora, high pain), India (huge volume, English-comfortable), Iran (acute embassy pain, high willingness to pay for relief)?
- Which **3 cities** to deepen Anmeldung guidance for first beyond Berlin? Munich, Frankfurt, Hamburg, Düsseldorf, Cologne?
- **Free tier limit**: 3 Decoder uses/month is the proposed cap. Test 2, 3, 5 in beta.
- **Affiliate partner selection**: which 1–2 partners per category to onboard pre-launch?
- **Lawyer engagement**: which firm handles the RDG review? Budget €5,000–15,000 for the launch review and €2,000–5,000 yearly.

These are decisions for the founder. The market and strategy support multiple right answers; the wrong answer is to delay until you're sure.
