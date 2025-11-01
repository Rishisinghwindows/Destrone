import Foundation
import Combine

enum UserRole: String, CaseIterable, Identifiable {
    case farmer
    case owner

    var id: String { rawValue }

    var label: String {
        switch self {
        case .farmer:
            return "Farmer"
        case .owner:
            return "Owner"
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var token: String?
    @Published var mobile: String?
    @Published var profileName: String?
    @Published var selectedRole: UserRole?
    @Published var drones: [Drone] = []
    @Published var bookings: [Booking] = []
    @Published var owners: [Owner] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var droneFilter = DroneFilter()
    @Published var availableRoles: [UserRole] = []
    @Published var ownerDrones: [Drone] = []

    let authService: AuthService
    let droneService: DroneService
    let bookingService: BookingService
    let ownerService: OwnerService

    init(
        authService: AuthService = AuthService(),
        droneService: DroneService = DroneService(),
        bookingService: BookingService = BookingService(),
        ownerService: OwnerService = OwnerService()
    ) {
        self.authService = authService
        self.droneService = droneService
        self.bookingService = bookingService
        self.ownerService = ownerService

        token = TokenManager.shared.token
        mobile = TokenManager.shared.mobile
        profileName = TokenManager.shared.profileName
        availableRoles = TokenManager.shared.availableRoles
        selectedRole = TokenManager.shared.selectedRole
        if availableRoles.isEmpty, let role = selectedRole {
            availableRoles = [role]
        }
        if selectedRole == nil, let first = availableRoles.first {
            selectedRole = first
        }
    }

    func updateToken(
        _ token: String?,
        mobile: String?,
        activeRole: UserRole?,
        roles: [UserRole],
        profileName: String? = nil
    ) {
        self.token = token
        self.mobile = mobile
        TokenManager.shared.token = token
        TokenManager.shared.mobile = mobile
        if let profileName {
            self.profileName = profileName
            TokenManager.shared.profileName = profileName
        } else if token == nil {
            self.profileName = nil
            TokenManager.shared.profileName = nil
        }

        let normalizedRoles = roles.isEmpty ? (activeRole.flatMap { [$0] } ?? []) : roles
        availableRoles = normalizedRoles
        TokenManager.shared.availableRoles = normalizedRoles

        if let stored = TokenManager.shared.selectedRole, normalizedRoles.contains(stored) {
            switchRole(stored)
        } else if let activeRole, normalizedRoles.contains(activeRole) {
            switchRole(activeRole)
        } else if normalizedRoles.count == 1, let first = normalizedRoles.first {
            switchRole(first)
        } else {
            switchRole(nil)
        }
    }

    func switchRole(_ role: UserRole?) {
        if let role, !availableRoles.isEmpty, !availableRoles.contains(role) {
            return
        }
        selectedRole = role
        TokenManager.shared.selectedRole = role
    }

    func signOut() {
        updateToken(nil, mobile: nil, activeRole: nil, roles: [])
        switchRole(nil)
        drones = []
        ownerDrones = []
        bookings = []
        owners = []
        availableRoles = []
    }

    func refreshData() async {
        await withLoading {
            if selectedRole == .owner {
                try await loadOwnerDrones()
                try await loadOwners()
                try await loadBookings()
            } else if selectedRole == .farmer {
                try await loadDrones()
                try await loadBookings()
            } else {
                drones = []
                ownerDrones = []
            }
        }
    }

    func loadDrones(filter: DroneFilter? = nil) async throws {
        let effectiveFilter = filter ?? droneFilter
        let items = try await droneService.fetchDrones(filter: effectiveFilter)
        drones = items
    }

    func loadOwners() async throws {
        guard let token else { return }
        owners = try await ownerService.fetchOwners(token: token)
    }

    func loadOwnerDrones() async throws {
        guard let token else { return }
        ownerDrones = try await droneService.fetchOwnerDrones(token: token)
    }

    func loadBookings(status: String? = nil) async throws {
        guard let token else { return }
        bookings = try await bookingService.fetchBookings(token: token, status: status)
    }

    func createBooking(droneId: Int, farmerName: String, duration: Int) async throws -> Booking {
        guard let token else { throw APIError.missingToken }
        guard selectedRole == .farmer else { throw APIError.httpError(403, nil) }
        let booking = try await bookingService.createBooking(
            token: token,
            payload: BookingService.CreatePayload(droneId: droneId, farmerName: farmerName, durationHours: duration)
        )
        try await loadBookings()
        return booking
    }

    func createDrone(
        name: String,
        type: String,
        price: Double,
        lat: Double,
        lon: Double,
        imageUrls: [String]? = nil,
        batteryMah: Double? = nil,
        capacityLiters: Double? = nil
    ) async throws -> Drone {
        guard let token else { throw APIError.missingToken }
        guard selectedRole == .owner else { throw APIError.httpError(403, nil) }
        let payload = DroneService.CreatePayload(
            name: name,
            type: type,
            lat: lat,
            lon: lon,
            pricePerHour: price,
            imageUrl: imageUrls?.first,
            imageUrls: imageUrls,
            batteryMah: batteryMah,
            capacityLiters: capacityLiters
        )
        let drone = try await droneService.createDrone(token: token, payload: payload)
        try await loadOwnerDrones()
        return drone
    }

    func updateAvailability(drone: Drone, status: String) async throws {
        guard let token else { throw APIError.missingToken }
        guard selectedRole == .owner else { throw APIError.httpError(403, nil) }
        try await droneService.updateAvailability(token: token, droneId: drone.id, status: status)
        try await loadOwnerDrones()
    }

    func updateBookingStatus(_ booking: Booking, status: String) async throws {
        guard let token else { throw APIError.missingToken }
        guard selectedRole == .owner else { throw APIError.httpError(403, nil) }
        _ = try await bookingService.updateBooking(token: token, bookingId: booking.id, status: status)
        try await loadBookings()
    }

    private func withLoading(_ task: () async throws -> Void) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await task()
            errorMessage = nil
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
