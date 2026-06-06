import Foundation

/// Content model for the Pre-arrival survival kit (P6-T6).
///
/// Pure, versioned content (keys only, no literals): a friendly orientation
/// reference of essentials for arriving in Germany — grouped tips across
/// emergencies, money, daily life, transport, connectivity and etiquette — plus
/// a "before you fly" preparation checklist.
///
/// **Information only** (RDG / D9): general orientation, not legal/medical
/// advice. This file carries no logic, only the grouped tips and the checklist.

/// One tip category: a heading plus an ordered list of short bullet tips (each a
/// localization key).
struct SurvivalCategory: Identifiable, Equatable {
    let id: String
    /// Category heading.
    let headingKey: String
    /// One or more bullet tip keys, in display order.
    let tipKeys: [String]
}

/// One "before you fly" preparation item (stable id + title key). Static,
/// informational — not wired to the persisted `ChecklistStore`.
struct SurvivalChecklistItem: Identifiable, Equatable {
    let id: String
    let titleKey: String
}

/// Versioned catalog of tip categories + the before-you-fly checklist (X-06 /
/// AGENTS: content isolated from views). Phone numbers, customs and figures are
/// stable but re-verify wording periodically (OQ-1).
enum SurvivalKitCatalog {

    /// The tip categories, in reading order.
    static let categories: [SurvivalCategory] = [
        SurvivalCategory(
            id: "emergencies",
            headingKey: "tool_survival_emergencies_heading",
            tipKeys: [
                "tool_survival_emergencies_112",
                "tool_survival_emergencies_110",
                "tool_survival_emergencies_116117",
                "tool_survival_emergencies_apotheke",
            ]),
        SurvivalCategory(
            id: "money",
            headingKey: "tool_survival_money_heading",
            tipKeys: [
                "tool_survival_money_cash",
                "tool_survival_money_cards",
                "tool_survival_money_pfand",
            ]),
        SurvivalCategory(
            id: "daily_life",
            headingKey: "tool_survival_daily_heading",
            tipKeys: [
                "tool_survival_daily_sundays",
                "tool_survival_daily_water",
                "tool_survival_daily_recycling",
                "tool_survival_daily_ruhezeit",
            ]),
        SurvivalCategory(
            id: "getting_around",
            headingKey: "tool_survival_transport_heading",
            tipKeys: [
                "tool_survival_transport_validate",
                "tool_survival_transport_db",
                "tool_survival_transport_deutschlandticket",
            ]),
        SurvivalCategory(
            id: "connectivity",
            headingKey: "tool_survival_connectivity_heading",
            tipKeys: [
                "tool_survival_connectivity_sim",
                "tool_survival_connectivity_wifi",
            ]),
        SurvivalCategory(
            id: "etiquette",
            headingKey: "tool_survival_etiquette_heading",
            tipKeys: [
                "tool_survival_etiquette_punctuality",
                "tool_survival_etiquette_tipping",
                "tool_survival_etiquette_greeting",
            ]),
    ]

    /// What to sort out before you fly (static checklist).
    static let checklist: [SurvivalChecklistItem] = [
        SurvivalChecklistItem(
            id: "passport",
            titleKey: "tool_survival_check_passport"),
        SurvivalChecklistItem(
            id: "insurance",
            titleKey: "tool_survival_check_insurance"),
        SurvivalChecklistItem(
            id: "funds_accommodation",
            titleKey: "tool_survival_check_funds"),
        SurvivalChecklistItem(
            id: "return_ticket",
            titleKey: "tool_survival_check_return_ticket"),
        SurvivalChecklistItem(
            id: "cash",
            titleKey: "tool_survival_check_cash"),
        SurvivalChecklistItem(
            id: "adapter",
            titleKey: "tool_survival_check_adapter"),
        SurvivalChecklistItem(
            id: "offline_maps",
            titleKey: "tool_survival_check_offline_maps"),
    ]
}
