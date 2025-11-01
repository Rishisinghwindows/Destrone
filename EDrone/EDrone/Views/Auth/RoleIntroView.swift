import SwiftUI
import UIKit

struct RoleIntroView: View {
    let onSelect: (OnboardingAudience) -> Void
    let onHelp: () -> Void

    private let cardCornerRadius: CGFloat = 28

    var body: some View {
        ZStack {
            backgroundImage
            overlayGradient

            VStack(spacing: 32) {
                header

                VStack(spacing: 18) {
                    Text("Choose your role to get started")
                        .font(AppTheme.font(18, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 16) {
                        primaryButton(title: "I am a Farmer", role: .farmer, isPrimary: true)
                        primaryButton(title: "I am a Drone Owner", role: .owner, isPrimary: false)
                    }
                }

                Spacer()

                Button(action: onHelp) {
                    Text("Need help?")
                        .font(AppTheme.font(14, weight: .semibold))
                        .foregroundStyle(AppTheme.subtle)
                        .underline()
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 32)
            .padding(.top, 80)
        }
    }

    private var backgroundImage: some View {
        Group {
            if UIImage(named: "role-intro-background") != nil {
                Image("role-intro-background")
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [
                        AppTheme.background,
                        AppTheme.surface
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
        .overlay(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.25),
                    Color.black.opacity(0.75)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var overlayGradient: some View {
        LinearGradient(
            colors: [
                AppTheme.background.opacity(0.1),
                AppTheme.background.opacity(0.85)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        VStack(spacing: 14) {
            icon
                .frame(width: 92, height: 92)

            Text("AgriFly")
                .font(AppTheme.font(32, weight: .bold))
                .foregroundStyle(.white)

            Text("Precision Agriculture, On-Demand")
                .font(AppTheme.font(15, weight: .medium))
                .foregroundStyle(AppTheme.subtle)
        }
    }

    private var icon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .fill(Color.white.opacity(0.12))
            Image(systemName: "dot.radiowaves.up.forward")
                .font(AppTheme.font(36, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
        }
    }

    private func primaryButton(title: String, role: OnboardingAudience, isPrimary: Bool) -> some View {
        Button {
            onSelect(role)
        } label: {
            Text(title)
                .font(AppTheme.font(17, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: cardCornerRadius)
                        .fill(isPrimary ? AppTheme.accent : Color.white.opacity(0.08))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: cardCornerRadius)
                        .stroke(isPrimary ? Color.clear : AppTheme.stroke, lineWidth: 1.2)
                }
                .foregroundStyle(isPrimary ? AppTheme.textInverted : AppTheme.subtle)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RoleIntroView(
        onSelect: { _ in },
        onHelp: {}
    )
}
