import Foundation
import CoreLocation

struct Drone: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let type: String
    let lat: Double
    let lon: Double
    let status: String
    let pricePerHour: Double
    let ownerId: Int
    let imageUrl: String?
    let imageUrls: [String]?
    let batteryMah: Double?
    let capacityLiters: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case lat
        case lon
        case status
        case pricePerHour = "price_per_hr"
        case ownerId = "owner_id"
        case imageUrl = "image_url"
        case imageUrls = "image_urls"
        case batteryMah = "battery_mah"
        case capacityLiters = "capacity_liters"
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var primaryImageURL: String? {
        guard let rawValue = imageUrls?.first ?? imageUrl else { return nil }
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)

        if let absolute = URL(string: trimmed), absolute.scheme != nil {
            return absolute.absoluteString
        }

        guard var components = URLComponents(url: Constants.baseURL, resolvingAgainstBaseURL: false) else {
            return nil
        }
        let normalizedPath = trimmed.hasPrefix("/") ? trimmed : "/\(trimmed)"
        components.path = normalizedPath
        return components.url?.absoluteString
    }
}
