import SwiftUI

/// Summary section component with key concepts, assignments, and quick revision
struct SummarySection: View {
    let summary: LectureSummary
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Header
            Button(action: {
                withAnimation(DesignSystem.Animation.spring) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(DesignSystem.Colors.primary)
                    
                    Text("Summary")
                        .font(DesignSystem.Typography.title2)
                        .foregroundColor(DesignSystem.Colors.label)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(DesignSystem.Colors.secondaryLabel)
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    // Narrative Text
                    Text(summary.text)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.label)
                        .lineSpacing(4)
                    
                    // Action Items
                    if !summary.actionItems.isEmpty {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Label("Action Items (Tests, Assignments)", systemImage: "calendar.badge.exclamationmark")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(DesignSystem.Colors.primary)
                            
                            ForEach(Array(summary.actionItems.enumerated()), id: \.offset) { index, item in
                                HStack(alignment: .top, spacing: DesignSystem.Spacing.xs) {
                                    Image(systemName: "circle")
                                        .font(.system(size: 8))
                                        .padding(.top, 6)
                                        .foregroundColor(DesignSystem.Colors.secondaryLabel)
                                    
                                    Text(item)
                                        .font(DesignSystem.Typography.callout)
                                        .foregroundColor(DesignSystem.Colors.label)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .padding(.top, DesignSystem.Spacing.xs)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
        .onAppear {
            // Auto-expand on appear with animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(DesignSystem.Animation.spring) {
                    isExpanded = true
                }
            }
        }
    }
}

#Preview {
    SummarySection(summary: LectureSummary(
        text: "Machine learning is a subset of artificial intelligence. It focuses on using data and algorithms to imitate the way that humans learn, gradually improving its accuracy.",
        actionItems: [
            "Complete the linear regression assignment by Friday",
            "Submit the research paper proposal next week"
        ]
    ))
    .padding()
}
