import Foundation

struct OTPRequestResponse: Codable {
    let mobile: String
    let otpSent: Bool
    let demoOtp: String?

    enum CodingKeys: String, CodingKey {
        case mobile
        case otpSent = "otp_sent"
        case demoOtp = "demo_otp"
    }
}

struct AuthResponse: Codable {
    let accessToken: String
    let tokenType: String
    let role: String
    let roles: [String]
    let profileName: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case role
        case roles
        case profileName = "profile_name"
    }

    init(accessToken: String, tokenType: String, role: String, roles: [String], profileName: String?) {
        self.accessToken = accessToken
        self.tokenType = tokenType
        self.role = role
        self.roles = roles
        self.profileName = profileName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try container.decode(String.self, forKey: .accessToken)
        tokenType = try container.decode(String.self, forKey: .tokenType)
        profileName = try container.decodeIfPresent(String.self, forKey: .profileName)

        let primaryRole = try container.decodeIfPresent(String.self, forKey: .role)
        let decodedRoles = try container.decodeIfPresent([String].self, forKey: .roles) ?? []

        if let firstRole = primaryRole ?? decodedRoles.first {
            role = firstRole
            roles = decodedRoles.isEmpty ? [firstRole] : decodedRoles
        } else {
            role = ""
            roles = []
        }
    }
}
