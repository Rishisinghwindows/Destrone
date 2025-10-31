import Foundation

struct AuthService {
    private let client: APIClient

    init(client: APIClient = APIClient()) {
        self.client = client
    }

    struct OTPRequestPayload: Encodable {
        let mobile: String
    }

    struct OTPVerifyPayload: Encodable {
        let mobile: String
        let otp: String
        let role: String
        let name: String?
        let lat: Double?
        let lon: Double?
    }

    func requestOTP(mobile: String) async throws -> OTPRequestResponse {
        try await client.send(
            "POST",
            path: "/auth/request_otp",
            body: OTPRequestPayload(mobile: mobile)
        )
    }

    func verifyOTP(
        mobile: String,
        otp: String,
        role: UserRole,
        name: String?,
        lat: Double?,
        lon: Double?
    ) async throws -> AuthResponse {
        try await client.send(
            "POST",
            path: "/auth/verify_otp",
            body: OTPVerifyPayload(
                mobile: mobile,
                otp: otp,
                role: role.rawValue,
                name: name,
                lat: lat,
                lon: lon
            )
        )
    }
}
