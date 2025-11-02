import SwiftUI

struct FarmerFilterOptions: Equatable {
    enum SortOption: String, CaseIterable, Identifiable {
        case distance
        case priceLowHigh
        case priceHighLow

        var id: String { rawValue }

        var label: String {
            switch self {
            case .distance: return "Distance"
            case .priceLowHigh: return "Price: Low to High"
            case .priceHighLow: return "Price: High to Low"
            }
        }

        var apiKey: String {
            switch self {
            case .distance: return "distance"
            case .priceLowHigh, .priceHighLow: return "price"
            }
        }
    }

    enum Availability: String, CaseIterable, Identifiable {
        case any
        case available
        case rented

        var id: String { rawValue }

        var label: String {
            switch self {
            case .any: return "Any Status"
            case .available: return "Available"
            case .rented: return "Rented"
            }
        }

        func matches(_ status: String) -> Bool {
            let normalized = status.lowercased()
            switch self {
            case .any:
                return true
            case .available:
                return normalized == "available"
            case .rented:
                return normalized == "rented" || normalized == "booked"
            }
        }
    }

    enum DroneCategory: String, CaseIterable, Identifiable {
        case spray = "Spray"
        case survey = "Survey"
        case mapping = "Mapping"
        case surveillance = "Surveillance"

        var id: String { rawValue }
        var label: String { rawValue }
    }

    struct Constants {
        static let maxDistance: Double = 100
    }

    var sort: SortOption = .distance
    var maxDistance: Double = Constants.maxDistance
    var minPrice: Double? = nil
    var maxPrice: Double? = nil
    var availability: Availability = .any
    var selectedCategories: Set<DroneCategory> = []

    static let `default` = FarmerFilterOptions()
}

struct FarmerFilterSheet: View {
    @Binding var options: FarmerFilterOptions
    @Binding var startDate: Date
    @Binding var endDate: Date

    let onApply: () -> Void
    let onClear: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var draft: FarmerFilterOptions
    @State private var minPriceText: String
    @State private var maxPriceText: String
    @State private var draftStartDate: Date
    @State private var draftEndDate: Date

    init(
        options: Binding<FarmerFilterOptions>,
        startDate: Binding<Date>,
        endDate: Binding<Date>,
        onApply: @escaping () -> Void,
        onClear: @escaping () -> Void
    ) {
        _options = options
        _startDate = startDate
        _endDate = endDate
        self.onApply = onApply
        self.onClear = onClear
        let current = options.wrappedValue
        _draft = State(initialValue: current)
        _minPriceText = State(initialValue: FarmerFilterSheet.formatPrice(current.minPrice))
        _maxPriceText = State(initialValue: FarmerFilterSheet.formatPrice(current.maxPrice))
        _draftStartDate = State(initialValue: startDate.wrappedValue)
        _draftEndDate = State(initialValue: endDate.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    ScrollView {
                        VStack(spacing: 24) {
                            sortSection
                            distanceSection
                            priceSection
                            availabilitySection
                            categorySection
                            rentalPeriodSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                    }
                    .scrollIndicators(.hidden)

                    footer
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .padding(.top, 12)
                        .background(AppTheme.background.opacity(0.95))
                }
            }
            .onAppear(perform: syncFromOptions)
        }
        .presentationDetents([.large])
        .preferredColorScheme(.dark)
    }
}

private extension FarmerFilterSheet {
    static func formatPrice(_ value: Double?) -> String {
        guard let value else { return "" }
        return String(format: "%.0f", value)
    }

    func syncFromOptions() {
        draft = options
        minPriceText = Self.formatPrice(options.minPrice)
        maxPriceText = Self.formatPrice(options.maxPrice)
        draftStartDate = startDate
        draftEndDate = endDate
    }

    var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(12)
                    .background(AppTheme.surface.opacity(0.3), in: Circle())
            }

            Spacer()

            Text("Filter & Sort")
                .font(AppTheme.font(20, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            Spacer()

            Spacer().frame(width: 44)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
    }

    var sortSection: some View {
        section(title: "Sort By") {
            HStack(spacing: 12) {
                ForEach(FarmerFilterOptions.SortOption.allCases) { option in
                    filterChip(
                        text: option.label,
                        isSelected: draft.sort == option
                    ) {
                        draft.sort = option
                    }
                }
            }
        }
    }

    var distanceSection: some View {
        section(title: "Distance Range") {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(draft.maxDistance >= FarmerFilterOptions.Constants.maxDistance ? "No limit" : String(format: "Up to %.0f km", draft.maxDistance))
                        .font(AppTheme.font(14, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Button {
                        draft.maxDistance = FarmerFilterOptions.Constants.maxDistance
                    } label: {
                        Text("Reset")
                            .font(AppTheme.font(13, weight: .semibold))
                            .foregroundStyle(AppTheme.subtle)
                    }
                }

                Slider(
                    value: $draft.maxDistance,
                    in: 0...FarmerFilterOptions.Constants.maxDistance,
                    step: 5
                )
                .tint(AppTheme.accent)

                HStack {
                    Text("0 km")
                        .font(AppTheme.font(12))
                        .foregroundStyle(AppTheme.subtle)
                    Spacer()
                    Text(String(format: "%.0f km", FarmerFilterOptions.Constants.maxDistance))
                        .font(AppTheme.font(12))
                        .foregroundStyle(AppTheme.subtle)
                }
            }
        }
    }

    var priceSection: some View {
        section(title: "Price Range", subtitle: "Set your preferred hourly price") {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    priceField(title: "Min", binding: $minPriceText)
                    priceField(title: "Max", binding: $maxPriceText)
                }

                HStack(spacing: 12) {
                    ForEach([6000, 9000, 12000, 15000], id: \.self) { value in
                        quickPriceChip(value: Double(value))
                    }
                }
            }
        }
    }

    var availabilitySection: some View {
        section(title: "Availability") {
            HStack(spacing: 12) {
                ForEach(FarmerFilterOptions.Availability.allCases) { option in
                    filterChip(
                        text: option.label,
                        isSelected: draft.availability == option
                    ) {
                        draft.availability = option
                    }
                }
            }
        }
    }

    var categorySection: some View {
        section(title: "Drone Type") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(FarmerFilterOptions.DroneCategory.allCases) { category in
                    filterChip(
                        text: category.label,
                        isSelected: draft.selectedCategories.contains(category)
                    ) {
                        if draft.selectedCategories.contains(category) {
                            draft.selectedCategories.remove(category)
                        } else {
                            draft.selectedCategories.insert(category)
                        }
                    }
                }
            }
        }
    }

    var rentalPeriodSection: some View {
        section(title: "Rental Period") {
            VStack(alignment: .leading, spacing: 12) {
                DatePicker(
                    "Start Date",
                    selection: $draftStartDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .accentColor(AppTheme.accent)

                DatePicker(
                    "End Date",
                    selection: $draftEndDate,
                    in: draftStartDate...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .accentColor(AppTheme.accent)
            }
        }
    }

    var footer: some View {
        VStack(spacing: 12) {
            Button {
                apply()
            } label: {
                Text("Apply Filters")
                    .font(AppTheme.font(16, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .foregroundStyle(AppTheme.textInverted)
            }

            Button {
                clearAll()
            } label: {
                Text("Clear Filters")
                    .font(AppTheme.font(16, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.surface.opacity(0.45), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
    }

    func section(title: String, subtitle: String? = nil, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(AppTheme.font(18, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(AppTheme.font(13))
                        .foregroundStyle(AppTheme.subtle)
                }
            }

            content()
        }
        .padding(20)
        .background(AppTheme.surface.opacity(0.6), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.stroke)
        )
    }

    func filterChip(text: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(AppTheme.font(13, weight: .semibold))
                .foregroundStyle(isSelected ? AppTheme.textInverted : AppTheme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius * 1.6, style: .continuous)
                        .fill(isSelected ? AppTheme.accent : AppTheme.surface.opacity(0.45))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius * 1.6, style: .continuous)
                        .stroke(isSelected ? AppTheme.accent : AppTheme.stroke)
                )
        }
        .buttonStyle(.plain)
    }

    func priceField(title: String, binding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(AppTheme.font(11, weight: .bold))
                .foregroundStyle(AppTheme.subtle)
            TextField("₹", text: binding)
                .keyboardType(.numberPad)
                .padding(14)
                .background(AppTheme.surface.opacity(0.45), in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                        .stroke(AppTheme.stroke)
                )
        }
    }

    func quickPriceChip(value: Double) -> some View {
        Button {
            minPriceText = ""
            maxPriceText = String(format: "%.0f", value)
        } label: {
            Text("Under ₹\(Int(value))")
                .font(AppTheme.font(12, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(AppTheme.surface.opacity(0.45), in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                        .stroke(AppTheme.stroke)
                )
        }
        .buttonStyle(.plain)
    }

    func apply() {
        let parsedMin = parsePrice(minPriceText)
        let parsedMax = parsePrice(maxPriceText)

        if let min = parsedMin, let max = parsedMax, min > max {
            draft.minPrice = max
            draft.maxPrice = min
        } else {
            draft.minPrice = parsedMin
            draft.maxPrice = parsedMax
        }

        options = draft
        startDate = draftStartDate
        endDate = draftEndDate
        onApply()
        dismiss()
    }

    func clearAll() {
        draft = .default
        minPriceText = ""
        maxPriceText = ""
        draftStartDate = startDate
        draftEndDate = endDate
        options = draft
        onClear()
    }

    func parsePrice(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let sanitized = trimmed.replacingOccurrences(of: ",", with: "")
        return Double(sanitized)
    }
}

#Preview {
    FarmerFilterSheet(
        options: .constant(.init()),
        startDate: .constant(Date()),
        endDate: .constant(Date().addingTimeInterval(86400 * 3)),
        onApply: {},
        onClear: {}
    )
}
