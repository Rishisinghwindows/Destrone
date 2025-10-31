import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case decodingError
    case httpError(Int, Data?)
    case unknown(Error)
    case missingToken

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .decodingError:
            return "Failed to decode response"
        case .httpError(let code, _):
            return "Server returned status code \(code)"
        case .unknown(let error):
            return error.localizedDescription
        case .missingToken:
            return "Authentication required"
        }
    }
}
