import Foundation

final class TokenManager {
    static let shared = TokenManager()

    private let tokenKey = "edrone.token"
    private let mobileKey = "edrone.mobile"
    private let roleKey = "edrone.role"
    private let rolesKey = "edrone.roles"
    private let profileNameKey = "edrone.profile_name"
    private let onboardingKey = "edrone.onboarding_complete"
    private let onboardingPreferredRoleKey = "edrone.onboarding_preferred_role"
    private let defaults: UserDefaults

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var token: String? {
        get { defaults.string(forKey: tokenKey) }
        set {
            if let value = newValue {
                defaults.set(value, forKey: tokenKey)
            } else {
                defaults.removeObject(forKey: tokenKey)
            }
        }
    }

    var mobile: String? {
        get { defaults.string(forKey: mobileKey) }
        set {
            if let value = newValue {
                defaults.set(value, forKey: mobileKey)
            } else {
                defaults.removeObject(forKey: mobileKey)
            }
        }
    }

    var selectedRole: UserRole? {
        get {
            guard let raw = defaults.string(forKey: roleKey) else { return nil }
            return UserRole(rawValue: raw)
        }
        set {
            if let value = newValue {
                defaults.set(value.rawValue, forKey: roleKey)
            } else {
                defaults.removeObject(forKey: roleKey)
            }
        }
    }

    var availableRoles: [UserRole] {
        get {
            guard let stored = defaults.array(forKey: rolesKey) as? [String] else { return [] }
            return stored.compactMap(UserRole.init(rawValue:))
        }
        set {
            if newValue.isEmpty {
                defaults.removeObject(forKey: rolesKey)
            } else {
                defaults.set(newValue.map { $0.rawValue }, forKey: rolesKey)
            }
        }
    }

    var profileName: String? {
        get { defaults.string(forKey: profileNameKey) }
        set {
            if let value = newValue, !value.isEmpty {
                defaults.set(value, forKey: profileNameKey)
            } else {
                defaults.removeObject(forKey: profileNameKey)
            }
        }
    }

    var hasSeenOnboarding: Bool {
        get { defaults.bool(forKey: onboardingKey) }
        set { defaults.set(newValue, forKey: onboardingKey) }
    }

    var onboardingPreferredRole: UserRole? {
        get {
            guard let raw = defaults.string(forKey: onboardingPreferredRoleKey) else { return nil }
            return UserRole(rawValue: raw)
        }
        set {
            if let role = newValue {
                defaults.set(role.rawValue, forKey: onboardingPreferredRoleKey)
            } else {
                defaults.removeObject(forKey: onboardingPreferredRoleKey)
            }
        }
    }

    func clear() {
        token = nil
        mobile = nil
        selectedRole = nil
        availableRoles = []
        profileName = nil
        defaults.removeObject(forKey: onboardingKey)
        defaults.removeObject(forKey: onboardingPreferredRoleKey)
    }
}
