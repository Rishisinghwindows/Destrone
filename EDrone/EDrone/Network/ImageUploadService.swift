import Foundation

struct ImageUploadService {
    private let client: APIClient

    init(client: APIClient = APIClient()) {
        self.client = client
    }

    struct UploadPayload: Encodable {
        let filename: String?
        let extensionValue: String?
        let data: String

        enum CodingKeys: String, CodingKey {
            case filename
            case extensionValue = "extension"
            case data
        }
    }

    struct UploadResponse: Decodable {
        let url: String
    }

    func upload(data: Data, filename: String? = nil) async throws -> String {
        let payload = UploadPayload(
            filename: filename,
            extensionValue: "jpg",
            data: data.base64EncodedString()
        )

        let response: UploadResponse = try await client.send(
            "POST",
            path: "/assets/upload",
            body: payload
        )
        return response.url
    }
}
