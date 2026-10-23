import SwiftUI

/// "How gim works": the title and the six explainer sections in a scrollable column.
struct ExplainerView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(String(localized: ExplainerContent.title, table: "Explainer"))
                    .font(.title2)
                    .bold()
                ForEach(ExplainerContent.sections) { section in
                    VStack(alignment: .leading, spacing: 4) {
                        if let title = section.title() {
                            Text(title)
                                .font(.headline)
                        }
                        Text(section.body())
                            .font(.body)
                            .foregroundStyle(section.titleKey == nil ? HierarchicalShapeStyle.secondary : .primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .contain)
                }
            }
            .padding(16)
        }
    }
}

#Preview {
    ExplainerView()
        .frame(width: 480, height: 600)
}
