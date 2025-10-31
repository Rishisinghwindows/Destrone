import SwiftUI

struct BookingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var statusSelection: String = "All"

    private let statuses = ["All", "Pending", "Accepted", "Rejected"]

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { appState.errorMessage != nil },
            set: { if !$0 { appState.errorMessage = nil } }
        )
    }

    private var isOwner: Bool { appState.selectedRole == .owner }

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    bookingsContent
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .refreshable {
                await reload(status: statusSelection)
            }
        }
        .navigationTitle("Bookings")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await reload(status: statusSelection)
        }
        .alert(
            "Error",
            isPresented: errorBinding,
            presenting: appState.errorMessage
        ) { _ in
            Button("OK", role: .cancel) {
                appState.errorMessage = nil
            }
        } message: { message in
            Text(message)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(isOwner ? "Manage bookings" : "Your bookings")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Track status and respond quickly to requests.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.subtle)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(statuses, id: \.self) { status in
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                statusSelection = status
                            }
                            Task { await reload(status: status) }
                        } label: {
                            Text(status)
                                .font(.footnote.weight(.semibold))
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(statusSelection == status ? AppTheme.accent : AppTheme.surface)
                                .foregroundStyle(statusSelection == status ? .black : .white)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(AppTheme.accent, lineWidth: statusSelection == status ? 0 : 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var bookingsContent: some View {
        VStack(spacing: 20) {
            if appState.bookings.isEmpty {
                emptyState
            } else {
                ForEach(appState.bookings) { booking in
                    BookingCardView(
                        booking: booking,
                        isOwner: isOwner,
                        actionHandler: { newStatus in update(booking, status: newStatus) }
                    )
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.subtle)
            Text("No bookings yet")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Pull to refresh or adjust filters to see new updates.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.subtle)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func reload(status: String) async {
        do {
            let value = status == "All" ? nil : status
            try await appState.loadBookings(status: value)
        } catch {
            appState.errorMessage = error.localizedDescription
        }
    }

    private func update(_ booking: Booking, status: String) {
        Task {
            do {
                try await appState.updateBookingStatus(booking, status: status)
                await reload(status: statusSelection)
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

private struct BookingCardView: View {
    let booking: Booking
    let isOwner: Bool
    let actionHandler: (String) -> Void

    private var statusColor: Color {
        switch booking.status {
        case "Accepted": return .green
        case "Rejected": return .red
        default: return AppTheme.accent
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Booking #\(booking.id)")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(dateLabel)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.subtle)
                }
                Spacer()
                statusChip
            }

            Divider()
                .background(AppTheme.stroke)

            VStack(alignment: .leading, spacing: 6) {
                infoRow(icon: "airplane", title: "Drone", value: "#\(booking.droneId)")
                infoRow(icon: "person.crop.circle", title: "Farmer", value: booking.farmerName)
                if let mobile = booking.farmerMobile {
                    infoRow(icon: "phone.fill", title: "Contact", value: mobile)
                }
                infoRow(icon: "clock", title: "Duration", value: "\(booking.durationHours) hrs")
            }

            if isOwner && booking.status == "Pending" {
                HStack(spacing: 12) {
                    Button {
                        actionHandler("Accepted")
                    } label: {
                        Text("Accept")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(.green)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        actionHandler("Rejected")
                    } label: {
                        Text("Reject")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.9))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(AppTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(AppTheme.stroke)
        )
    }

    private var dateLabel: String {
        booking.bookingDate.formatted(.dateTime.day().month().year().hour().minute())
    }

    private var statusChip: some View {
        Text(booking.status)
            .font(.caption.weight(.bold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(statusColor.opacity(0.2))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
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
