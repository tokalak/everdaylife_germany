# How to Stay on the Right Side of German Law

This document explains the legal rules that govern this kind of business in Germany. The single biggest risk to *Service für Alltag und Bürokratie in Deutschland* isn't a competitor or a product flaw — it's stepping over a legal line that you didn't know existed, getting fined or sued, and shutting down.

This is written for a smart person with no legal background. Every German legal term gets explained the first time it appears. The goal is to know enough to make sound product decisions and to know exactly when to pay a lawyer for a real legal review.

**This is not legal advice.** It's an operating guide. Before you launch anything for paying customers, hire a German lawyer (Rechtsanwalt) who specializes in *Berufsrecht* (the law about professional licensing) and *IT-Recht* (technology law) to read it, point out gaps, and sign off. Update it every year.

---

## 0. The Plain-English Version

Germany has very specific rules about who is allowed to give what kind of advice. These rules exist mostly to protect consumers from scams. The two big ones are:

- **Only licensed lawyers (Rechtsanwälte) can give legal advice.** Even if you're free, even if you're well-meaning, even if you say "I'm not a lawyer." Telling someone what to do in their specific legal situation is reserved.
- **Only licensed tax advisors (Steuerberater) can give tax advice.** Same logic. Even helping someone fill in a tax form, after looking at their personal numbers, can break this rule.

There are also rules about:

- **Selling insurance.** You need a license (§34d GewO) to recommend or sell a specific insurance policy. Affiliate links to comparison content are okay if structured carefully.
- **Personal data.** Europe's GDPR (called DSGVO in German) is strict, especially about health data, religion, ethnicity, and biometric data — all of which appear constantly in this product.
- **Money laundering.** If you ever hold customer funds, the Anti-Money-Laundering law (GwG) kicks in. Solution: don't hold customer funds. Use a payment processor like [Stripe](https://stripe.com).
- **Advertising honesty.** No fake testimonials, no guaranteed outcomes, real prices.

The way to stay safe is:

1. **Don't tell people what to do.** Tell them what the criteria are, what the options are, and refer them to a licensed pro for the actual decision.
2. **Build very specific output templates** for the AI features so the AI can't accidentally cross the line.
3. **Hire a German lawyer specializing in this area** and review every feature with them before launch.
4. **Host all personal data in the EU.** Encrypt everything. Keep paperwork showing you did it right.

The rest of this document goes into the details of each rule, with examples of safe vs. unsafe wording.

---

## 1. The Six Laws That Govern This Business

Six different rule sets apply. Each has its own penalty structure.

| Law (German name) | What it covers | Penalty if violated | What triggers it |
|---|---|---|---|
| **RDG** (Rechtsdienstleistungsgesetz — Legal Services Act) | Who can give legal advice | Up to €5,000 per violation, court injunctions, reputation damage | Any individualized legal opinion on someone's specific situation |
| **StBerG** (Steuerberatungsgesetz — Tax Advisor Act) | Who can give tax advice | Criminal offense (§5), €5,000 per violation | Any individualized tax help |
| **§34d GewO** (Gewerbeordnung §34d — the rule for insurance brokers) | Who can sell/recommend insurance | Up to €5,000, injunctions, affiliate revenue lost | Recommending or selling a specific insurance policy |
| **DSGVO / GDPR** (the EU's General Data Protection Regulation) | How you handle personal data | Up to 4% of global revenue or €20 million | Processing personal data, especially sensitive categories |
| **GwG** (Geldwäschegesetz — Anti-Money-Laundering Act) | Financial intermediation | Criminal charges possible | Holding customer funds or facilitating large transactions |
| **UWG / TMG** (Gesetz gegen den unlauteren Wettbewerb — Unfair Competition Act, plus the German Telemedia Act) | Honest advertising and required website disclosures | Civil claims, fines | Misleading ads, missing legal info on website |

The first two — RDG and StBerG — are the ones that affect the product daily. The rest are mostly handled with one-time setup work.

---

## 2. The Legal Services Act (RDG) — the Big One

### What the law actually says

The Rechtsdienstleistungsgesetz (RDG) defines "Rechtsdienstleistung" — literally "legal service" — as **"any activity in another person's concrete legal matter that requires legal examination of the individual case."**

If your activity meets that definition, you need a lawyer license. Section §3 of the RDG forbids the activity unless explicitly permitted.

That's a wide net. Read it carefully: "concrete" means specific to one person; "legal examination" means thinking about how the law applies. Even unpaid, even well-meaning, even with a disclaimer — if you do this without a license, you broke the law.

### What's allowed without a license

- **Pure information.** Abstract legal information, news, FAQs, general content. ("Here are the rules for the Blue Card visa.")
- **§5 RDG ancillary services.** Legal aspects of a non-legal main business, very narrow. (For example, a real estate agent can explain what a "Schufa-Auskunft" is — that's ancillary to their main business of selling houses.)
- **§6 RDG free non-commercial help** by qualified persons. (For example, a retired lawyer can help refugees for free as charity. Doesn't apply to us.)
- **§10 RDG registration.** A lower-level legal license for specific niches (debt collection, foreign-law matters, pension matters). We don't need this for the MVP.

### The hard line — examples

| Crosses the line (illegal) | Stays on the safe side (legal) |
|---|---|
| "You should apply for the Blue Card." | "Your salary meets the Blue Card threshold (€48,300 in 2025). Here are the criteria for Blue Card and the alternative Skilled Worker visa. To choose the best route for your case, consult an immigration lawyer." |
| "This clause in your rental contract is illegal." | "This clause is similar to ones that have been ruled unenforceable by German courts (BGH ruling VIII ZR 240/12 and others). Before signing, we recommend reviewing with a Rechtsanwalt or your local tenants' association (Mieterverein)." |
| "We will file your residence permit application." | "We help you organize and prepare your documents. You sign and submit them yourself. If you want a lawyer to review before submission, we can refer one." |
| "You should appeal this rejection." | "This is a rejection letter. Typical responses include filing a formal protest (Remonstration) within one month, or accepting the decision. The implications of each option depend on your individual situation and should be discussed with an immigration lawyer." |
| "Your case is strong." | (Do not say this. Never assess outcome probability for a specific case.) |
| "Cancel this insurance policy." | "This policy has the following characteristics: [factual list]. Common reasons people switch include [factual list]. The decision depends on your individual circumstances." |

The pattern that works: **state facts, list options, suggest a licensed pro for the personal decision.**

### The required disclaimers

Every page that touches advice-adjacent territory needs a disclaimer. We use one short and one long version.

**Short version** (every advice-adjacent page footer):

> Diese Informationen ersetzen keine Rechts- oder Steuerberatung. Für eine rechtsverbindliche Beratung wenden Sie sich an einen Rechtsanwalt oder Steuerberater.
>
> (English: This information does not replace legal or tax advice. For binding advice, consult a Rechtsanwalt or Steuerberater.)

**Long version** (in the Terms of Service):

> Die durch [Name] bereitgestellten Informationen und Werkzeuge dienen ausschließlich der allgemeinen Orientierung. Sie stellen keine Rechtsdienstleistung im Sinne des Rechtsdienstleistungsgesetzes (RDG) und keine Steuerberatung im Sinne des Steuerberatungsgesetzes (StBerG) dar. Eine individuelle rechtliche Prüfung des Einzelfalls erfolgt nicht. Für eine rechtsverbindliche Beratung verweisen wir auf unser Netzwerk lizenzierter Rechtsanwälte und Steuerberater.

In English: "The information and tools provided by [Name] serve general orientation only. They do not constitute a legal service under the RDG or tax advice under the StBerG. We do not perform individual legal examination. For binding advice, we refer you to our network of licensed Rechtsanwälte and Steuerberater."

**Where this must appear:** every page footer, the account signup flow, every output of the Behörden-Brief Decoder, every visa decision tool result, every form preview, every rental contract scan result.

---

## 3. The Tax Advisor Act (StBerG) — Strict, Different

The StBerG is even stricter than the RDG. It's actually a criminal law: section §5 makes unauthorized tax advice a crime (not just a civil violation).

### What's allowed

- General tax information (deadlines, what a particular form is, links to the official tax-office sources).
- Document checklists ("here's what to bring to your Steuerberater").
- Calendar reminders ("your tax filing deadline is July 31").
- Tax ID retrieval (purely administrative — you're just helping the user request their existing number).
- ELSTER account setup walkthrough (the official tax filing portal — explaining the procedure, not the tax content).
- Steuerberater referrals with commission.

### What's not allowed

- Filling in tax returns for users.
- Recommending specific tax treatments.
- Advising whether to use the small-business rule (Kleinunternehmerregelung).
- Reviewing a tax assessment notice (Steuerbescheid) and saying "this is wrong, file a protest."
- Calculating how much tax someone owes.

### Safe vs. unsafe wording — examples

| Don't say | Say instead |
|---|---|
| "You should opt out of the Kleinunternehmerregelung." | "Kleinunternehmerregelung is available for businesses with turnover under €22,000. Here are the factual implications: [list]. The decision depends on your situation — consult a Steuerberater." |
| "This Steuerbescheid is incorrect." | "A Steuerbescheid is the official tax assessment. If you believe it is incorrect, the deadline to file a formal objection (Einspruch) is one month. The validity depends on individual circumstances — consult a Steuerberater." |
| "We'll file your VAT pre-filing (Umsatzsteuer-Voranmeldung)." | "Umsatzsteuer-Voranmeldung is due [date]. Here is the official ELSTER process. We can refer a Steuerberater who handles this." |

Same pattern: **facts and process, never "you should."**

---

## 4. Insurance Distribution (§34d GewO)

### What it covers

Any commercial activity of brokering or selling insurance in Germany requires a license under §34d of the trade regulation (Gewerbeordnung). Affiliate links plus factual comparison content sit in a grey area — usually fine if structured carefully, but worth a lawyer review.

### Safe insurance content

- Factual side-by-side comparison of policies (showing the features, not picking the winner).
- Side-by-side feature tables.
- "How to choose" educational content (here are the criteria; you decide).
- Affiliate links clearly labeled as affiliate links.
- Disclosure text: "We may receive commission from insurance providers via these links. This does not affect our comparison criteria."

### Not allowed

- "We recommend X insurance for your situation."
- "Sign up here" with our brand handling the enrollment data directly.
- Personalized "best insurance for you" recommendation engine without holding a §34d license.

### Workaround for richer features

- Partner with an existing licensed broker (someone who holds §34d). They handle the regulated activity; you provide the funnel. Most likely path.
- Or: get our own §34d license once revenue justifies the overhead — probably around Month 18.

---

## 5. EU Data Protection (DSGVO / GDPR)

GDPR is the European Union's data protection law. In Germany it's called DSGVO (Datenschutz-Grundverordnung). Penalties go up to **4% of worldwide revenue or €20 million, whichever is higher.** Big numbers, real fines.

### The "special category" data we touch

Some categories of personal data have extra-strict protection under Article 9 of GDPR. This product touches several of them constantly:

- **Health data** — insurance choices, doctor records, mental health pathway use.
- **Racial / ethnic origin** — passport country, country of origin.
- **Religion** — questions about church tax (Kirchensteuer), references to religious communities, halal/kosher finder.
- **Political opinions, philosophical beliefs** — relevant for asylum cases.
- **Biometric data** — uploaded passport photos, sometimes fingerprint records.

For each of these categories, you need **explicit consent** (a separate checkbox, plain language, easy to withdraw) on top of normal data processing rights.

### Required infrastructure before launch

Check every box before public launch:

- [ ] **All data hosted in the EU.** Every database, every backup, every log. AWS Frankfurt, Hetzner (Germany), or OVH (France) are typical choices. Document where everything lives.
- [ ] **Encryption at rest.** AES-256 for all personal data on disk.
- [ ] **Encryption in transit.** TLS 1.3 for everything sent over the network.
- [ ] **Subprocessor list.** Publicly available, updated whenever it changes. A "subprocessor" is any other company that processes data on your behalf (e.g., AWS, an email provider).
- [ ] **Data Processing Agreements (Auftragsverarbeitungsvertrag / AVV / DPA)** signed with every subprocessor. This is a standard legal contract that says "we'll handle your customer data correctly."
- [ ] **Data Protection Officer (DPO / Datenschutzbeauftragter).** Required if you process special category data at scale. Can be in-house or external (€800–€1,200/month from a contractor).
- [ ] **Data Protection Impact Assessment (DPIA).** A documented analysis of the risks before launching anything that handles sensitive data. Must be written and stored.
- [ ] **Records of Processing Activities (Verzeichnis von Verarbeitungstätigkeiten / ROPA).** Article 30 of GDPR requires a log of every data flow.
- [ ] **User rights handled in product.** UI for: access (download your data), rectification (fix mistakes), erasure (delete me), portability (export as JSON/PDF), restriction (stop processing), objection. Respond within 30 days.
- [ ] **Cookie consent banner** (TTDSG — the German Telecommunications-Telemedia Data Protection Act, in force since Dec 2021). Explicit opt-in only, never pre-checked.
- [ ] **Breach notification process.** If data leaks, you have 72 hours to report to the state data-protection authority (Landesdatenschutzbehörde).
- [ ] **Annual employee training.**
- [ ] **Pseudonymization** in analytics. (Don't track "user 123 named Anna Schmidt"; track "user h3k29qrf.")
- [ ] **Data minimization.** Only collect what you actually need for the feature. Don't grab everything "just in case."
- [ ] **Retention policy.** Auto-delete data after a defined period. No data hoarding.

### Consent flows for sensitive data

For each special-category data type:

- A separate checkbox per category. Not one big "I agree."
- Plain-language explanation of why you need this specific data.
- Easy withdrawal at any time.
- Consent log with timestamp + version of the consent text the user actually saw.

### Sub-processor discipline (especially for AI)

- **Don't use US-hosted LLMs** for any user personal data unless the data residency contract is iron-clad. Prefer European providers ([Aleph Alpha](https://aleph-alpha.com), [Mistral](https://mistral.ai) on an EU-hosted instance) or self-hosted models.
- If using Anthropic or OpenAI: zero-retention contract (they don't store your prompts), DPA signed, EU API endpoint, and **never** send unredacted special-category data even with all that.

### Cross-border transfers

- Default: no transfer outside the European Economic Area (EEA).
- If a non-EEA processor is unavoidable: use Standard Contractual Clauses (SCCs) plus a Transfer Impact Assessment.

---

## 6. Anti-Money-Laundering (GwG)

### When it applies

If you ever hold customer funds, facilitate financial transactions above thresholds (€10,000 in cash; €1,000 in crypto in some configurations), or operate as a financial intermediary.

### How to stay out of scope

Easy: don't be the bank.

- We are a platform, not a financial principal.
- We never hold customer funds in our accounts.
- All payments to third parties (lawyers, insurance, banks) flow directly between the user and the provider. We're just the matchmaker.
- Affiliate revenue and marketplace commissions are paid to us by the provider, not by the user, and they stay well below KYC (Know Your Customer) thresholds per transaction.

### If we ever scale into custodied money flows

- Trigger a full assessment by BaFin (the German Federal Financial Supervisory Authority).
- Most likely path: outsource to a regulated payment service provider — [Stripe](https://stripe.com) (which has a German entity), [Mollie](https://www.mollie.com), or [Adyen](https://www.adyen.com).

---

## 7. Honest Advertising (UWG and TMG)

### Forbidden

- Guarantees of outcome. ("Get your visa approved with us!") We cannot guarantee a visa.
- Disparaging comparisons of competitors. ("Localyze is bad" — civilly actionable.)
- Hidden affiliate disclosures.
- Fake testimonials.
- Calling things "free" when they aren't actually free.

### Required

- **Impressum** on every page (required by §5 of the German Telemedia Act / TMG). The Impressum is a legal notice giving the company name, address, contact, and registration details. Every German website needs one. There's no equivalent in most countries — it's a German specialty.
- Clear pricing displayed before purchase.
- Cooling-off period for consumers (14 days under §312g of the Civil Code).
- Honest affiliate disclosures.

---

## 8. Per-Feature Legal Audit

Before launching each feature, run it through this matrix. Every row gets a specific answer.

| # | Feature | Which law? | The specific risk | How we keep it safe |
|---|---|---|---|---|
| 1 | Behörden-Brief Decoder | RDG | "Translation" drifting into "interpretation" — saying what the letter *means* for this person | Strict output template: factual translation + general "typical next steps" + "talk to a lawyer" call-to-action. Never assess "what this means for you." |
| 2 | Document translation | None directly | n/a | Label as machine-assisted translation, not certified. |
| 3 | Sworn translator marketplace | None | n/a | Pure referral. The translator handles certification. |
| 4 | Form autofill (Anmeldung etc.) | RDG (low for administrative forms) | User-entered data only; we don't analyze legal posture | Frame as "we help you organize, you submit." Never auto-submit on the user's behalf. |
| 5 | Form pre-flight check | RDG | "Common errors" could drift into "advice on your case" | Generic checks only (missing fields, formatting). Never "you should change X to Y for legal reasons." |
| 6 | Visa decision tree | RDG (high) | Recommending a visa = legal advice | Output: factual comparison of options, criteria met vs not met. Never "you should apply for X." Lawyer-referral call-to-action on every result. |
| 7 | Blue Card / Chancenkarte calculators | RDG (low) | Factual threshold check | Display result as "your salary [meets / does not meet] the threshold." Pure fact. |
| 8 | Anerkennung routing | RDG (low) | Process navigation | Factual: "for your profession, the authority is X." Not "you should pursue recognition." |
| 9 | Job offer review | RDG (medium) | Interpreting contract clauses | Pattern-match flags only: "this clause matches one that has been disputed in court." Lawyer referral. |
| 10 | Schufa primer | RDG (low) | Information | Generic info; templates for disputes; never submit on user's behalf. |
| 11 | Rental contract scanner | RDG (high) | Interpreting contract = legal advice | Pattern-match against published court rulings; output: "this clause resembles X — review with a lawyer." |
| 12 | Nebenkostenabrechnung review (service charge statement) | RDG (medium) | Disputing on user's behalf would be RDG | Output: math check plus common-error pattern flags. Template for a dispute letter the user sends themselves. |
| 13 | Cancellation templates | RDG (low) | Templates are info; submission would be RDG | User signs and sends; we never represent. |
| 14 | Family reunification eligibility | RDG (medium) | Eligibility = legal assessment | Display criteria + match status; lawyer referral. |
| 15 | Kindergeld / Elterngeld | RDG (low) | Administrative assistance | Form-filling + factual info. User submits. |
| 16 | Citizenship / Einbürgerung | RDG (medium) | Eligibility assessment | Criteria checklist + factual info. Lawyer referral for complex cases. |
| 17 | Visa refusal Remonstration | RDG (HIGH) | Drafting appeals = legal service | Template generator with placeholders; output stamped "consult a lawyer before submitting." Strong push to marketplace. |
| 18 | Tax ID retrieval | StBerG (low) | Administrative | Procedural only. |
| 19 | ELSTER setup walkthrough | StBerG (low) | Walkthrough | Procedural only. |
| 20 | Tax deadline calendar | StBerG (low) | Information | Factual dates. |
| 21 | Tax document checklist | StBerG (medium) | "What to claim" drifting into advice | Generic checklist by employment type. Never "you should claim X." |
| 22 | Steuerberater marketplace | None | Pure referral | Commission disclosed. |
| 23 | Freelancer registration pack | StBerG (medium) | Tax-office form filling could drift into tax advice | Form assistance only; user submits; Steuerberater offered for the elections that count as tax decisions. |
| 24 | Künstlersozialkasse (KSK) eligibility | StBerG (low) | Eligibility info | Factual criteria. KSK referral. |
| 25 | Krankenkasse decision tool | §34d GewO (medium) | Recommending = brokering | Factual comparison only. Affiliate disclosure. Partner with a §34d licensee for the actual sale. |
| 26 | Bank account comparison | BaFin (low) | Financial information | Factual comparison; affiliate disclosure. |
| 27 | Insurance audit feature | §34d GewO (high) | Reviewing & recommending = brokering | Pattern-match only; output is factual ("policy has these characteristics"); recommend talking to a licensed broker. |
| 28 | Hausarzt finder | None | Directory | Pure information. |
| 29 | Mental health pathway | None | Information | Factual; crisis-hotline forwarding for severe cases. |
| 30 | Crisis hotline tier | RDG (HIGH if anything advisory creeps in) | Highest stakes | Triage to vetted lawyer marketplace + immediate disclaimer. Every interaction logged. |

---

## 9. Operational Controls

### Before each feature launches

- [ ] Legal review by a Rechtsanwalt — template phrasing approved.
- [ ] Output template includes the mandatory disclaimer.
- [ ] Decision tree never returns "you should" — only "the criteria are."
- [ ] Lawyer or Steuerberater referral call-to-action is present.
- [ ] Every output is logged for later review.
- [ ] DPIA updated to reflect any new data processing.

### Ongoing

- [ ] Quarterly RDG audit by external counsel.
- [ ] Annual full legal review of all features.
- [ ] Monthly review of customer-service transcripts that got flagged for "user asked for advice."
- [ ] Employee training on RDG-safe phrasing — at onboarding and annually.
- [ ] Escalation runbook: when a user asks for actual advice, the response includes a structured handoff to the marketplace.

### Logging requirements

For every AI-generated output, log:

- The user's input (with personally identifiable info redacted before storage).
- The version of the output template used.
- The output content.
- The disclaimer shown.
- The user's acknowledgment of the disclaimer.
- A timestamp.

**Keep the logs for 6 years.** That matches Germany's commercial law obligation to keep business documentation.

---

## 10. Documents to Have On File Before Launch

### Customer-facing

- [ ] **Terms of Service (AGB — Allgemeine Geschäftsbedingungen).** RDG-compliant scope of service, disclaimers, liability cap, withdrawal rights.
- [ ] **Privacy Policy (Datenschutzerklärung).** Compliant with GDPR Articles 13 and 14.
- [ ] **Impressum.** Compliant with §5 of TMG.
- [ ] **Cookie Policy.** Compliant with TTDSG.
- [ ] **Affiliate Disclosure.** Compliant with UWG.
- [ ] **Marketplace Terms.** For users who interact with our partner lawyers/Steuerberater through the platform.

### Partner-facing

- [ ] **Marketplace Agreement** for lawyers and Steuerberater (preserves their independence, avoids any structure that violates their own professional rules — the German *Berufsrecht*).
- [ ] **Affiliate Agreement** for insurance and banking partners.
- [ ] **Data Processing Agreement (AVV / DPA) templates** — both directions (when they process for us, and when we process for them).

### Internal

- [ ] **DPIA** (Data Protection Impact Assessment).
- [ ] **ROPA** (Records of Processing Activities).
- [ ] **Subprocessor register.**
- [ ] **Incident response runbook** (72-hour breach reporting).
- [ ] **Internal RDG/StBerG compliance manual** (this document, operationalized).
- [ ] **Employee code of conduct** — the phrasing rules everyone follows.
- [ ] **Marketplace partner due-diligence checklist** — verifying licenses, professional liability insurance, and clean professional records.

---

## 11. The Marketplace Compliance Layer

Lawyers and Steuerberater operate under their own professional rules — Berufsrecht — set by the German Federal Bar Association (Bundesrechtsanwaltskammer) and the Federal Chamber of Tax Advisors (Bundessteuerberaterkammer). Structuring the marketplace badly can expose them and us. The professional gets disciplined, we get sued.

### Required due diligence on every marketplace partner

- [ ] Active license verification (annually).
- [ ] Proof of professional liability insurance (Berufshaftpflichtversicherung — mandatory for German lawyers and tax advisors).
- [ ] No active disciplinary proceedings.
- [ ] Written confirmation that they understand our referral model.

### Structural compliance

- **No success fees.** German lawyer professional rules (BRAO §49b) restrict performance-based fees from a referrer.
- **Referral fees must be structured as platform/listing fees, not per-case kickbacks.** This is a grey area — get explicit legal sign-off.
- **No direction of legal work.** We connect, they handle the case independently.
- **No undercutting the official fee schedules** for German lawyers (RVG — Rechtsanwaltsvergütungsgesetz).
- **Independence of advice** preserved. The lawyer or Steuerberater works for the user, not for us.

### What we can safely do

- Charge listing/subscription fees to partners.
- Charge introduction/lead fees within the limits set by the professional rules.
- Provide CRM, scheduling, and payment tooling.
- Run quality ratings — carefully (defamation risk).

### What we cannot do

- Tell the partner what advice to give.
- Promise outcomes to the user.
- Receive a share of the partner's case fee in ways that compromise their independence.

This whole structure needs review by a Rechtsanwalt who specializes in **Anwaltsrecht / Berufsrecht** (the law about lawyering itself). This is a separate, additional review from the general RDG/StBerG audit.

---

## 12. The Three Ways This Goes Wrong

Almost every failure in this category traces back to one of three failure modes. Beware of all three.

### Failure mode 1: "It's just a translation" creep

The Behörden-Brief Decoder starts as a translation tool. Then someone has a great idea: "What if the Decoder told the user what to do?" Now the Decoder says, "Based on this letter, you should respond by Friday or you'll be deported."

That sentence breaks the law. The hard rule: every Decoder output has exactly three parts and no fourth:

1. The factual translation.
2. General factual context ("This kind of letter is typically about X").
3. A "talk to a lawyer" call-to-action with the partner marketplace.

Anyone proposing a fourth part has to file a feature request that goes through legal review.

### Failure mode 2: Marketplace structure that compromises lawyer independence

If our marketplace contract gives the lawyer any incentive to advise a certain way — even subtly — we have compromised their independence. The lawyer can lose their license; we can get sued for damages. The bar association reviews these arrangements skeptically.

Get the marketplace structure reviewed by a Berufsrecht specialist before launch. Not just any lawyer — one who specifically handles cases about other lawyers.

### Failure mode 3: GDPR drift via subprocessors

Engineering adds a new third-party tool one Friday afternoon. Maybe it's an analytics service, maybe a new email provider, maybe a hot new LLM. They don't think to check where it stores data. Suddenly customer data is flowing to a US server with no DPA in place. That's a breach.

The fix is a process rule: **adding any new subprocessor requires a ticketed legal sign-off**, not just engineering judgment. The DPO reviews. Then it goes live. No exceptions.

---

## 13. Pre-Launch Compliance Checklist

Before public launch (paid tier or B2B contracts), every box gets signed off:

- [ ] RDG audit by external Rechtsanwalt — signed.
- [ ] StBerG audit by external Steuerberater — signed.
- [ ] §34d GewO posture confirmed — signed by Rechtsanwalt.
- [ ] DPIA completed and signed by the DPO.
- [ ] ROPA completed.
- [ ] DPA templates reviewed.
- [ ] All customer-facing documents (TOS, Privacy, Impressum, Cookie, Marketplace) reviewed.
- [ ] Marketplace agreement reviewed by a Berufsrecht specialist.
- [ ] All output templates reviewed for RDG-safe phrasing.
- [ ] Disclaimers visible at every advice-adjacent surface.
- [ ] Breach response runbook tested via a "tabletop" exercise (simulated breach drill).
- [ ] Employee training delivered.
- [ ] Insurance: Cyber liability + Professional liability (where applicable) + Directors & Officers — all bound.

---

## 14. Year 1 Compliance Budget

This is what the compliance work actually costs. It's not optional. Cutting it is the most common way startups in this category die.

| Item | Cost |
|---|---|
| Rechtsanwalt retainer (Berufsrecht + IT-Recht specialist) | €15,000–€25,000 |
| External Steuerberater review (one-off + annual) | €5,000 |
| DPO (external contractor) | €12,000 |
| Cyber insurance | €5,000–€10,000 |
| Compliance tooling (cookie consent platform, DPIA software, ROPA tooling) | €3,000 |
| SOC 2 Type 2 readiness (Year 1 prep) — a US security certification that helps with B2B sales | €30,000 |
| Training and tabletop exercises | €3,000 |
| Contingency for legal incidents | €15,000 |
| **Total Year 1** | **€85,000–€100,000** |

---

## 15. The Three Things That Will Decide This

1. **Boundary discipline.** Every feature reviewed against the boundary. Every output template constrained. Drift kills the company. The engineer who finds a clever way to "be more helpful" by crossing the line is the engineer who shuts the company down.

2. **External counsel, not internal heroics.** A specialist German lawyer who actually knows RDG, Berufsrecht, and IT-Recht is worth every euro you pay them. Internal counsel + Google searches is not a substitute. Pay for the specialist.

3. **Document everything.** When a state data-protection authority (Landesdatenschutzbehörde) or the lawyer's chamber (Rechtsanwaltskammer) comes knocking — and at scale they eventually will, even if you've done nothing wrong — the difference between business survival and business death is whether the DPIA, the ROPA, the consent logs, and the Berufsrecht due-diligence paper trail are all on file. Build that paper trail from Day 1.
