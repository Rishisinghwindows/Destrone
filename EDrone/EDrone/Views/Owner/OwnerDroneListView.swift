import SwiftUI

struct OwnerDroneListView: View {
    @EnvironmentObject private var appState: AppState
    @State private var activeSheet: ActiveSheet?

    private var ownedDrones: [Drone] { appState.ownerDrones }

    private var currentOwner: Owner? {
        appState.owners.first { $0.mobile == appState.mobile }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    if ownedDrones.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 18) {
                            ForEach(ownedDrones) { drone in
                                OwnerDroneCard(
                                    drone: drone,
                                    onView: { activeSheet = .view(drone) },
                                    onEdit: { activeSheet = .edit(drone) }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
            .refreshable { await reload() }

            addButton
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .add:
                NavigationStack {
                    AddDroneView()
                        .environmentObject(appState)
                }
            case .view(let drone):
                NavigationStack {
                    OwnerDroneInfoView(drone: drone)
                }
            case .edit(let drone):
                OwnerDroneStatusSheet(
                    drone: drone,
                    onUpdate: { status in
                        Task {
                            await updateStatus(drone: drone, status: status)
                            await MainActor.run { activeSheet = nil }
                        }
                    }
                )
                .presentationDetents([.fraction(0.35)])
            }
        }
        .task { await initialLoad() }
        .onChange(of: activeSheet) { newValue in
            if newValue == nil {
                Task { await reload() }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { appState.errorMessage != nil },
            set: { if !$0 { appState.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { appState.errorMessage = nil }
        } message: {
            Text(appState.errorMessage ?? "")
        }
    }

    private var header: some View {
        HStack {
            Spacer()
            Text("My Drones")
                .font(AppTheme.font(20, weight: .bold))
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(.top, 24)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "airplane.circle")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.subtle)
            Text("No drones listed yet")
                .font(AppTheme.font(18, weight: .semibold))
                .foregroundStyle(.white)
            Text("Tap the plus button to add your first drone and start receiving bookings.")
                .font(AppTheme.font(14))
                .foregroundStyle(AppTheme.subtle)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius * 2, style: .continuous)
                .fill(AppTheme.surface.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius * 2, style: .continuous)
                .stroke(AppTheme.stroke)
        )
    }

    private var addButton: some View {
        Button {
            activeSheet = .add
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius * 2, style: .continuous)
                        .fill(AppTheme.accent)
                )
                .shadow(color: AppTheme.accent.opacity(0.45), radius: 18, x: 0, y: 12)
                .padding(.trailing, 24)
                .padding(.bottom, 36)
        }
        .buttonStyle(.plain)
    }

    private func initialLoad() async {
        if appState.owners.isEmpty || appState.ownerDrones.isEmpty {
            await reload()
        }
    }

    private func reload() async {
        do {
            try await appState.loadOwners()
            try await appState.loadOwnerDrones()
        } catch {
            appState.errorMessage = error.localizedDescription
        }
    }

    private func updateStatus(drone: Drone, status: String) async {
        do {
            try await appState.updateAvailability(drone: drone, status: status)
        } catch {
            appState.errorMessage = error.localizedDescription
        }
    }

    private enum ActiveSheet: Identifiable, Equatable {
        case add
        case view(Drone)
        case edit(Drone)

        var id: String {
            switch self {
            case .add: return "add"
            case .view(let drone): return "view_\(drone.id)"
            case .edit(let drone): return "edit_\(drone.id)"
            }
        }
    }
}

private struct OwnerDroneCard: View {
    let drone: Drone
    let onView: () -> Void
    let onEdit: () -> Void

    private let cardCornerRadius: CGFloat = 16
    private let cardBackground = Color(red: 0.11, green: 0.16, blue: 0.11)
    private let borderColor = Color(red: 0.19, green: 0.32, blue: 0.18)
    private let viewButtonBackground = Color(red: 0.18, green: 0.26, blue: 0.16)
    private let editButtonBackground = Color(red: 0.24, green: 0.27, blue: 0.32)

    private var statusColor: Color {
        switch drone.status.lowercased() {
        case "available": return AppTheme.accent
        case "booked", "rented": return Color(red: 1.0, green: 0.66, blue: 0.0)
        case "maintenance": return Color.gray.opacity(0.5)
        default: return AppTheme.subtle
        }
    }

    private var statusText: String {
        switch drone.status.lowercased() {
        case "available": return "Available"
        case "booked", "rented": return "Rented"
        case "maintenance": return "Maintenance"
        default: return drone.status.capitalized
        }
    }

    private var statusBackground: Color {
        statusColor.opacity(0.18)
    }

    var body: some View {
        VStack(spacing: 0) {
            AsyncImage(url: resolvedImageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    Color.black.opacity(0.12)
                        .overlay(
                            Image(systemName: "airplane")
                                .font(.system(size: 48, weight: .semibold))
                                .foregroundStyle(AppTheme.subtle)
                        )
                }
            }
            .frame(height: 192)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
            .overlay(
                statusChip
                    .padding(14),
                alignment: .topTrailing
            )

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(drone.name)
                        .font(AppTheme.font(18, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text(priceLabel)
                        .font(AppTheme.font(13, weight: .medium))
                        .foregroundStyle(AppTheme.subtle)
                }

                Divider()
                    .overlay(AppTheme.stroke)
                    .padding(.vertical, 6)

                HStack(spacing: 14) {
                    button(title: "View Details", isPrimary: true, action: onView)
                    button(title: "Edit Drone", isPrimary: false, action: onEdit)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                    .fill(cardBackground)
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 8)
    }

    private var statusChip: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            Text(statusText)
                .font(AppTheme.font(12, weight: .semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(statusBackground)
        .foregroundStyle(statusColor)
        .clipShape(Capsule())
    }

    private func button(title: String, isPrimary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.font(13, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius * 1.2)
                        .fill(isPrimary ? viewButtonBackground : editButtonBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius * 1.2)
                        .stroke(isPrimary ? borderColor : Color.clear, lineWidth: isPrimary ? 1 : 0)
                )
                .foregroundStyle(isPrimary ? AppTheme.accent : Color.white.opacity(0.9))
        }
        .buttonStyle(.plain)
    }

    private var priceLabel: String {
        String(format: "₹%.0f / sq. m.", drone.pricePerHour)
    }

    private var resolvedImageURL: URL {
        if let urlString = drone.primaryImageURL, let url = URL(string: urlString) {
            return url
        }
        return URL(string: "https://images.unsplash.com/photo-1523966211575-eb4a01e7dd51?auto=format&fit=crop&w=1200&q=80")!
    }
}

private struct OwnerDroneStatusSheet: View {
    let drone: Drone
    let onUpdate: (String) -> Void

    private let statuses = ["Available", "Rented", "Maintenance"]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Update Status")
                .font(AppTheme.font(20, weight: .bold))
                .foregroundStyle(.white)

            Text(drone.name)
                .font(AppTheme.font(15, weight: .medium))
                .foregroundStyle(AppTheme.subtle)

            ForEach(statuses, id: \.self) { status in
                Button {
                    onUpdate(status)
                } label: {
                    HStack {
                        Text(status)
                            .font(AppTheme.font(16, weight: .semibold))
                        Spacer()
                        if status.lowercased() == drone.status.lowercased() {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 4)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface)
    }
}

private struct OwnerDroneInfoView: View {
    let drone: Drone

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    image
                    detailCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(drone.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(drone.name)
                .font(AppTheme.font(24, weight: .bold))
                .foregroundStyle(.white)
            Text("Status: \(drone.status)")
                .font(AppTheme.font(15, weight: .medium))
                .foregroundStyle(AppTheme.subtle)
        }
    }

    private var image: some View {
        AsyncImage(url: URL(string: drone.primaryImageURL ?? "")) { phase in
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
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius * 1.5))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius * 1.5)
                .stroke(AppTheme.stroke)
        )
    }

    private var detailCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            infoRow(title: "Type", value: drone.type)
            infoRow(title: "Price / hour", value: "₹\(Int(drone.pricePerHour))")
            infoRow(title: "Battery", value: (drone.batteryMah.map { "\(Int($0)) mAh" }) ?? "—")
            infoRow(title: "Tank capacity", value: (drone.capacityLiters.map { "\(Int($0)) L" }) ?? "—")
            infoRow(title: "Latitude", value: String(format: "%.4f", drone.lat))
            infoRow(title: "Longitude", value: String(format: "%.4f", drone.lon))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius * 1.4)
                .fill(AppTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius * 1.4)
                .stroke(AppTheme.stroke)
        )
    }

    private func infoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(AppTheme.font(11, weight: .semibold))
                .foregroundStyle(AppTheme.subtle)
            Text(value)
                .font(AppTheme.font(16, weight: .medium))
                .foregroundStyle(.white)
        }
    }
}
