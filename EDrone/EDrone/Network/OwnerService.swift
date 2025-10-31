import Foundation

struct OwnerService {
    private let client: APIClient

    init(client: APIClient = APIClient()) {
        self.client = client
    }

    func fetchOwners(token: String) async throws -> [Owner] {
        try await client.send("GET", path: "/owners/", token: token)
    }
}
