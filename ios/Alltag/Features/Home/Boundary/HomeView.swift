import SwiftUI

/// The persona-aware Home (P4-02 / D10): a warm greeting with the active **mode**
/// and a progress ring, a search entry, an "Up next" card pulled from the user's
/// deadlines, the persona checklist (ticking preserved per-persona), the "Tools
/// for your mode" grid, and the cross-persona guides.
///
/// All persona content comes from `PersonaCatalog` (X-06); progress from
/// `ChecklistStore`; the next date from `DeadlineStore`. The interactive tool
/// engines and the guide reader land in **Phase 6**, so their taps surface a
/// gentle "coming soon" toast for now. Search across guides/tools is **P6-G6**.
struct HomeView: View {
    @Environment(AppEnvironment.self) private var env
    /// Lets Home deep-link into the other tabs (e.g. "Up next" → Decode/Dates).
    @Binding var selection: AppTab

    /// Embed the content in a `ScrollView` (the shipping default). The snapshot
    /// harness sets this `false` — `ImageRenderer` renders `ScrollView` content
    /// blank, so tests exercise the layout directly across the trait matrix.
    var embedInScrollView = true

    @State private var toast = false
    /// Navigation stack for in-Home pushes (guide reader; tool engines extend
    /// this in later P6 tasks). Empty in snapshot mode (no `NavigationStack`).
    @State private var path: [HomeRoute] = []

    init(selection: Binding<AppTab> = .constant(.home), embedInScrollView: Bool = true) {
        self._selection = selection
        self.embedInScrollView = embedInScrollView
    }

    private var persona: Persona? { env.personas.activePersona }

    var body: some View {
        Group {
            if embedInScrollView {
                NavigationStack(path: $path) {
                    ScrollView { content }
                        .background(AppColor.paper)
                        .navigationDestination(for: HomeRoute.self, destination: destination)
                }
            } else {
                content
            }
        }
        .background(AppColor.paper)
        .appToast(isPresented: $toast, "home_coming_soon", systemImage: "sparkles")
    }

    /// Resolves a pushed route to its screen. Guides open the reader; unknown
    /// guide ids fall through to nothing (guarded by `GuideLibraryTests`).
    @ViewBuilder
    private func destination(_ route: HomeRoute) -> some View {
        switch route {
        case .guide(let id):
            if let content = GuideLibrary.content(for: id) {
                GuideReaderView(content: content)
            }
        case .tool(let id):
            toolDestination(id)
        case .search:
            SearchView(
                items: HomeSearch.items(for: persona),
                localize: { HomeSearch.resolve($0, locale: env.language.locale) },
                onSelect: select)
        }
    }

    /// Tool ids whose interactive screen has shipped. A tile only navigates when
    /// its id is here; everything else still toasts "coming soon" (kept in sync
    /// with the `toolDestination` switch below).
    private static let implementedToolIDs: Set<String> = ["visa_fit", "blue_card", "chancenkarte", "bank_compare", "health_decision", "tax_id_organizer", "freelance_registration", "visa_need", "embassy_checklist", "verpflichtungserklaerung", "travel_insurance", "schengen_counter", "survival_kit", "prearrival_nationality", "blocked_account", "student_health", "anmeldung_guide", "working_hours", "post_study", "reunification_visa", "a1_test", "sponsor_pack", "post_arrival", "kindergeld", "kita_school", "birth_registration", "niederlassung", "einbuergerung", "einbuergerungstest", "renewal_tracker", "reunification_guide"]

    @ViewBuilder
    private func toolDestination(_ id: String) -> some View {
        switch id {
        case "visa_fit":
            VisaFitView(onOpenGuide: openGuide)
        case "blue_card":
            BlueCardView(onOpenGuide: openGuide)
        case "chancenkarte":
            ChancenkarteView(onOpenGuide: openGuide)
        case "bank_compare":
            BankCompareView()
        case "health_decision":
            HealthDecisionView(onOpenGuide: openGuide)
        case "tax_id_organizer":
            TaxIdOrganizerView(onOpenGuide: openGuide)
        case "freelance_registration":
            FreelanceRegistrationView(onOpenGuide: openGuide)
        case "visa_need":
            VisaNeedView(onOpenGuide: openGuide)
        case "embassy_checklist":
            EmbassyChecklistView(onOpenGuide: openGuide)
        case "verpflichtungserklaerung":
            VerpflichtungView()
        case "travel_insurance":
            TravelInsuranceView()
        case "schengen_counter":
            SchengenCounterView()
        case "survival_kit":
            SurvivalKitView()
        case "prearrival_nationality":
            StudentPrearrivalView(onOpenGuide: openGuide)
        case "blocked_account":
            BlockedAccountView(onOpenGuide: openGuide)
        case "student_health":
            StudentHealthView(onOpenGuide: openGuide)
        case "anmeldung_guide":
            AnmeldungView()
        case "working_hours":
            WorkingHoursView(onOpenGuide: openGuide)
        case "post_study":
            PostStudyView(onOpenGuide: openGuide)
        case "reunification_visa":
            ReunificationChecklistView(onOpenGuide: openGuide)
        case "a1_test":
            A1TestView(onOpenGuide: openGuide)
        case "sponsor_pack":
            SponsorPackView(onOpenGuide: openGuide)
        case "post_arrival":
            PostArrivalView(onOpenGuide: openGuide)
        case "kindergeld":
            KindergeldView(onOpenGuide: openGuide)
        case "kita_school":
            KitaSchoolView()
        case "birth_registration":
            BirthRegistrationView(onOpenGuide: openGuide)
        case "niederlassung":
            SettlementEligibilityView(onOpenGuide: openGuide)
        case "einbuergerung":
            CitizenshipEligibilityView(onOpenGuide: openGuide)
        case "einbuergerungstest":
            EinbuergerungstestView()
        case "renewal_tracker":
            RenewalTrackerView(documents: env.vault.documents)
        case "reunification_guide":
            ReunificationGuideView(onOpenGuide: openGuide)
        default:
            EmptyView()
        }
    }

    /// Handles a search result: guides push the reader (on top of search);
    /// implemented tools open too, the rest toast "coming soon".
    private func select(_ item: SearchItem) {
        switch item.kind {
        case .guide: openGuide(item.targetId)
        case .tool:  openTool(item.targetId)
        }
    }

    /// Opens a tool screen if it has shipped, else toasts "coming soon" — so a
    /// tile never dead-ends while engines land task by task.
    private func openTool(_ id: String) {
        if Self.implementedToolIDs.contains(id) {
            path.append(.tool(id))
        } else {
            toast = true
        }
    }

    /// Opens a guide in the reader, or toasts "coming soon" if its body hasn't
    /// shipped yet (so a tile never dead-ends).
    private func openGuide(_ id: String) {
        if GuideLibrary.content(for: id) != nil {
            path.append(.guide(id))
        } else {
            toast = true
        }
    }

    // MARK: - Content

    private var content: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            if let persona {
                greeting(persona)
                    .appReveal(index: 0)
                searchBar
                    .appReveal(index: 1)
                if let upNext { upNextCard(upNext).appReveal(index: 2) }
                checklistSection(persona).appReveal(index: 3)
                toolsSection(persona).appReveal(index: 4)
                guidesSection.appReveal(index: 5)
            } else {
                // Onboarding guarantees a persona before Home; this is a defensive
                // fallback that still teaches the next action (X-05).
                EmptyState(
                    systemImage: "person.crop.circle.badge.questionmark",
                    titleKey: "home_no_mode_title",
                    messageKey: "home_no_mode_message")
                    .padding(.top, AppSpacing.xxxl)
            }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Greeting

    private func greeting(_ persona: Persona) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(Self.greetingKey())
                    .appText(.display)
                    .foregroundStyle(AppColor.ink)
                Text("home_welcome_subtitle")
                    .appText(.body)
                    .foregroundStyle(AppColor.inkSoft)
                modeChip(persona)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            ProgressRing(fraction: env.checklist.fraction(in: persona))
        }
    }

    private func modeChip(_ persona: Persona) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: persona.systemImage)
                .imageScale(.small)
            Text("home_mode_prefix")
            Text(persona.titleKey)
                .fontWeight(.semibold)
        }
        .appText(.label)
        .foregroundStyle(persona.accent)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(persona.accent.opacity(0.14), in: Capsule())
        .padding(.top, AppSpacing.xxs)
    }

    /// Time-of-day greeting. Day-granular and purely cosmetic, so the exact hour
    /// boundary isn't worth localizing as a plural/variation table.
    static func greetingKey(now: Date = .now) -> LocalizedStringKey {
        switch Calendar.current.component(.hour, from: now) {
        case 5..<12:  return "home_greeting_morning"
        case 12..<18: return "home_greeting_day"
        default:      return "home_greeting_evening"
        }
    }

    // MARK: - Search

    private var searchBar: some View {
        Button { path.append(.search) } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppColor.inkSoft)
                Text("home_search_placeholder")
                    .appText(.body)
                    .foregroundStyle(AppColor.inkSoft)
                Spacer()
            }
            .padding(AppSpacing.md)
            .background(AppColor.card, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .strokeBorder(AppColor.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("home_search_placeholder")
    }

    // MARK: - Up next

    /// The soonest deadline the user hasn't completed (the store keeps them
    /// sorted ascending by due date), or nil if there's nothing pending.
    private var upNext: Deadline? {
        env.deadlines.deadlines.first { !$0.isDone }
    }

    private func upNextCard(_ deadline: Deadline) -> some View {
        Button { selection = .dates } label: {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Label("home_up_next", systemImage: "clock.fill")
                    .appText(.sectionHeader)
                    .foregroundStyle(AppColor.primaryDeep)
                Text(deadline.title)
                    .appText(.cardTitle)
                    .foregroundStyle(AppColor.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                DeadlineChip(
                    date: deadline.dueDate,
                    relativeLabel: DatesFormat.countdown(for: deadline.dueDate),
                    severity: deadline.severity)
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.primaryWash, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .strokeBorder(AppColor.primary.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("home_up_next")
    }

    // MARK: - Checklist

    private func checklistSection(_ persona: Persona) -> some View {
        let items = PersonaCatalog.checklist(for: persona)
        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionHeader(
                "home_checklist_title",
                trailing: Text(verbatim: "\(env.checklist.completedCount(in: persona)) / \(items.count)"))
            ForEach(items) { item in
                ChecklistRow(
                    titleKey: item.titleKey,
                    subtitleKey: item.subtitleKey,
                    isDone: env.checklist.isDone(item.id, in: persona),
                    showsDisclosure: item.link != nil
                ) {
                    env.checklist.toggle(item.id, in: persona)
                }
            }
        }
    }

    // MARK: - Tools

    private func toolsSection(_ persona: Persona) -> some View {
        let tools = PersonaCatalog.tools(for: persona)
        return Group {
            if !tools.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    sectionHeader("home_tools_title", trailing: Text(persona.titleKey))
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: AppSpacing.sm),
                                  GridItem(.flexible(), spacing: AppSpacing.sm)],
                        spacing: AppSpacing.sm
                    ) {
                        ForEach(tools) { tool in
                            ToolTile(
                                titleKey: LocalizedStringKey(tool.titleKey),
                                subtitleKey: tool.subtitleKey.map { LocalizedStringKey($0) },
                                systemImage: tool.systemImage,
                                tint: tool.tint
                            ) { openTool(tool.id) }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Guides

    private var guidesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionHeader("home_guides_title", trailing: Text("home_guides_for_everyone"))
            ForEach(PersonaCatalog.guides) { guide in
                GuideRow(
                    titleKey: LocalizedStringKey(guide.titleKey),
                    subtitleKey: guide.subtitleKey.map { LocalizedStringKey($0) },
                    systemImage: guide.systemImage,
                    tint: guide.tint
                ) { openGuide(guide.id) }
            }
        }
    }

    // MARK: - Shared

    private func sectionHeader(_ titleKey: LocalizedStringKey, trailing: Text) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(titleKey)
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            Spacer()
            trailing
                .appText(.label)
                .foregroundStyle(AppColor.inkSoft)
        }
    }
}

#Preview {
    HomeView()
        .environment(AppEnvironment.live())
        .appFontDesign()
}
