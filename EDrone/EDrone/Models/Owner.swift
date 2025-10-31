import Foundation

struct Owner: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let mobile: String
    let lat: Double?
    let lon: Double?
}
