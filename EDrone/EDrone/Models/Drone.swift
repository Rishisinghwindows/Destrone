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
        let candidates = (imageUrls ?? []) + [imageUrl].compactMap { $0 }
        for raw in candidates {
            if let normalized = normalizeImagePath(raw) {
                return normalized
            }
        }
        return nil
    }

    var galleryImageURLs: [String] {
        let candidates = imageUrls ?? []
        let normalized = candidates.compactMap { normalizeImagePath($0) }
        if normalized.isEmpty, let fallback = normalizeImagePath(imageUrl ?? "") {
            return [fallback]
        }
        return normalized
    }

    static let placeholderImages: [String] = [
        "https://images.unsplash.com/photo-1504198458649-3128b932f49b?auto=format&fit=crop&w=1200&q=80",
        "https://images.unsplash.com/photo-1508612761958-e931b366d5c9?auto=format&fit=crop&w=1200&q=80",
        "https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=1200&q=80",
        "https://images.unsplash.com/photo-1489515217757-5fd1be406fef?auto=format&fit=crop&w=1200&q=80",
        "https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=1200&q=80"
    ]

    func fallbackImageURL() -> String {
        guard !Self.placeholderImages.isEmpty else {
            return "https://images.unsplash.com/photo-1520453803296-c39eabe2dab4?auto=format&fit=crop&w=1200&q=80"
        }
        let index = abs(id.hashValue) % Self.placeholderImages.count
        return Self.placeholderImages[index]
    }

    private func normalizeImagePath(_ rawValue: String) -> String? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

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
