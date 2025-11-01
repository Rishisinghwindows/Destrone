import SwiftUI

enum OnboardingAudience: String, CaseIterable {
    case farmer
    case owner

    var label: String {
        switch self {
        case .farmer: return "Farmer"
        case .owner: return "Owner"
        }
    }
}

struct OnboardingView: View {
    let audience: OnboardingAudience
    let onSkip: () -> Void
    let onFinish: () -> Void

    @State private var currentIndex = 0

    private let cardCornerRadius: CGFloat = 28

    private var slides: [Slide] {
        Slide.samples(for: audience)
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                TabView(selection: $currentIndex) {
                    ForEach(Array(slides.enumerated()), id: \.element.id) { index, slide in
                        slideCard(for: slide, isLast: index == slides.count - 1)
                            .tag(index)
                            .padding(.horizontal, 20)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 24)
                .padding(.bottom, 36)
            }
        }
    }

    private var header: some View {
        HStack {
            Spacer()
            Button("Skip") { onSkip() }
                .font(AppTheme.font(16, weight: .semibold))
                .foregroundStyle(AppTheme.subtle)
                .padding(.trailing, 28)
                .padding(.top, 16)
        }
    }

    private func slideCard(for slide: Slide, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            AsyncImage(url: slide.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    LinearGradient(
                        colors: [AppTheme.surface, AppTheme.elevatedSurface],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
            .frame(height: 340)
            .frame(maxWidth: .infinity)
            .clipped()
            .clipShape(RoundedCorners(radius: cardCornerRadius, corners: [.topLeft, .topRight]))

            VStack(alignment: .leading, spacing: 18) {
                Text(slide.title)
                    .font(AppTheme.font(28, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(slide.subtitle)
                    .font(AppTheme.font(16))
                    .foregroundStyle(AppTheme.subtle)
                    .lineSpacing(6)

                indicatorBar
                    .padding(.top, 8)

                Button(action: advance) {
                    Text(isLast ? "Get Started" : "Next")
                        .font(AppTheme.font(18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.accent)
                        .foregroundStyle(AppTheme.textInverted)
                        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 32)
            .background(Color.black)
            .clipShape(RoundedCorners(radius: cardCornerRadius, corners: [.bottomLeft, .bottomRight]))
        }
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .fill(Color.black)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .stroke(AppTheme.stroke)
        )
        .shadow(color: AppTheme.overlay.opacity(0.35), radius: 24, x: 0, y: 14)
        .frame(maxWidth: 360)
    }

    private var indicatorBar: some View {
        HStack(spacing: 10) {
            ForEach(slides.indices, id: \.self) { index in
                Capsule()
                    .fill(index == currentIndex ? AppTheme.accent : AppTheme.subtle.opacity(0.3))
                    .frame(width: index == currentIndex ? 22 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: currentIndex)
            }
        }
    }

    private func advance() {
        if currentIndex < slides.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentIndex += 1
            }
        } else {
            onFinish()
        }
    }

    private struct Slide: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let imageURL: URL?

        static func samples(for audience: OnboardingAudience) -> [Slide] {
            switch audience {
            case .farmer:
                return [
                    Slide(
                        id: "farmer_1",
                        title: "Boost Your Yields",
                        subtitle: "Rent drones for precision spraying, crop monitoring, and soil analysis to maximize harvest quality.",
                        imageURL: URL(string: "https://images.unsplash.com/photo-1508873696983-2dfd5898f08b?auto=format&fit=crop&w=1200&q=80")
                    ),
                    Slide(
                        id: "farmer_2",
                        title: "See Fields Clearly",
                        subtitle: "Capture real-time aerial imagery, detect problem zones early, and make data-backed decisions.",
                        imageURL: URL(string: "https://images.unsplash.com/photo-1484704849700-f032a568e944?auto=format&fit=crop&w=1200&q=80")
                    ),
                    Slide(
                        id: "farmer_3",
                        title: "Book in Minutes",
                        subtitle: "Choose nearby drones, compare pricing, and schedule missions from a single dashboard.",
                        imageURL: URL(string: "https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=1200&q=80")
                    )
                ]
            case .owner:
                return [
                    Slide(
                        id: "owner_1",
                        title: "Grow Your Drone Business",
                        subtitle: "List your fleet, set pricing, and reach farmers looking for expert aerial services.",
                        imageURL: URL(string: "https://images.unsplash.com/photo-1523966211575-eb4a01e7dd51?auto=format&fit=crop&w=1200&q=80")
                    ),
                    Slide(
                        id: "owner_2",
                        title: "Manage Missions Easily",
                        subtitle: "Accept requests, update drone availability, and track bookings from any device.",
                        imageURL: URL(string: "https://images.unsplash.com/photo-1489515217757-5fd1be406fef?auto=format&fit=crop&w=1200&q=80")
                    ),
                    Slide(
                        id: "owner_3",
                        title: "Build Trusted Partnerships",
                        subtitle: "Deliver consistent results, earn repeat business, and expand into new regions.",
                        imageURL: URL(string: "https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?auto=format&fit=crop&w=1200&q=80")
                    )
                ]
            }
        }
    }
}

private struct RoundedCorners: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    OnboardingView(audience: .farmer, onSkip: {}, onFinish: {})
}
