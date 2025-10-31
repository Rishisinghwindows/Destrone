import Foundation

struct APIClient {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func send<T: Decodable>(
        _ method: String,
        path: String,
        token: String? = nil,
        queryItems: [URLQueryItem] = [],
        body: Encodable? = nil
    ) async throws -> T {
        var components = URLComponents(url: Constants.baseURL, resolvingAgainstBaseURL: false)
        components?.path = path
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            request.httpBody = try JSONEncoder.apiEncoder.encode(AnyEncodable(body))
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.unknown(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.httpError(-1, nil)
        }

        guard 200..<300 ~= http.statusCode else {
            throw APIError.httpError(http.statusCode, data)
        }

        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }

        do {
            return try JSONDecoder.apiDecoder.decode(T.self, from: data)
        } catch {
            if let raw = String(data: data, encoding: .utf8) {
                print("Decoding error for path \(path):", raw)
            }
            throw APIError.decodingError
        }
    }
}

private struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init(_ value: Encodable) {
        encodeClosure = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}

struct EmptyResponse: Decodable {}

extension JSONEncoder {
    static var apiEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var apiDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: value) {
                return date
            }

            let fallback = DateFormatter()
            fallback.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            fallback.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = fallback.date(from: value) {
                return date
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(value)")
        }
        return decoder
    }
}
