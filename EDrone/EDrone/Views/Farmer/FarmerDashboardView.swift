import SwiftUI
import MapKit
import CoreLocation
import Combine
import UIKit

struct FarmerDashboardView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var locationManager = LocationManager.shared

    @State private var filterOptions = FarmerFilterOptions()
    @State private var selectedDrone: Drone?
    @State private var quickFilter: QuickFilter = .all
    @State private var startDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()
    @State private var activePanel: ActivePanel?

    private enum ActivePanel: String, Identifiable {
        case filters
        case dates

        var id: String { rawValue }
    }

    private enum QuickFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case nearby = "Nearby"
        case budget = "Budget"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .all: return "globe"
            case .nearby: return "location"
            case .budget: return "indianrupeesign"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                AppTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    headerSection
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                        .background(AppTheme.background)

                    Divider()
                        .overlay(AppTheme.stroke)

                    ScrollView {
                        droneList
                            .padding(.horizontal, 20)
                            .padding(.bottom, 32)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .refreshable {
                await refreshDrones()
            }
            .sheet(item: $selectedDrone) { drone in
                DroneDetailView(drone: drone)
                    .environmentObject(appState)
            }
            .sheet(item: $activePanel) { panel in
                switch panel {
                case .filters:
                    FarmerFilterSheet(
                        options: $filterOptions,
                        startDate: $startDate,
                        endDate: $endDate,
                        onApply: {
                            quickFilter = .all
                            activePanel = nil
                            Task { await refreshDrones() }
                        },
                        onClear: {
                            filterOptions = .default
                            quickFilter = .all
                            activePanel = nil
                            Task { await refreshDrones() }
                        }
                    )
                case .dates:
                    NavigationStack {
                        Form {
                            Section("Booking window") {
                                DatePicker(
                                    "Start",
                                    selection: $startDate,
                                    displayedComponents: .date
                                )
                                DatePicker(
                                    "End",
                                    selection: $endDate,
                                    in: startDate...,
                                    displayedComponents: .date
                                )
                            }
                        }
                        .navigationTitle("Select Dates")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") { activePanel = nil }
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    normalizeDateRange()
                                    activePanel = nil
                                }
                            }
                        }
                    }
                }
            }
            .task {
                await initialLoad()
            }
            .onChange(of: startDate) { _ in
                normalizeDateRange()
            }
            .onReceive(locationManager.$lastLocation.compactMap { $0 }) { _ in
                if filterOptions.sort == .distance {
                    Task { await refreshDrones() }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            welcomeHeader
            VStack(alignment: .leading, spacing: 10) {
                dateSelector
                quickFilterRow
            }
        }
    }

    private var welcomeHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "person.crop.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 58, height: 58)
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 6) {
                Text("Welcome, \(displayName)")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                    Text(locationSubtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.subtle)
                }
            }

                Spacer()

                NavigationLink {
                BookingsView()
            } label: {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(AppTheme.surface)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "bell.fill")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)
                        )

                    if pendingBookingsCount > 0 {
                        Text("\(pendingBookingsCount)")
                            .font(.caption2.bold())
                            .padding(6)
                            .background(AppTheme.accent)
                            .clipShape(Circle())
                            .foregroundStyle(.black)
                            .offset(x: 10, y: -10)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var dateSelector: some View {
        Button {
            activePanel = .dates
        } label: {
            HStack {
                Image(systemName: "calendar")
                Text(dateRangeLabel)
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
            }
            .padding()
            .background(AppTheme.surface)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        }
        .buttonStyle(.plain)
    }

    private var quickFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(QuickFilter.allCases) { filter in
                    Button {
                        applyQuickFilter(filter)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: filter.icon)
                            Text(filter.rawValue)
                                .fontWeight(.semibold)
                        }
                        .font(.footnote)
                        .frame(height: 44)
                        .padding(.horizontal, 20)
                        .background(filter == quickFilter
                                    ? AppTheme.accent
                                    : AppTheme.surface)
                        .foregroundStyle(filter == quickFilter ? .black : .white)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                .stroke(AppTheme.accent, lineWidth: filter == quickFilter ? 0 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    activePanel = .filters
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.footnote.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .background(AppTheme.surface)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                .stroke(AppTheme.stroke)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 44)
    }

    private var droneList: some View {
        VStack(alignment: .leading, spacing: 18) {
            let drones = displayedDrones
            if drones.isEmpty {
                if appState.isLoading {
                    ProgressView("Fetching drones...")
                        .tint(AppTheme.accent)
                        .padding(.top, 40)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "airplane.circle")
                            .font(.system(size: 48))
                            .foregroundStyle(AppTheme.subtle)
                        Text("No drones match your filters")
                            .font(AppTheme.font(18, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("Try broadening the distance or price range to discover more fleets nearby.")
                            .font(AppTheme.font(14))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(AppTheme.subtle)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 0)
                }
            } else {
                LazyVStack(spacing: 20) {
                    ForEach(drones) { drone in
                        Button {
                            selectedDrone = drone
                        } label: {
                            DroneCardView(
                                drone: drone,
                                userCoordinate: locationManager.resolvedLocation?.coordinate
                            )
                }
                .buttonStyle(.plain)
            }
        }
    }
        }
    }

    @MainActor
    private func initialLoad() async {
        await refreshDrones()
        await loadBookingsForBadge()
        LocationManager.shared.requestAccess()
    }

    @MainActor
    private func refreshDrones() async {
        do {
            let filter = buildFilter()
            appState.droneFilter = filter
            try await appState.loadDrones(filter: filter)
        } catch {
            appState.errorMessage = error.localizedDescription
        }
    }

    private func applyQuickFilter(_ filter: QuickFilter) {
        quickFilter = filter
        var updated = FarmerFilterOptions.default
        switch filter {
        case .all:
            break
        case .nearby:
            updated.sort = .distance
            updated.maxDistance = 15
        case .budget:
            updated.sort = .priceLowHigh
            updated.maxPrice = 600
        }
        filterOptions = updated
        Task { await refreshDrones() }
    }

    private func buildFilter() -> DroneFilter {
        var filter = DroneFilter()
        if let coordinate = locationManager.resolvedLocation?.coordinate {
            let lat = coordinate.latitude
            let lon = coordinate.longitude
            filter.lat = lat
            filter.lon = lon
        }
        if let min = filterOptions.minPrice { filter.minPrice = min }
        if let max = filterOptions.maxPrice { filter.maxPrice = max }
        if filterOptions.maxDistance < FarmerFilterOptions.Constants.maxDistance {
            filter.maxDistance = filterOptions.maxDistance
        }
        filter.sortBy = filterOptions.sort.apiKey
        return filter
    }

    private var locationSubtitle: String {
        if let description = locationManager.locationDescription, !description.isEmpty {
            return description
        }
        if let coordinate = locationManager.resolvedLocation?.coordinate {
            return String(format: "Lat %.2f, Lon %.2f", coordinate.latitude, coordinate.longitude)
        }
        return "Locating..."
    }

    private var displayName: String {
        if let name = appState.profileName, !name.isEmpty {
            return name
        }
        if let mobile = appState.mobile, !mobile.isEmpty {
            return "Farmer \(mobile.suffix(4))"
        }
        return "Farmer"
    }

    private var dateRangeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let startText = formatter.string(from: startDate)
        let endFormatter = DateFormatter()
        endFormatter.dateFormat = "MMM d"
        let endText = endFormatter.string(from: endDate)
        return "\(startText) - \(endText)"
    }

    private var displayedDrones: [Drone] {
        var drones = appState.drones

        if filterOptions.availability != .any {
            drones = drones.filter { filterOptions.availability.matches($0.status) }
        }

        if !filterOptions.selectedCategories.isEmpty {
            let allowed = Set(filterOptions.selectedCategories.map { $0.rawValue.lowercased() })
            drones = drones.filter { allowed.contains($0.type.lowercased()) }
        }

        if let min = filterOptions.minPrice {
            drones = drones.filter { $0.pricePerHour >= min }
        }
        if let max = filterOptions.maxPrice {
            drones = drones.filter { $0.pricePerHour <= max }
        }

        if filterOptions.maxDistance < FarmerFilterOptions.Constants.maxDistance,
           let coordinate = locationManager.resolvedLocation?.coordinate {
            drones = drones.filter {
                distance(from: coordinate, to: $0) <= filterOptions.maxDistance * 1000
            }
        }

        switch filterOptions.sort {
        case .priceLowHigh:
            drones = drones.sorted { $0.pricePerHour < $1.pricePerHour }
        case .priceHighLow:
            drones = drones.sorted { $0.pricePerHour > $1.pricePerHour }
        case .distance:
            if let coordinate = locationManager.resolvedLocation?.coordinate {
                drones = drones.sorted {
                    distance(from: coordinate, to: $0) < distance(from: coordinate, to: $1)
                }
            }
        }

        return drones
    }

    private var pendingBookingsCount: Int {
        appState.bookings.filter { $0.status.lowercased() == "pending" }.count
    }

    private func normalizeDateRange() {
        if endDate < startDate {
            endDate = startDate
        }
    }

    private func loadBookingsForBadge() async {
        do {
            try await appState.loadBookings()
        } catch {
            // Ignore badge errors; surface elsewhere if needed
        }
    }

    private func distance(from coordinate: CLLocationCoordinate2D, to drone: Drone) -> Double {
        let userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let droneLocation = CLLocation(latitude: drone.lat, longitude: drone.lon)
        return userLocation.distance(from: droneLocation)
    }
}

private struct DroneCardView: View {
    let drone: Drone
    let userCoordinate: CLLocationCoordinate2D?

    private static let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "en_IN")
        return formatter
    }()

    var body: some View {
        let cornerRadius: CGFloat = AppTheme.cornerRadius

        VStack(spacing: 0) {
            AsyncImage(url: imageURL, transaction: Transaction(animation: .easeInOut)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    fallbackImage
                case .empty:
                    placeholderGradient
                @unknown default:
                    placeholderGradient
                }
            }
            .frame(height: 200)
            .clipShape(RoundedCorners(radius: cornerRadius, corners: [.topLeft, .topRight]))
            .overlay(
                RoundedCorners(radius: cornerRadius, corners: [.topLeft, .topRight])
                    .stroke(Color.white.opacity(0.08))
            )
            .clipped()

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center) {
                    Text(drone.type.uppercased())
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.subtle)
                    Spacer()
                    if let distance = distanceLabel {
                        Label(distance, systemImage: "mappin.and.ellipse")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(AppTheme.subtle)
                            .labelStyle(.titleAndIcon)
                            .symbolRenderingMode(.hierarchical)
                    }
                }

                Text(drone.name)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    specLabel(icon: "bolt.fill", value: batteryLabel)
                    Spacer()
                    specLabel(icon: "drop.fill", value: capacityLabel)
                }

                Divider()
                    .overlay(AppTheme.stroke)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(priceLabel)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("/ hour")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.subtle)
                    Spacer()
                    ctaLabel
                }

                Text(statusText)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(statusColor)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.elevatedSurface, AppTheme.surface],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                .stroke(AppTheme.stroke)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 10)
    }

    private var distanceLabel: String? {
        guard let coordinate = userCoordinate else { return nil }
        let userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let droneLocation = CLLocation(latitude: drone.lat, longitude: drone.lon)
        let distanceMeters = userLocation.distance(from: droneLocation)
        let distanceKm = distanceMeters / 1000
        if distanceKm < 0.2 {
            return "Nearby"
        }
        return String(format: "%.1f km away", distanceKm)
    }

    private var imageURL: URL? {
        guard let urlString = drone.primaryImageURL else { return nil }
        return URL(string: urlString)
    }

    private var priceLabel: String {
        let number = NSNumber(value: drone.pricePerHour)
        let formatted = Self.priceFormatter.string(from: number) ?? String(format: "%.0f", drone.pricePerHour)
        return "₹" + formatted
    }

    private var ctaLabel: some View {
        let available = drone.status.lowercased() == "available"
        let background = available ? AppTheme.accent : AppTheme.surface.opacity(0.4)
        let foreground = available ? Color.black : AppTheme.subtle
        return Text(available ? "Book Now" : "Unavailable")
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(background, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
            .foregroundStyle(foreground)
    }

    private var statusText: String {
        drone.status
    }

    private var statusColor: Color {
        drone.status.lowercased() == "available" ? AppTheme.accent : Color.orange
    }

    private var batteryLabel: String {
        if let capacity = drone.batteryMah {
            return String(format: "%,.0f mAh", capacity)
        }

        let normalized = drone.name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        if normalized.contains("agri-bot x4") || normalized.contains("agribot x4") {
            return "9,500 mAh"
        }
        if normalized.contains("fieldmapper pro") {
            return "7,000 mAh"
        }
        if normalized.contains("seedstorm x1") {
            return "12,000 mAh"
        }

        let base = 6500 + (drone.id % 6) * 500
        return String(format: "%,d mAh", base)
    }

    private var capacityLabel: String {
        if let litres = drone.capacityLiters {
            return String(format: "%.0f L", litres)
        }

        let normalized = drone.name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        if normalized.contains("agri-bot x4") || normalized.contains("agribot x4") {
            return "40 L"
        }
        if normalized.contains("fieldmapper pro") {
            return "20 L"
        }
        if normalized.contains("seedstorm x1") {
            return "50 L"
        }

        let litres = 15 + (drone.id % 4) * 5
        return "\(litres) L"
    }

    private var placeholderGradient: some View {
        LinearGradient(
            colors: [AppTheme.accent.opacity(0.5), AppTheme.accentMuted.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @ViewBuilder
    private var fallbackImage: some View {
        if let fallbackURL = URL(string: drone.fallbackImageURL()) {
            AsyncImage(url: fallbackURL, transaction: Transaction(animation: .easeInOut)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    placeholderGradient
                }
            }
        } else {
            placeholderGradient
        }
    }

    private func specLabel(icon: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(value)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(AppTheme.subtle)
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
    ContentView()
        .environmentObject(AppState())
}
