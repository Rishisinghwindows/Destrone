import SwiftUI

struct AddDroneView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var type: String = ""
    @State private var price: String = "500"
    @State private var lat: String = ""
    @State private var lon: String = ""
    @State private var imageUrl: String = ""
    @State private var batteryMah: String = ""
    @State private var capacityLiters: String = ""
    @State private var isSubmitting = false

    private var isValid: Bool {
        !name.isEmpty && !type.isEmpty && Double(price) != nil && Double(lat) != nil && Double(lon) != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        Text("New drone details")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)

                        sectionContainer(title: "Basics", icon: "airplane") {
                            formField("Name", text: $name, placeholder: "Agri-Bot X4")
                            formField("Type", text: $type, placeholder: "Spray / Survey")
                            formField("Price per hour", text: $price, placeholder: "1200", keyboard: .decimalPad)
                            formField("Image URL", text: $imageUrl, placeholder: "https://example.com/drone.jpg", keyboard: .URL)
                            formField("Battery (mAh)", text: $batteryMah, placeholder: "9500", keyboard: .numberPad)
                            formField("Capacity (L)", text: $capacityLiters, placeholder: "40", keyboard: .decimalPad)
                        }

                        sectionContainer(title: "Location", icon: "location.fill") {
                            formField("Latitude", text: $lat, placeholder: "25.123", keyboard: .decimalPad)
                            formField("Longitude", text: $lon, placeholder: "85.456", keyboard: .decimalPad)
                        }

                        Button(action: save) {
                            HStack {
                                if isSubmitting { ProgressView().tint(.black) }
                                Text("Save Drone")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(isValid ? AppTheme.accent : AppTheme.accentMuted)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .disabled(!isValid || isSubmitting)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add Drone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
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

    private func formField(
        _ title: String,
        text: Binding<String>,
        placeholder: String,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .padding(12)
                .background(AppTheme.surface)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppTheme.stroke)
                )
        }
    }

    @ViewBuilder
    private func sectionContainer<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(AppTheme.accent)
                Text(title.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.subtle)
            }

            VStack(alignment: .leading, spacing: 16) {
                content()
            }
            .padding(16)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(AppTheme.stroke)
            )
        }
    }

    private func save() {
        guard let priceValue = Double(price),
              let latValue = Double(lat),
              let lonValue = Double(lon) else { return }
        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                _ = try await appState.createDrone(
                    name: name,
                    type: type,
                    price: priceValue,
                    lat: latValue,
                    lon: lonValue,
                    imageUrl: imageUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? nil
                        : imageUrl.trimmingCharacters(in: .whitespacesAndNewlines),
                    batteryMah: Double(batteryMah),
                    capacityLiters: Double(capacityLiters)
                )
                dismiss()
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
