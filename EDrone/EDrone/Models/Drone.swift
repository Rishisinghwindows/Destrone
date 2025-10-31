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
        case batteryMah = "battery_mah"
        case capacityLiters = "capacity_liters"
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}
