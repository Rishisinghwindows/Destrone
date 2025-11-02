import SwiftUI

struct DroneDetailView: View {
    @EnvironmentObject private var appState: AppState
    let drone: Drone

    @State private var farmerName: String = ""
    @State private var duration: String = "2"
    @State private var successMessage: String?
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        heroImage
                        overviewSection
                        locationSection
                        bookingSection
                        if let successMessage {
                            confirmationSection(message: successMessage)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 48)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle(drone.name)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                farmerName = appState.profileName ?? appState.mobile ?? ""
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

    private var heroImage: some View {
        AsyncImage(url: imageURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                fallbackImage
            default:
                LinearGradient(
                    colors: [AppTheme.accent, AppTheme.accentMuted],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(AppTheme.stroke)
        )
        .shadow(color: AppTheme.overlay, radius: 20, x: 0, y: 12)
    }

    private var overviewSection: some View {
        detailCard(title: "Overview", icon: "info.circle") {
            infoRow(label: "Type", value: drone.type)
            infoRow(label: "Price", value: String(format: "₹%.0f per hour", drone.pricePerHour))
            infoRow(label: "Status", value: drone.status)
        }
    }

    private var locationSection: some View {
        detailCard(title: "Location", icon: "location.fill") {
            infoRow(label: "Latitude", value: String(format: "%.4f", drone.lat))
            infoRow(label: "Longitude", value: String(format: "%.4f", drone.lon))
        }
    }

    private var bookingSection: some View {
        detailCard(title: "Book this drone", icon: "calendar.badge.plus") {
            inputField("Farmer name", text: $farmerName)
            inputField("Duration (hrs)", text: $duration, keyboard: .numberPad)

            Button(action: createBooking) {
                HStack {
                    if isSubmitting { ProgressView().tint(.black) }
                    Text("Confirm booking")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.accent)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .disabled(isSubmitting || farmerName.isEmpty || Int(duration) == nil)
        }
    }

    private func confirmationSection(message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Success", systemImage: "checkmark.seal.fill")
                .foregroundStyle(.green)
                .font(.headline)
            Text(message)
                .foregroundStyle(.white)
        }
        .padding(20)
        .background(Color.green.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }

    private func detailCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(AppTheme.accent)
                Text(title.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.subtle)
            }
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(18)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.stroke)
            )
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

    private func inputField(
        _ label: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            TextField(label, text: text)
                .keyboardType(keyboard)
                .padding(12)
                .background(AppTheme.surface)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(AppTheme.stroke)
                )
        }
    }

    private func createBooking() {
        guard let hours = Int(duration) else { return }
        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                _ = try await appState.createBooking(
                    droneId: drone.id,
                    farmerName: farmerName,
                    duration: hours
                )
                successMessage = "Booking created successfully"
            } catch {
                appState.errorMessage = error.localizedDescription
            }
        }
    }

private var imageURL: URL? {
    guard let urlString = drone.primaryImageURL else { return nil }
    return URL(string: urlString)
}

@ViewBuilder
private var fallbackImage: some View {
    if let fallbackURL = URL(string: drone.fallbackImageURL()) {
        AsyncImage(url: fallbackURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                LinearGradient(
                    colors: [AppTheme.accent, AppTheme.accentMuted],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    } else {
        LinearGradient(
            colors: [AppTheme.accent, AppTheme.accentMuted],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
