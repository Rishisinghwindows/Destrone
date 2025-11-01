import Foundation

struct DroneFilter {
    var lat: Double?
    var lon: Double?
    var maxDistance: Double?
    var minPrice: Double?
    var maxPrice: Double?
    var sortBy: String?

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let lat = lat { items.append(URLQueryItem(name: "lat", value: String(lat))) }
        if let lon = lon { items.append(URLQueryItem(name: "lon", value: String(lon))) }
        if let maxDistance = maxDistance { items.append(URLQueryItem(name: "max_dist_km", value: String(maxDistance))) }
        if let minPrice = minPrice { items.append(URLQueryItem(name: "min_price", value: String(minPrice))) }
        if let maxPrice = maxPrice { items.append(URLQueryItem(name: "max_price", value: String(maxPrice))) }
        if let sortBy = sortBy { items.append(URLQueryItem(name: "sort_by", value: sortBy)) }
        return items
    }
}

struct DroneService {
    private let client: APIClient

    init(client: APIClient = APIClient()) {
        self.client = client
    }

    struct CreatePayload: Encodable {
        let name: String
        let type: String
        let lat: Double
        let lon: Double
        let pricePerHour: Double
        let imageUrl: String?
        let imageUrls: [String]?
        let batteryMah: Double?
        let capacityLiters: Double?

        enum CodingKeys: String, CodingKey {
            case name
            case type
            case lat
            case lon
            case pricePerHour = "price_per_hr"
            case imageUrl = "image_url"
            case imageUrls = "image_urls"
            case batteryMah = "battery_mah"
            case capacityLiters = "capacity_liters"
        }
    }

    struct AvailabilityPayload: Encodable {
        let status: String
    }

    func fetchDrones(filter: DroneFilter = DroneFilter()) async throws -> [Drone] {
        try await client.send("GET", path: "/drones/", queryItems: filter.queryItems)
    }

    func fetchOwnerDrones(token: String) async throws -> [Drone] {
        try await client.send(
            "GET",
            path: "/owners/me/drones",
            token: token
        )
    }

    func createDrone(token: String, payload: CreatePayload) async throws -> Drone {
        try await client.send(
            "POST",
            path: "/drones/",
            token: token,
            body: payload
        )
    }

    func updateAvailability(token: String, droneId: Int, status: String) async throws {
        _ = try await client.send(
            "PATCH",
            path: "/drones/\(droneId)/availability/",
            token: token,
            body: AvailabilityPayload(status: status)
        ) as EmptyResponse
    }
}
