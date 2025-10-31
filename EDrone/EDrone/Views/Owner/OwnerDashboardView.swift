import SwiftUI

struct OwnerDashboardView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingAddDrone = false

    private var currentOwner: Owner? {
        appState.owners.first { $0.mobile == appState.mobile }
    }

    private var ownedDrones: [Drone] {
        guard let ownerId = currentOwner?.id else { return [] }
        return appState.drones.filter { $0.ownerId == ownerId }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        header
                        actionsRow
                        dronesSection
                        bookingsShortcut
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 36)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingAddDrone) {
                AddDroneView()
                    .environmentObject(appState)
            }
            .task {
                await reload()
            }
            .alert("Error", isPresented: Binding<Bool>(
                get: { appState.errorMessage != nil },
                set: { if !$0 { appState.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { appState.errorMessage = nil }
            } message: {
                Text(appState.errorMessage ?? "")
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "airplane.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundStyle(AppTheme.accent)

            VStack(alignment: .leading, spacing: 6) {
                Text("Welcome back")
                    .font(.caption)
                    .foregroundStyle(AppTheme.subtle)
                Text(currentOwner?.name ?? appState.profileName ?? "Drone Owner")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                HStack(spacing: 6) {
                    Image(systemName: "phone.fill")
                        .font(.caption)
                    Text(appState.mobile ?? "-")
                        .font(.caption)
                        .foregroundStyle(AppTheme.subtle)
                }
            }
            Spacer()
        }
    }

    private var actionsRow: some View {
        HStack(spacing: 14) {
            Button {
                showingAddDrone = true
            } label: {
                actionTile(icon: "plus", title: "Add Drone", subtitle: "Register a new asset")
            }
            .buttonStyle(.plain)

            Button {
                Task { await reload() }
            } label: {
                actionTile(icon: "arrow.clockwise", title: "Refresh", subtitle: "Sync latest data")
            }
            .buttonStyle(.plain)
        }
    }

    private var dronesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("My Fleet")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(ownedDrones.count) drones")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.subtle)
            }

            if ownedDrones.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 44))
                        .foregroundStyle(AppTheme.subtle)
                    Text("No drones yet")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Tap add to list your first drone and start receiving bookings.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppTheme.subtle)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 26))
                .overlay(
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(AppTheme.stroke)
                )
            } else {
                LazyVStack(spacing: 18) {
                    ForEach(ownedDrones) { drone in
                        OwnerDroneCard(drone: drone) { newStatus in
                            updateStatus(drone: drone, status: newStatus)
                        }
                    }
                }
            }
        }
    }

    private var bookingsShortcut: some View {
        NavigationLink {
            BookingsView()
                .environmentObject(appState)
        } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Manage bookings")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Review farmer requests and update status.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.subtle)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.subtle)
            }
            .padding(20)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(AppTheme.stroke)
            )
        }
        .buttonStyle(.plain)
    }

    private func actionTile(icon: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .padding(12)
                .background(AppTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(AppTheme.subtle)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppTheme.stroke)
        )
    }

    private func reload() async {
        do {
            try await appState.loadOwners()
            try await appState.loadDrones()
            try await appState.loadBookings()
        } catch {
            appState.errorMessage = error.localizedDescription
        }
    }

    private func updateStatus(drone: Drone, status: String) {
        Task {
            do {
                try await appState.updateAvailability(drone: drone, status: status)
                await reload()
            } catch {
                appState.errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}

private struct OwnerDroneCard: View {
    let drone: Drone
    let updateStatus: (String) -> Void

    private var statusColor: Color {
        switch drone.status.lowercased() {
        case "available": return .green
        case "maintenance": return .orange
        default: return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(drone.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(drone.type)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.subtle)
                }
                Spacer()
                statusChip
            }

            Divider()
                .background(AppTheme.stroke)

            VStack(alignment: .leading, spacing: 6) {
                infoRow(label: "Price", value: String(format: "₹%.0f/hour", drone.pricePerHour), icon: "indianrupeesign.circle")
                infoRow(label: "Location", value: String(format: "%.3f, %.3f", drone.lat, drone.lon), icon: "location.fill")
            }

            Menu {
                Button("Available") { updateStatus("Available") }
                Button("Maintenance") { updateStatus("Maintenance") }
                Button("Booked") { updateStatus("Booked") }
            } label: {
                Text("Update availability")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.accent)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(20)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(AppTheme.stroke)
        )
    }

    private var statusChip: some View {
        Text(drone.status)
            .font(.caption.weight(.bold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(statusColor.opacity(0.25))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private func infoRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppTheme.subtle)
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            Spacer()
        }
    }
}
