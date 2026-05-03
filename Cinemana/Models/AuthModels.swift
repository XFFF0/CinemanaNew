import Foundation

struct TokenResponse: Codable {
    let accessToken: String?
    let refreshToken: String?
    let expiresIn: Int?
    let tokenType: String?
    let scope: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case scope
    }
}

struct UserInfo: Codable {
    let sub: String?
    let email: String?
    let name: String?
    let picture: String?
    let pictureSmall: String?
    let pictureLarge: String?
    let firstName: String?
    let lastName: String?
    let phoneNumber: String?

    var displayName: String {
        name ?? email ?? "User"
    }

    var avatarUrl: String? {
        pictureLarge ?? pictureSmall ?? picture
    }
}

enum AuthError: Error, LocalizedError {
    case loginFailed
    case refreshFailed
    case invalidCredentials
    case networkError

    var errorDescription: String? {
        switch self {
        case .loginFailed:
            return "Login failed. Please check your credentials."
        case .refreshFailed:
            return "Session expired. Please login again."
        case .invalidCredentials:
            return "Invalid email or password."
        case .networkError:
            return "Network error. Please check your connection."
        }
    }
}

struct DeviceLoginRequest: Codable {
    let deviceId: String
    let deviceName: String
    let playerId: String?
}

struct SubscriptionStatus: Codable {
    let isSubscribed: Bool?
    let videoId: String?
    let userId: String?
}

struct UserNotification: Codable, Identifiable {
    var id: String { nb ?? UUID().uuidString }
    let nb: String?
    let title: String?
    let message: String?
    let date: String?
    let videoId: String?
    let isViewed: Bool?
}

struct NotificationsResponse: Codable {
    let notifications: [UserNotification]?
    let totalCount: Int?
}