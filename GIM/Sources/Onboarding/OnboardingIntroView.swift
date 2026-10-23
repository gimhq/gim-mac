import SwiftUI

/// Groups the "How gim works" sections into the three onboarding intro pages.
enum OnboardingIntroPages {
    /// Section ids per page; the untitled `intro` section is skipped.
    static let pages: [[String]] = [
        ["noPhoneNumber", "onYourDevices"],
        ["lockedMessages", "accountId"],
        ["recoveryKey"],
    ]

    /// The explainer sections shown on `page` (zero-based), in page order.
    static func sections(for page: Int) -> [ExplainerSection] {
        guard pages.indices.contains(page) else { return [] }
        return pages[page].compactMap { id in ExplainerContent.sections.first { $0.id == id } }
    }
}

/// Three short pages explaining gim before the start screen; reuses the `Explainer` catalog.
struct OnboardingIntroView: View {
    private let onFinished: () -> Void
    @State private var page = 0

    init(onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
    }

    private var isLastPage: Bool { page == OnboardingIntroPages.pages.count - 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(String(localized: ExplainerContent.title, table: "Explainer"))
                .font(.title2.bold())
            ForEach(OnboardingIntroPages.sections(for: page)) { section in
                VStack(alignment: .leading, spacing: 4) {
                    if let title = section.title() {
                        Text(title)
                            .font(.headline)
                    }
                    Text(section.body())
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .contain)
            }
            Spacer(minLength: 0)
            Text(
                String(
                    localized: "onboarding.intro.page",
                    defaultValue: "Page \(page + 1) of \(OnboardingIntroPages.pages.count)",
                    table: "Onboarding")
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
            HStack {
                Button {
                    onFinished()
                } label: {
                    Text("onboarding.intro.skip", tableName: "Onboarding")
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                if page > 0 {
                    Button {
                        page -= 1
                    } label: {
                        Text("onboarding.intro.back", tableName: "Onboarding")
                    }
                }
                Button {
                    if isLastPage {
                        onFinished()
                    } else {
                        page += 1
                    }
                } label: {
                    if isLastPage {
                        Text("onboarding.intro.getStarted", tableName: "Onboarding")
                    } else {
                        Text("onboarding.intro.next", tableName: "Onboarding")
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
    }
}

#Preview {
    OnboardingIntroView {}
        .frame(width: 520, height: 440)
}
