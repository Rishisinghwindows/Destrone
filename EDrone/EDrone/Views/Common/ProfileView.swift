import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    credentialCard
                    actionButtons
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 48)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundStyle(AppTheme.accent)

            VStack(alignment: .leading, spacing: 6) {
                Text("Account overview")
                    .font(.caption)
                    .foregroundStyle(AppTheme.subtle)
                Text(displayName)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                Text(currentRoleText)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.subtle)
            }
            Spacer()
        }
    }

    private var credentialCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            infoRow(label: "Mobile", value: appState.mobile ?? "-")
            infoRow(label: "Active role", value: appState.selectedRole?.label ?? "Not selected")
            if !appState.availableRoles.isEmpty {
                infoRow(label: "Available roles", value: appState.availableRoles.map(\.label).joined(separator: ", "))
            }
        }
        .padding(20)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppTheme.stroke)
        )
    }

    private var actionButtons: some View {
        VStack(spacing: 16) {
            Button {
                Task { await appState.refreshData() }
            } label: {
                Text("Reload data")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.surface)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(AppTheme.stroke)
                    )
            }

            Button(role: .destructive) {
                appState.signOut()
            } label: {
                Text("Sign out")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.red.opacity(0.9))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.subtle)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.white)
        }
    }

    private var displayName: String {
        if let name = appState.profileName, !name.isEmpty {
            return name
        }
        if let role = appState.selectedRole {
            return "\(role.label)"
        }
        return "EDrone User"
    }

    private var currentRoleText: String {
        if let role = appState.selectedRole {
            return "Currently viewing as \(role.label)"
        }
        return "Select a role to get started"
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
