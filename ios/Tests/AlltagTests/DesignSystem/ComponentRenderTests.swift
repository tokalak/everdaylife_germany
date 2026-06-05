import SwiftUI
import XCTest
@testable import Alltag

/// Render-smoke "snapshot" tests for the component library (P1-02 / DS-04…06).
///
/// Each component is rendered across the full trait matrix (light/dark, Dynamic
/// Type accessibility size, RTL) and asserted to produce a non-blank, correctly
/// sized bitmap — see `SnapshotSupport`. This is the A-06 guarantee that every
/// component lays out and remains visible under Dynamic Type XXL and RTL.
@MainActor
final class ComponentRenderTests: XCTestCase {

    func testCard() {
        SnapshotSupport.assertRenders(
            Card { Text("Letter from the Finanzamt").foregroundStyle(AppColor.ink) })
    }

    func testSeverityPillAllLevels() {
        for severity in Severity.allCases {
            SnapshotSupport.assertRenders(SeverityPill(severity))
        }
    }

    func testChecklistRow() {
        SnapshotSupport.assertRenders(
            ChecklistRow(titleKey: "Register your address",
                         subtitleKey: "Within 14 days", isDone: false))
        SnapshotSupport.assertRenders(
            ChecklistRow(titleKey: "Open a bank account", isDone: true))
    }

    func testToolTile() {
        SnapshotSupport.assertRenders(
            ToolTile(titleKey: "Blue Card check",
                     subtitleKey: "Salary threshold 2026",
                     systemImage: "creditcard.fill"))
    }

    func testGuideRow() {
        SnapshotSupport.assertRenders(
            GuideRow(titleKey: "How taxes work",
                     subtitleKey: "Steuern, simply explained",
                     systemImage: "eurosign.circle.fill"))
    }

    func testSettingsRow() {
        SnapshotSupport.assertRenders(
            SettingsRow(titleKey: "Appearance",
                        explanationKey: "Light, dark, or system",
                        systemImage: "circle.lefthalf.filled",
                        valueKey: "System"))
    }

    func testSegmentedControl() {
        SnapshotSupport.assertRenders(
            AppSegmentedControl(
                options: ["System", "Light", "Dark"],
                selection: .constant("Light"),
                label: { LocalizedStringKey($0) }))
    }

    func testPrimaryAndSecondaryButtons() {
        SnapshotSupport.assertRenders(
            PrimaryButton(titleKey: "Scan a letter", systemImage: "camera.fill") {})
        SnapshotSupport.assertRenders(
            Button("Maybe later") {}.buttonStyle(.secondary))
    }

    func testDeadlineChip() {
        let date = Date(timeIntervalSince1970: 1_718_841_600)  // fixed → deterministic
        SnapshotSupport.assertRenders(
            DeadlineChip(date: date, relativeLabel: "Due in 6 days", severity: .action))
        SnapshotSupport.assertRenders(
            DeadlineChip(date: date, severity: .urgent))
    }

    func testTrustBanner() {
        SnapshotSupport.assertRenders(TrustBanner())
    }

    func testDisclaimerNote() {
        SnapshotSupport.assertRenders(DisclaimerNote())
    }

    func testEmptyState() {
        SnapshotSupport.assertRenders(
            EmptyState(systemImage: "tray.fill",
                       titleKey: "No documents yet",
                       messageKey: "Scan or import a letter and it lands here.",
                       actionTitleKey: "Scan a letter",
                       action: {}))
    }

    func testToast() {
        SnapshotSupport.assertRenders(
            Toast(messageKey: "Added to your calendar"))
    }

    func testBottomSheetContainer() {
        SnapshotSupport.assertRenders(
            BottomSheetContainer {
                Text("Add to calendar?").foregroundStyle(AppColor.ink)
            })
    }
}
