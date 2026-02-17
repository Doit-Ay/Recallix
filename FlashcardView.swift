import SwiftUI

/// Flashcard study mode — converts KeyPoints into swipeable cards
struct FlashcardView: View {
    let lecture: Lecture
    
    @State private var currentIndex = 0
    @State private var dragOffset: CGSize = .zero
    @State private var cardRotation: Double = 0
    @State private var knownCount = 0
    @State private var unknownCount = 0
    @State private var isFlipped = false
    @Environment(\.dismiss) private var dismiss
    
    private var keyPoints: [String] {
        lecture.safeKeyPoints.map { $0.text }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                if keyPoints.isEmpty {
                    emptyState
                } else if currentIndex >= keyPoints.count {
                    completionView
                } else {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        progressHeader
                        
                        Spacer()
                        
                        // Card stack
                        ZStack {
                            // Next card preview (behind)
                            if currentIndex + 1 < keyPoints.count {
                                flashcard(for: keyPoints[currentIndex + 1], isFront: true)
                                    .scaleEffect(0.92)
                                    .opacity(0.5)
                            }
                            
                            // Current card
                            flashcard(for: keyPoints[currentIndex], isFront: !isFlipped)
                                .offset(dragOffset)
                                .rotationEffect(.degrees(cardRotation))
                                .gesture(dragGesture)
                                .onTapGesture {
                                    withAnimation(DesignSystem.Animation.spring) {
                                        isFlipped.toggle()
                                    }
                                }
                        }
                        
                        Spacer()
                        
                        // Swipe hints
                        HStack {
                            Label("Don't Know", systemImage: "arrow.left")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.warning)
                            Spacer()
                            Text("Tap to flip")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.tertiaryLabel)
                            Spacer()
                            Label("Know It", systemImage: "arrow.right")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.xl)
                        .padding(.bottom, DesignSystem.Spacing.md)
                    }
                }
            }
            .navigationTitle("Study Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Card
    private func flashcard(for text: String, isFront: Bool) -> some View {
        VStack {
            if isFront {
                // Question side
                VStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 36))
                        .foregroundColor(DesignSystem.Colors.primary.opacity(0.6))
                    
                    Text("Key Point \(currentIndex + 1)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryLabel)
                    
                    Text(text)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.label)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                }
            } else {
                // Back side — "Do you remember this?"
                VStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 36))
                        .foregroundColor(DesignSystem.Colors.primary)
                    
                    Text("Do you remember this concept?")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.label)
                    
                    Text(text)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryLabel)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                }
            }
        }
        .frame(maxWidth: 320, maxHeight: 400)
        .frame(maxWidth: .infinity, maxHeight: 400)
        .padding(DesignSystem.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .fill(DesignSystem.Colors.secondaryBackground)
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .stroke(DesignSystem.Colors.separator, lineWidth: 1)
        )
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }
    
    // MARK: - Drag Gesture
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
                cardRotation = Double(value.translation.width / 20)
            }
            .onEnded { value in
                let threshold: CGFloat = 100
                
                if value.translation.width > threshold {
                    // Swiped right — Known
                    withAnimation(DesignSystem.Animation.spring) {
                        dragOffset = CGSize(width: 500, height: 0)
                    }
                    knownCount += 1
                    advanceCard()
                } else if value.translation.width < -threshold {
                    // Swiped left — Unknown
                    withAnimation(DesignSystem.Animation.spring) {
                        dragOffset = CGSize(width: -500, height: 0)
                    }
                    unknownCount += 1
                    advanceCard()
                } else {
                    // Reset
                    withAnimation(DesignSystem.Animation.spring) {
                        dragOffset = .zero
                        cardRotation = 0
                    }
                }
            }
    }
    
    private func advanceCard() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(DesignSystem.Animation.standard) {
                currentIndex += 1
                dragOffset = .zero
                cardRotation = 0
                isFlipped = false
            }
        }
    }
    
    // MARK: - Sub-views
    private var progressHeader: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignSystem.Colors.primary.opacity(0.15))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignSystem.Colors.primary)
                        .frame(width: geo.size.width * CGFloat(currentIndex) / CGFloat(max(keyPoints.count, 1)))
                        .animation(DesignSystem.Animation.standard, value: currentIndex)
                }
            }
            .frame(height: 6)
            
            HStack {
                Text("\(currentIndex)/\(keyPoints.count)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryLabel)
                Spacer()
                HStack(spacing: DesignSystem.Spacing.md) {
                    Label("\(knownCount)", systemImage: "checkmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.primary)
                    Label("\(unknownCount)", systemImage: "xmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.warning)
                }
                .font(DesignSystem.Typography.caption)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.top, DesignSystem.Spacing.md)
    }
    
    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.tertiaryLabel)
            Text("No key points found")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.secondaryLabel)
            Text("Record a longer lecture to generate study cards.")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.tertiaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding(DesignSystem.Spacing.xl)
    }
    
    private var completionView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "party.popper.fill")
                .font(.system(size: 56))
                .foregroundColor(DesignSystem.Colors.primary)
            
            Text("Session Complete!")
                .font(DesignSystem.Typography.title)
                .foregroundColor(DesignSystem.Colors.label)
            
            HStack(spacing: DesignSystem.Spacing.xl) {
                VStack {
                    Text("\(knownCount)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.primary)
                    Text("Known")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryLabel)
                }
                
                VStack {
                    Text("\(unknownCount)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.warning)
                    Text("Review")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryLabel)
                }
            }
            
            Button("Done") {
                dismiss()
            }
            .font(DesignSystem.Typography.headline)
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.primary)
            .cornerRadius(DesignSystem.CornerRadius.medium)
        }
    }
}
