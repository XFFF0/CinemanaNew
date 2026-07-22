import Foundation

enum AuthError: Error {
    case invalidCredentials
    case network(Error)
    case decoding
    case noRefreshToken
}

/// OAuth2 client. Credentials below were extracted via static analysis of
/// s30.java (UserManagementConfiguration) — see cinemana-reverse-engineering.md §3.1/§7.2.
enum ShabakatyOAuthConfig {
    static let accountBaseURL = URL(string: "https://account.shabakaty.com")!
    static let clientId = "com.shabakaty"
    static let clientSecret = "secret"
    static let scope = "openid email offline_access earthlink.profile fileservice songster"
    // Base64("Shabakaty.Mobile:secret")
    static let basicAuthHeader = "Basic U2hhYmFrYXR5Lk1vYmlsZTpzZWNyZXQ="
    static let googleClientId = "809377071843-jc87v0q9i2f0k20sncd3rordaj79e1ul.apps.googleusercontent.com"
    static let facebookAppId = "1870041376359385"
}

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isAuthenticated: Bool = false

    private let keychain = KeychainManager.shared
    private let session: URLSession

    private init(session: URLSession = .shared) {
        self.session = session
        self.isAuthenticated = keychain.get("access_token") != nil
    }

    var accessToken: String? { keychain.get("access_token") }

    // MARK: - Password grant login

    func login(email: String, password: String) async throws {
        var request = URLRequest(url: ShabakatyOAuthConfig.accountBaseURL.appendingPathComponent("core/connect/token"))
        request.httpMethod = "POST"
        request.setValue(ShabakatyOAuthConfig.basicAuthHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "username": email,
            "password": password,
            "scope": ShabakatyOAuthConfig.scope,
            "grant_type": "password"
        ]
        request.httpBody = formEncode(body)

        try await performTokenRequest(request)
    }

    // MARK: - Social login (Facebook / Google)

    func loginWithGoogle(idToken: String) async throws {
        try await socialLogin(provider: "google", token: idToken)
    }

    func loginWithFacebook(accessToken: String) async throws {
        try await socialLogin(provider: "facebook", token: accessToken)
    }

    private func socialLogin(provider: String, token: String) async throws {
        var components = URLComponents(url: ShabakatyOAuthConfig.accountBaseURL.appendingPathComponent("core/connect/\(provider)"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "clientId", value: provider == "google" ? ShabakatyOAuthConfig.googleClientId : ShabakatyOAuthConfig.facebookAppId),
            URLQueryItem(name: "scope", value: ShabakatyOAuthConfig.scope)
        ]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue(ShabakatyOAuthConfig.basicAuthHeader, forHTTPHeaderField: "Authorization")

        try await performTokenRequest(request)
    }

    // MARK: - Refresh

    func refreshTokenIfNeeded() async throws {
        guard let refreshToken = keychain.get("refresh_token") else {
            throw AuthError.noRefreshToken
        }
        var request = URLRequest(url: ShabakatyOAuthConfig.accountBaseURL.appendingPathComponent("core/connect/token"))
        request.httpMethod = "POST"
        request.setValue(ShabakatyOAuthConfig.basicAuthHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "refresh_token": refreshToken,
            "scope": ShabakatyOAuthConfig.scope,
            "grant_type": "refresh_token"
        ]
        request.httpBody = formEncode(body)

        try await performTokenRequest(request)
    }

    func logout() {
        keychain.clearAll()
        isAuthenticated = false
    }

    // MARK: - Helpers

    private func performTokenRequest(_ request: URLRequest) async throws {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw AuthError.invalidCredentials
            }
            let decoder = JSONDecoder()
            let token = try decoder.decode(TokenResponse.self, from: data)
            keychain.set(token.accessToken, forKey: "access_token")
            if let refresh = token.refreshToken {
                keychain.set(refresh, forKey: "refresh_token")
            }
            isAuthenticated = true
        } catch let error as AuthError {
            throw error
        } catch is DecodingError {
            throw AuthError.decoding
        } catch {
            throw AuthError.network(error)
        }
    }

    private func formEncode(_ params: [String: String]) -> Data {
        params.map { key, value in
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? key
            let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? value
            return "\(encodedKey)=\(encodedValue)"
        }
        .joined(separator: "&")
        .data(using: .utf8)!
    }
}

private extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&=")
        return allowed
    }()
}
