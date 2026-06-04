# Distribution: App Store Connect, TestFlight, and Review

With signing demystified, you can produce a trusted artifact. Now you
need a place to put it and a process to release it. In your world that
is a registry plus a deploy pipeline: `docker push`, then a rollout
that a dashboard watches, with stages you can pause and roll back.
Apple's equivalent has the same shape — a console, an artifact upload,
a staged rollout, and a release gate — but with one component you have
no analogue for: a **human reviewer** stands between your upload and
your customers. This chapter walks the path from archive to live for
Alltag, a paid, on-device app, and names every gate along the way.

## App Store Connect: the console

**App Store Connect** (ASC) is the web console at
`appstoreconnect.apple.com`. Treat it as your deploy dashboard plus
product catalog plus billing back office, all behind your Apple
account. It is where the app's *record* lives — its metadata, pricing,
privacy declarations, uploaded builds, TestFlight groups, and release
state. Crucially, ASC holds everything *except* the signed binary,
which you upload to it from Xcode or the CLI.

### Create the app record

Before any build can be associated with the app, the record must
exist. You create it once, in ASC ▸ **My Apps** ▸ **+** ▸ **New App**,
supplying:

- **Platform**: iOS.
- **Name**: the public App Store name (Alltag).
- **Primary language**: **German** — matching the project's
  `developmentLanguage: de` and the app's audience.
- **Bundle ID**: pick `de.everydaygermany.app` from the dropdown. It
  appears there only after the App ID is registered in the Developer
  portal (chapter 13), which is why that step precedes this one.
- **SKU**: an internal identifier of your choosing; ASC never shows it
  to users. It is a private key for your own bookkeeping.

This record is the durable thing. Builds come and go against it;
metadata and pricing attach to it.

### Metadata

Each App Store *version* carries marketing metadata, edited in ASC and
submitted alongside the build. For Alltag's German listing you supply:

- **Description**: the long-form pitch.
- **Keywords**: a comma-separated list feeding search.
- **Screenshots**: required, per device size class. ASC will not let
  you submit without them. iPhone-only is fine here —
  `TARGETED_DEVICE_FAMILY: "1"` means Alltag is an iPhone app, so you
  provide iPhone screenshots only.
- **Support URL**: a reachable page where users can get help. Required.
- **Promotional text, what's new**: optional and per-release.

Metadata is part of what review checks, so it must be truthful and
match the app's actual behavior.

### Pricing: Alltag is a paid app

In ASC ▸ **Pricing and Availability** you choose a **price tier**.
Apple sells through a fixed ladder of price points per region; you
pick a tier (e.g. the €4.99 point) and Apple maps it to a local price
in every territory you enable. This is the entire monetization model
for Alltag: **the app is paid once, up front, and everything unlocks
on purchase.**

That has a clean engineering consequence worth stating plainly:
**there is no in-app purchase code.** No StoreKit transactions, no
receipt validation, no entitlement-unlock logic, no subscription
renewal handling. The purchase happens entirely in Apple's
infrastructure at download time; your binary ships fully functional to
anyone who has paid. A paid-up-front app is the simplest possible
commerce integration — you write zero commerce code — which is exactly
why it was chosen for an on-device app with no backend.

> **Quarkus analogy.** A paid-up-front app is like selling a perpetual
> license that gates the *download* rather than runtime features. There
> is no license-check service to run, no entitlement call on startup —
> possession of the artifact *is* the license, enforced by the store,
> not by your code.

### App Privacy and age rating

ASC requires two declarations before submission.

**App Privacy** — Apple's "nutrition labels" — is a questionnaire
about what data your app collects and how it is used, surfaced on the
product page. This is Alltag's easiest path by a wide margin: it
collects **no** data. Everything is on-device, there is no backend, no
analytics SDK, no tracking, no account. You answer "**Data Not
Collected**" and you are done. No data types to enumerate, no linkage
or tracking disclosures.

> **Gotcha.** The privacy answers are a *binding claim*, not marketing.
> If you later add even a crash-reporting SDK that phones home, the
> declaration must change and a mismatch is a guideline violation and a
> rejection reason. Keep "Data Not Collected" honest: any third-party
> SDK that transmits data off-device invalidates it.

**Age rating** is a short questionnaire about content (violence,
mature themes, gambling, and so on). Alltag is informational, so it
lands at the lowest rating. Answer it once; it can be revised later.

## Build and upload

The artifact you ship is an **archive** — a signed, Release-
configured build of the app, the iOS analogue of a release jar built
from your `main` profile rather than a dev one.

### From Xcode

The GUI path, suitable for a first release:

1. Select a **generic iOS device** (not the Simulator) as the run
   destination, so Xcode builds for the device architecture.
2. **Product ▸ Archive.** This builds the Release configuration and
   signs it with your **distribution** certificate and an App Store
   provisioning profile.
3. The **Organizer** window opens with the archive. Choose
   **Distribute App ▸ App Store Connect ▸ Upload**.
4. Xcode validates and uploads the build to ASC.

### From the command line

For CI or reproducibility, the same in two steps — archive, then
export-and-upload:

```bash
cd ios
xcodegen generate
xcodebuild -project Alltag.xcodeproj -scheme Alltag \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/Alltag.xcarchive \
  -allowProvisioningUpdates archive
```

```bash
xcodebuild -exportArchive \
  -archivePath build/Alltag.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath build/export \
  -allowProvisioningUpdates
```

The export produces an `.ipa`, which you upload with **Transporter**
(Apple's upload app) or the `xcrun altool`/`notarytool` family. Note
that App Store and TestFlight builds are **not** separately notarized
the way a Developer-ID Mac app is — Apple's backend processes them
after upload. `notarytool` is the right tool when you distribute a Mac
app *outside* the Store; iOS Store uploads are handled by the ASC
ingestion described next.

### Processing on App Store Connect

After upload, the build is **Processing** in ASC for a few minutes to
an hour: Apple unpacks it, runs automated checks, computes thinned
variants per device, and then the build appears under the app's
**TestFlight** and **App Store** tabs, ready to attach to a version or
hand to testers. This is the asynchronous "image accepted by the
registry, now indexing" stage of your mental pipeline.

## TestFlight: the staging rollout

**TestFlight** is Apple's beta distribution channel — your staging
environment before production. A processed build can go to testers
without going to the public Store. Two audiences:

- **Internal testers**: up to 100 members of your ASC team. They get
  builds **immediately** after processing, with **no review**. This is
  your fast inner loop — the equivalent of deploying to a staging
  cluster you fully control.
- **External testers**: up to 10,000 people by email or a public link.
  Their *first* build per version requires a lightweight **Beta App
  Review**, after which subsequent builds flow with less friction.

> **Note.** Beta App Review for external testers is lighter and faster
> than full App Store review, but it is still a human gate. Plan for it
> if you intend a public beta; internal testing has no such wait, so
> use internal testers to validate the upload pipeline itself before
> exposing anything externally.

The staging analogy is exact: prove the build on a controlled audience
(internal), widen to a representative beta population (external), then
promote the *same artifact* to production. You do not rebuild for
release — the build that testers approve is the build you ship.

## App Review: the human gate

This is the component with no backend equivalent. Before a build
reaches the public Store, an Apple reviewer exercises the app against
the **App Store Review Guidelines**. There is no automated-only fast
path for a first release.

What reviewers check, and what is relevant to Alltag:

- **The app works.** No crashes, no broken features, no placeholder
  content, no dead links. A reviewer will open the app and use it; an
  obvious crash on launch is an instant rejection.
- **Privacy claims are true.** They cross-check your "Data Not
  Collected" declaration against observed behavior. For Alltag this is
  a strength — there is nothing to contradict — provided you keep it
  data-free.
- **A paid app delivers obvious value.** Apps that charge money must
  visibly justify the price; a thin or non-functional paid app is a
  classic rejection. Alltag must present clear, working functionality
  on first launch.
- **Metadata accuracy.** Screenshots and description must match the
  actual app; misleading marketing is a rejection reason.
- **Completeness.** A support URL that 404s, or a required field left
  to a placeholder, gets bounced.

Common rejection reasons map directly to those: crashes/bugs,
inaccurate privacy labels, insufficient value for a paid app,
metadata that misrepresents the app, and broken links. Review times
vary but commonly land within a day or two; you can request expedited
review for genuine emergencies. The practical posture: ship a
build that genuinely works, keep the privacy declaration honest, and
make the paid value obvious on first launch — for an honest on-device
app like Alltag, review is a formality, not a hurdle.

## Release: controlling the rollout

Approval does not automatically mean *live*. When you submit a
version, you choose how it releases:

- **Manual release**: after approval the build sits in **Pending
  Developer Release** until you click to publish. This is the
  "approved, awaiting my go" gate — useful for coordinating a launch.
- **Automatic release**: it goes live as soon as it is approved.
- **Phased release**: once live, the update rolls out to existing
  users in increasing percentages over **seven days**, rather than to
  everyone at once. This is a canary/progressive rollout, and you can
  **pause** it if something looks wrong. New downloaders always get the
  latest version immediately; phasing only throttles the
  auto-update wave to existing users.

The pattern matches a progressive deployment with a manual promotion
gate: hold at "approved," release on your signal, then ramp exposure
gradually with the ability to halt.

## Versioning: marketing version vs build number

Two numbers travel with every build, and ASC treats them very
differently. Both are real settings in `project.yml`:

```yaml
MARKETING_VERSION: "0.1.0"
CURRENT_PROJECT_VERSION: "1"
```

- **`MARKETING_VERSION`** is `CFBundleShortVersionString` — the
  public, human-facing version, here **0.1.0**. This is the number
  users see on the App Store page. Each *App Store version record* is
  keyed to one of these; you cannot submit two different builds to the
  Store under the same marketing version as separate releases.
- **`CURRENT_PROJECT_VERSION`** is the build number
  (`CFBundleVersion`), here **1**. This identifies a specific build
  *within* a marketing version. It is the value that must be **unique
  and increasing** for every upload: re-upload `0.1.0 (1)` and ASC
  rejects it as a duplicate; bump to `0.1.0 (2)` and it accepts.

The rule of thumb: bump `CURRENT_PROJECT_VERSION` for **every upload**
(including each TestFlight build of the same release), and bump
`MARKETING_VERSION` when you ship a new *public* version. The pair
`0.1.0 (1)` is read as "marketing version 0.1.0, build 1" — semver for
humans, monotonic counter for the upload system.

> **Quarkus analogy.** `MARKETING_VERSION` is your released semver
> (`0.1.0`) — what a consumer pins. `CURRENT_PROJECT_VERSION` is like a
> CI build number or a unique image tag: it must increment on every
> push to the registry so two artifacts never collide, even within the
> same released version.

## Takeaways

- App Store Connect is the console: it holds the app *record* (bundle
  id `de.everydaygermany.app`, German primary language), metadata,
  pricing, privacy, and uploaded builds — everything but the signed
  binary, which you upload to it.
- Alltag is **paid up front**, so you pick a price tier and write
  **no in-app purchase code** — the store gates the download, your
  binary ships fully unlocked.
- App Privacy is the easy path: Alltag collects **no data**, so you
  answer "Data Not Collected" — but keep it honest, since any
  data-transmitting SDK invalidates the claim.
- Distribute by **archiving** the Release build (Xcode Organizer or
  `xcodebuild archive` + Transporter/`altool`), then let ASC process
  it.
- **TestFlight** is staging: internal testers get builds instantly
  with no review; external testers need a lightweight Beta App Review.
- **App Review** is the human gate with no backend analogue: it checks
  that the app works, that privacy claims are true, and that a paid app
  delivers obvious value.
- Release manually, automatically, or in a 7-day **phased** rollout you
  can pause — a progressive deploy with a promotion gate.
- `MARKETING_VERSION` (`0.1.0`) is the public semver; bump
  `CURRENT_PROJECT_VERSION` (`1`) on **every upload** — it must be
  unique and increasing.

**Next:** *Production: Privacy, Crashes, Performance, and Updates*
