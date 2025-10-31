import SwiftUI

struct RoleSelectView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            backgroundView

            VStack(spacing: 32) {
                Spacer()

                header

                VStack(spacing: 16) {
                    Text("Choose your role to get started")
                        .font(.title2.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)

                    roleButtons
                }

                Spacer()

                Button {
                    // Placeholder for support action
                } label: {
                    Text("Need help?")
                        .underline()
                        .foregroundStyle(AppTheme.subtle)
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 40)
        }
        .navigationBarBackButtonHidden()
    }

    private var backgroundView: some View {
        AsyncImage(url: URL(string: "https://source.unsplash.com/featured/1200x2000?agriculture,drone")) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                LinearGradient(
                    colors: [AppTheme.background, AppTheme.surface],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
        .overlay(
            LinearGradient(
                colors: [.black.opacity(0.2), .black.opacity(0.55)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "circle.grid.3x3")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.accent)
            Text("AgriFly")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.white)
            Text("Precision Agriculture, On-Demand")
                .font(.subheadline)
                .foregroundStyle(AppTheme.subtle)
        }
    }

    private var roleButtons: some View {
        VStack(spacing: 14) {
            ForEach(Array(appState.availableRoles.enumerated()), id: \.element.id) { item in
                let index = item.offset
                let role = item.element

                Button {
                    appState.switchRole(role)
                    Task { await appState.refreshData() }
                } label: {
                    Text(label(for: role))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(buttonBackground(forPrimary: index == 0))
                        .foregroundStyle(buttonForeground(forPrimary: index == 0))
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(AppTheme.stroke, lineWidth: index == 0 ? 0 : 1)
                        )
                }
                .buttonStyle(.plain)
            }

            Button {
                appState.signOut()
            } label: {
                Text("Sign out")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.05))
                    .foregroundStyle(.white.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
    }

    private func label(for role: UserRole) -> String {
        switch role {
        case .farmer:
            return "I am a Farmer"
        case .owner:
            return "I am a Drone Owner"
        }
    }

    private func buttonBackground(forPrimary isPrimary: Bool) -> LinearGradient {
        if isPrimary {
            return LinearGradient(colors: [AppTheme.accent, AppTheme.accentMuted], startPoint: .leading, endPoint: .trailing)
        }
        return LinearGradient(colors: [Color.white.opacity(0.04), Color.white.opacity(0.08)], startPoint: .top, endPoint: .bottom)
    }

    private func buttonForeground(forPrimary isPrimary: Bool) -> Color {
        isPrimary ? .black : .white
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
