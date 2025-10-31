import Foundation

struct Booking: Codable, Identifiable, Hashable {
    let id: Int
    let droneId: Int
    let farmerName: String
    let farmerMobile: String?
    let bookingDate: Date
    let durationHours: Int
    let status: String

    enum CodingKeys: String, CodingKey {
        case id
        case droneId = "drone_id"
        case farmerName = "farmer_name"
        case farmerMobile = "farmer_mobile"
        case bookingDate = "booking_date"
        case durationHours = "duration_hrs"
        case status
    }
}
