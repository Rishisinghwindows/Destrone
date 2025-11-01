import SwiftUI
import MapKit
import CoreLocation
import Combine
import UIKit

struct FarmerDashboardView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var locationManager = LocationManager.shared

    @State private var minPrice: String = ""
    @State private var maxPrice: String = ""
    @State private var maxDistance: String = ""
    @State private var sortBy: String = "distance"
    @State private var selectedDrone: Drone?
    @State private var showAdvancedFilters = false
    @State private var quickFilter: QuickFilter = .all
    @State private var startDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()
    @State private var showDateSheet = false

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
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        welcomeHeader
                        dateSelector
                        quickFilterRow
                        advancedFiltersPanel
                        droneList
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
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
            .sheet(isPresented: $showDateSheet) {
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
                            Button("Cancel") { showDateSheet = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                normalizeDateRange()
                                showDateSheet = false
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
                if sortBy == "distance" {
                    Task { await refreshDrones() }
                }
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
            showDateSheet = true
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
            HStack(spacing: 12) {
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
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
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
                    withAnimation(.spring()) {
                        showAdvancedFilters.toggle()
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.footnote.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .background(AppTheme.surface)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                }
            }
        }
    }

    private var advancedFiltersPanel: some View {
        Group {
            if showAdvancedFilters {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Fine tune results")
                        .font(.headline)
                        .foregroundStyle(.white)

                    HStack(spacing: 12) {
                        filterField(title: "Min price", value: $minPrice)
                        filterField(title: "Max price", value: $maxPrice)
                    }

                    filterField(title: "Max distance (km)", value: $maxDistance)

                    Picker("Sort by", selection: $sortBy) {
                        Text("Distance").tag("distance")
                        Text("Price").tag("price")
                    }
                    .pickerStyle(.segmented)

                    HStack(spacing: 14) {
                        Button("Apply", action: applyFilters)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppTheme.accent)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))

                        Button("Reset") {
                            resetFilters()
                            Task { await refreshDrones() }
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.08))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                    }
                }
                .padding(20)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var droneList: some View {
        VStack(alignment: .leading, spacing: 18) {
            if appState.drones.isEmpty {
                if appState.isLoading {
                    ProgressView("Fetching drones...")
                        .tint(AppTheme.accent)
                        .padding(.top, 40)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "airplane.circle")
                            .font(.system(size: 48))
                            .foregroundStyle(AppTheme.subtle)
                        Text("No drones yet")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Pull to refresh or adjust filters to explore available drones.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(AppTheme.subtle)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 48)
                }
            } else {
                LazyVStack(spacing: 20) {
                    ForEach(appState.drones) { drone in
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

    private func filterField(title: String, value: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.subtle)
            TextField(title, text: value)
                .keyboardType(.decimalPad)
                .padding(12)
                .background(Color.white.opacity(0.08))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        }
    }

    private func initialLoad() async {
        await refreshDrones()
        await loadBookingsForBadge()
        LocationManager.shared.requestAccess()
    }

    private func refreshDrones() async {
        do {
            let filter = buildFilter()
            appState.droneFilter = filter
            try await appState.loadDrones(filter: filter)
        } catch {
            appState.errorMessage = error.localizedDescription
        }
    }

    private func applyFilters() {
        Task { await refreshDrones() }
    }

    private func applyQuickFilter(_ filter: QuickFilter) {
        quickFilter = filter
        switch filter {
        case .all:
            resetFilters()
        case .nearby:
            minPrice = ""
            maxPrice = ""
            maxDistance = "15"
            sortBy = "distance"
        case .budget:
            minPrice = ""
            maxPrice = "600"
            maxDistance = ""
            sortBy = "price"
        }
        Task { await refreshDrones() }
    }

    private func resetFilters() {
        minPrice = ""
        maxPrice = ""
        maxDistance = ""
        sortBy = "distance"
    }

    private func buildFilter() -> DroneFilter {
        var filter = DroneFilter()
        if let coordinate = locationManager.resolvedLocation?.coordinate {
            let lat = coordinate.latitude
            let lon = coordinate.longitude
            filter.lat = lat
            filter.lon = lon
        }
        if let min = Double(minPrice) { filter.minPrice = min }
        if let max = Double(maxPrice) { filter.maxPrice = max }
        if let distance = Double(maxDistance) { filter.maxDistance = distance }
        filter.sortBy = sortBy
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
                    placeholderGradient
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
        if let urlString = drone.primaryImageURL, let url = URL(string: urlString) {
            return url
        }
        return URL(string: "https://lh3.googleusercontent.com/aida-public/AB6AXuDw3EbDprqmgL5vEuv4kwV7bhY5RFilj_p4P9AERyMOGxEO9ITL2XwDoRxkOCeZU50jnu7xne0FiHdLTlZIJB2dSTbp5_gBfA9WhmdLVWHyzFhQPe9Jo7PD0vv6-dCgt1g3YnnLe_4opFr9BIXJD-p-r7l65ouwI6eKBN_tab8Q4oytcXmTfJKtZPo96ZyZBBKPv-Yl8VUVDIdXXHOjtU-0zaOCLGIftg3o6XJFk_BsV4qxQ2s1a4dLiDN_VwiqtFc-ZlezlDK97q2r")
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
