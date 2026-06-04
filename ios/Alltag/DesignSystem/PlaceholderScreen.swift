import SwiftUI

/// Foundation-phase placeholder for tabs whose real features arrive in later
/// phases. Centralized so all stub screens look consistent and pick up the
/// Warm-Companion paper background and rounded type.
struct PlaceholderScreen: View {
    let titleKey: LocalizedStringKey
    let systemImage: String

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.paper.ignoresSafeArea()
                VStack(spacing: 12) {
                    Image(systemName: systemImage)
                        .font(.system(size: 44))
                        .foregroundStyle(AppColor.primary)
                    Text(titleKey)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(AppColor.ink)
                    Text("placeholder_coming_soon")
                        .font(.subheadline)
                        .foregroundStyle(AppColor.inkSoft)
                }
                .padding()
            }
            .navigationTitle(titleKey)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
