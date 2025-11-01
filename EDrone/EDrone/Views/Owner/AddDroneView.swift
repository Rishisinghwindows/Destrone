import SwiftUI
import PhotosUI
import UIKit

struct AddDroneView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var locationManager = LocationManager.shared

    @State private var form = DroneForm()
    @State private var galleryItems: [GalleryItem] = []
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var manualImageURL = ""
    @State private var isSubmitting = false

    private let uploadService = ImageUploadService()
    private let maxGalleryCount = 3

    private var remainingSlots: Int { max(0, maxGalleryCount -
galleryItems.count) }

    private var isValid: Bool {
        !form.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Double(form.pricePerHour) != nil &&
        Double(form.latitude) != nil &&
        Double(form.longitude) != nil
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        photosSection
                        basicsSection
                        specsSection
                        locationSection
                            .padding(.bottom, 120)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
                .scrollIndicators(.hidden)

                publishButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
            }
            .navigationTitle("List a New Drone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", role: .cancel) { dismiss() }
                        .font(AppTheme.font(15, weight: .semibold))
                        .foregroundStyle(AppTheme.subtle)
                }
            }
            .alert(
                "Error",
                isPresented: Binding(
                    get: { appState.errorMessage != nil },
                    set: { if !$0 { appState.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) { appState.errorMessage = nil }
            } message: {
                Text(appState.errorMessage ?? "")
            }
        }
        .onAppear { locationManager.requestAccess() }
        .onChange(of: pickerItems) { newItems in
            Task { await handlePicker(items: newItems) }
        }
    }

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionHeader(
                title: "Drone Photos",
                subtitle: "Upload up to three shots that highlight the hardware and payload in action."
            )

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing:
12), count: 3), spacing: 12) {
                ForEach(galleryItems) { item in
                    ZStack(alignment: .topTrailing) {
                        galleryPreview(for: item)
                            .frame(height: 95)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius:
AppTheme.cornerRadius, style: .continuous))

                        Button {
                            withAnimation(.easeInOut) {
                                galleryItems.removeAll { $0.id == item.id }
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(5)
                                .background(Color.black.opacity(0.55))
                                .clipShape(Circle())
                        }
                        .padding(6)
                    }
                }

                if remainingSlots > 0 {
                    PhotosPicker(selection: $pickerItems, maxSelectionCount:
remainingSlots, matching: .images) {
                        VStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .semibold))
                            Text("Add Photo")
                                .font(AppTheme.font(12, weight: .semibold))
                        }
                        .frame(height: 95)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(AppTheme.subtle)
                        .background(AppTheme.surface.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius:
AppTheme.cornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius:
AppTheme.cornerRadius, style: .continuous)
                                .stroke(AppTheme.stroke)
                        )
                    }
                }
            }

            VStack(spacing: 12) {
                TextField("Paste image URL", text: $manualImageURL)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .padding(14)
                    .background(AppTheme.surface.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius:
AppTheme.cornerRadius, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius:
AppTheme.cornerRadius, style: .continuous).stroke(AppTheme.stroke))
                    .foregroundStyle(AppTheme.textPrimary)

                Button {
                    addManualImage()
                } label: {
                    Label("Add URL", systemImage: "link")
                        .font(AppTheme.font(13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AppTheme.surface.opacity(0.45))
                        .clipShape(RoundedRectangle(cornerRadius:
AppTheme.cornerRadius, style: .continuous))
                }
                .disabled(manualImageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || remainingSlots == 0)
            }
        }
    }

    private var basicsSection: some View {
        sectionCard {
            sectionHeader(title: "Rental Details")

            VStack(spacing: 16) {
                outlinedField(
                    label: "Drone Name",
                    placeholder: "e.g., DJI Agras T40",
                    text: $form.name
                )

                outlinedField(
                    label: "Price per hour (₹)",
                    placeholder: "1500",
                    text: $form.pricePerHour,
                    keyboard: .decimalPad
                )

                Picker("Drone Type", selection: $form.kind) {
                    ForEach(DroneKind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.top, 6)
            }
        }
    }

    private var specsSection: some View {
        sectionCard {
            sectionHeader(title: "Specifications")

            VStack(spacing: 16) {
                outlinedField(
                    label: "Battery (mAh)",
                    placeholder: "22000",
                    text: $form.batteryMah,
                    keyboard: .numberPad
                )

                outlinedField(
                    label: "Tank Capacity (Liters)",
                    placeholder: "40",
                    text: $form.capacityLiters,
                    keyboard: .decimalPad
                )

                outlinedField(
                    label: "Notes",
                    placeholder: "Describe special attachments or payloads",
                    text: $form.notes,
                    axis: .vertical
                )
            }
        }
    }

    private var locationSection: some View {
        sectionCard {
            sectionHeader(title: "Operating Location")

            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    outlinedField(
                        label: "Latitude",
                        placeholder: "25.6150",
                        text: $form.latitude,
                        keyboard: .decimalPad
                    )

                    outlinedField(
                        label: "Longitude",
                        placeholder: "85.1350",
                        text: $form.longitude,
                        keyboard: .decimalPad
                    )
                }

                outlinedField(
                    label: "Address or Landmark",
                    placeholder: "Village, block, district",
                    text: $form.address,
                    axis: .vertical
                )

                Button {
                    fillCurrentLocation()
                } label: {
                    Label("Use current location", systemImage:
"location.fill")
                        .font(AppTheme.font(13, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                }
            }
        }
    }

    private var publishButton: some View {
        Button {
            Task { await save() }
        } label: {
            HStack(spacing: 12) {
                if isSubmitting { ProgressView().tint(AppTheme.textPrimary) }
                Text(isSubmitting ? "Publishing…" : "Publish Drone")
                    .font(AppTheme.font(17, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isValid ? AppTheme.accent :
AppTheme.surface.opacity(0.35))
            .foregroundStyle(isValid ? AppTheme.textInverted :
AppTheme.subtle)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius,
style: .continuous))
            .shadow(color: AppTheme.accent.opacity(isValid ? 0.35 : 0),
radius: 18, x: 0, y: 12)
        }
        .disabled(!isValid || isSubmitting)
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, subtitle: String? = nil) -> some
View {
        VStack(alignment: .leading, spacing: subtitle == nil ? 0 : 6) {
            Text(title)
                .font(AppTheme.font(20, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(AppTheme.font(13))
                    .foregroundStyle(AppTheme.subtle)
            }
        }
    }

    private func sectionCard<Content: View>(@ViewBuilder content: () ->
Content) -> some View {
        VStack(alignment: .leading, spacing: 16, content: content)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.surface.opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius,
style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius,
style: .continuous)
                    .stroke(AppTheme.stroke)
            )
    }

    private func outlinedField(
        label: String,
        placeholder: String,
        text: Binding<String>,
        axis: Axis = .horizontal,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(AppTheme.font(13, weight: .semibold))
                .foregroundStyle(AppTheme.subtle)

            if axis == .horizontal {
                TextField(placeholder, text: text)
                    .textInputAutocapitalization(.never)
                    .keyboardType(keyboard)
                    .padding(12)
                    .background(AppTheme.surface.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius:
AppTheme.cornerRadius, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius:
AppTheme.cornerRadius, style: .continuous).stroke(AppTheme.stroke))
                    .foregroundStyle(AppTheme.textPrimary)
            } else {
                TextEditor(text: text)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 92)
                    .padding(12)
                    .background(AppTheme.surface.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius:
AppTheme.cornerRadius, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius:
AppTheme.cornerRadius, style: .continuous).stroke(AppTheme.stroke))
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
    }

    private func galleryPreview(for item: GalleryItem) -> some View {
        Group {
            switch item.source {
            case .remote(let urlString):
                AsyncImage(url: URL(string: urlString)) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFill()
                    case .failure(_):
                        placeholderImage
                    default:
                        ProgressView().tint(AppTheme.subtle)
                    }
                }
            case .local(let image):
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
        }
        .background(AppTheme.surface.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius,
style: .continuous))
    }

    private var placeholderImage: some View {
        ZStack {
            AppTheme.surface.opacity(0.35)
            Image(systemName: "photo")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppTheme.subtle)
        }
    }

    private func addManualImage() {
        let trimmed =
manualImageURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, remainingSlots > 0 else { return }
        withAnimation(.easeInOut) {
            galleryItems.append(GalleryItem(source: .remote(trimmed)))
            manualImageURL = ""
        }
    }

    private func handlePicker(items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        var newItems: [GalleryItem] = []
        for item in items.prefix(remainingSlots) {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                newItems.append(GalleryItem(source: .local(image)))
            }
        }
        await MainActor.run {
            galleryItems.append(contentsOf: newItems)
            pickerItems.removeAll()
        }
    }

    private func fillCurrentLocation() {
        guard let location = locationManager.resolvedLocation else { return }
        form.latitude = String(format: "%.5f", location.coordinate.latitude)
        form.longitude = String(format: "%.5f", location.coordinate.longitude)
    }

    private func save() async {
        guard isValid else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            var uploaded: [String] = []
            for item in galleryItems.prefix(maxGalleryCount) {
                switch item.source {
                case .remote(let url):
                    uploaded.append(url)
                case .local(let image):
                    if let data = image.jpegData(compressionQuality: 0.85) {
                        let url = try await uploadService.upload(
                            data: data,
                            filename: "drone-\(UUID().uuidString).jpg"
                        )
                        uploaded.append(url)
                    }
                }
            }

            let price = Double(form.pricePerHour) ?? 0
            let lat = Double(form.latitude) ?? 0
            let lon = Double(form.longitude) ?? 0
            let battery = Double(form.batteryMah)
            let capacity = Double(form.capacityLiters)

            _ = try await appState.createDrone(
                name: form.name,
                type: form.kind.rawValue,
                price: price,
                lat: lat,
                lon: lon,
                imageUrls: uploaded.isEmpty ? nil : uploaded,
                batteryMah: battery,
                capacityLiters: capacity
            )
            dismiss()
        } catch {
            appState.errorMessage = error.localizedDescription
        }
    }
}

private struct DroneForm {
    var name = ""
    var kind: DroneKind = .spray
    var pricePerHour = ""
    var batteryMah = ""
    var capacityLiters = ""
    var latitude = ""
    var longitude = ""
    var address = ""
    var notes = ""
}

private enum DroneKind: String, CaseIterable, Identifiable {
    case spray = "Spray"
    case survey = "Survey"
    case mapping = "Mapping"
    case surveillance = "Surveillance"

    var id: String { rawValue }
    var title: String { rawValue }
}

private struct GalleryItem: Identifiable {
    let id = UUID()
    let source: Source

    enum Source {
        case remote(String)
        case local(UIImage)
    }
}

#Preview {
    NavigationStack {
        AddDroneView()
            .environmentObject(AppState())
    }
}

