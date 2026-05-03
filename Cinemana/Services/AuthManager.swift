import Foundation

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isLoggedIn: Bool = false
    @Published var userInfo: UserInfo?
    @Published var accessToken: String = ""
    @Published var refreshToken: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let clientId = "cTnj9bUcDmr08B586K7pGFHy"
    private let clientSecret = "secret"
    private let tokenKey = "com.shabakaty.cinemanaa.accessToken"
    private let refreshTokenKey = "com.shabakaty.cinemanaa.refreshToken"

    private init() {
        loadTokens()
    }

    private func loadTokens() {
        if let token = UserDefaults.standard.string(forKey: tokenKey), !token.isEmpty {
            accessToken = token
            refreshToken = UserDefaults.standard.string(forKey: refreshTokenKey) ?? ""
            isLoggedIn = true
            Task {
                try? await fetchUserInfo()
            }
        }
    }

    func login(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        let base64Credentials = Data("\(clientId):\(clientSecret)".utf8).base64EncodedString()

        var request = URLRequest(url: URL(string: "https://account.shabakaty.com/core/connect/token")!)
        request.httpMethod = "POST"
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "username": email,
            "password": password,
            "scope": "openid email offline_access earthlink.profile fileservice songster",
            "grant_type": "password"
        ]
        request.httpBody = body.map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.loginFailed
            }

            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 401 {
                    throw AuthError.invalidCredentials
                }
                throw AuthError.loginFailed
            }

            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

            self.accessToken = tokenResponse.accessToken ?? ""
            self.refreshToken = tokenResponse.refreshToken ?? ""
            self.isLoggedIn = true

            UserDefaults.standard.set(tokenResponse.accessToken, forKey: tokenKey)
            UserDefaults.standard.set(tokenResponse.refreshToken, forKey: refreshTokenKey)

            try await fetchUserInfo()
            try await registerDevice()
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
            throw error
        } catch {
            errorMessage = "Network error. Please check your connection."
            throw AuthError.networkError
        }
    }

    func fetchUserInfo() async throws {
        guard !accessToken.isEmpty else { return }

        var request = URLRequest(url: URL(string: "https://account.shabakaty.com/core/connect/userinfo")!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)

        if let userInfo = try? JSONDecoder().decode(UserInfo.self, from: data) {
            self.userInfo = userInfo
        }
    }

    func refreshAccessToken() async throws {
        guard !refreshToken.isEmpty else {
            throw AuthError.refreshFailed
        }

        let base64Credentials = Data("\(clientId):\(clientSecret)".utf8).base64EncodedString()

        var request = URLRequest(url: URL(string: "https://account.shabakaty.com/core/connect/token")!)
        request.httpMethod = "POST"
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "refresh_token": refreshToken,
            "scope": "openid email offline_access earthlink.profile fileservice songster",
            "grant_type": "refresh_token"
        ]
        request.httpBody = body.map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthError.refreshFailed
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        self.accessToken = tokenResponse.accessToken ?? ""
        self.refreshToken = tokenResponse.refreshToken ?? ""

        UserDefaults.standard.set(tokenResponse.accessToken, forKey: tokenKey)
        UserDefaults.standard.set(tokenResponse.refreshToken, forKey: refreshTokenKey)
    }

    func registerDevice() async throws {
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let deviceName = UIDevice.current.name

        try await APIService.shared.registerDevice(deviceId: deviceId, deviceName: deviceName)
    }

    func logout() {
        accessToken = ""
        refreshToken = ""
        userInfo = nil
        isLoggedIn = false

        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
    }

    func changePassword(oldPassword: String, newPassword: String) async throws {
        guard !accessToken.isEmpty else { return }

        var request = URLRequest(url: URL(string: "https://account.shabakaty.com/core/api/password")!)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = [
            "oldPassword": oldPassword,
            "newPassword": newPassword,
            "confirmPassword": newPassword
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthError.loginFailed
        }
    }

    func forgotPassword(email: String) async throws {
        var request = URLRequest(url: URL(string: "https://account.shabakaty.com/core/api/password/mobile-forgot-password")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["email": email]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthError.loginFailed
        }
    }
}

import UIKit

enum AuthError: Error, LocalizedError {
    case loginFailed
    case refreshFailed
    case invalidCredentials
    case networkError

    var errorDescription: String? {
        switch self {
        case .loginFailed:
            return "Login failed. Please try again."
        case .refreshFailed:
            return "Session expired. Please login again."
        case .invalidCredentials:
            return "Invalid email or password."
        case .networkError:
            return "Network error. Please check your connection."
        }
    }
}