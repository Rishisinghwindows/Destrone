import Foundation

struct BookingService {
    private let client: APIClient

    init(client: APIClient = APIClient()) {
        self.client = client
    }

    struct CreatePayload: Encodable {
        let droneId: Int
        let farmerName: String
        let durationHours: Int

        enum CodingKeys: String, CodingKey {
            case droneId = "drone_id"
            case farmerName = "farmer_name"
            case durationHours = "duration_hrs"
        }
    }

    struct UpdatePayload: Encodable {
        let status: String
    }

    func fetchBookings(token: String, status: String? = nil) async throws -> [Booking] {
        var query: [URLQueryItem] = []
        if let status = status {
            query.append(URLQueryItem(name: "status", value: status))
        }
        return try await client.send(
            "GET",
            path: "/bookings/",
            token: token,
            queryItems: query
        )
    }

    func createBooking(token: String, payload: CreatePayload) async throws -> Booking {
        try await client.send(
            "POST",
            path: "/bookings/",
            token: token,
            body: payload
        )
    }

    func updateBooking(token: String, bookingId: Int, status: String) async throws -> [String: String] {
        try await client.send(
            "PATCH",
            path: "/bookings/\(bookingId)/",
            token: token,
            body: UpdatePayload(status: status)
        )
    }
}
