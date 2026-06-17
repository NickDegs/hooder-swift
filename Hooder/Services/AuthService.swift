import Foundation
import AuthenticationServices

@MainActor
final class AuthService: ObservableObject {

    @Published var isAuthenticated = false
    @Published var userID:      String = ""
    @Published var displayName: String = ""
    @Published var email:       String = ""
    @Published var authError:   String?

    private let kv    = NSUbiquitousKeyValueStore.default
    private let local = UserDefaults.standard

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(kvChanged),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: kv
        )
        kv.synchronize()
        restoreSession()
    }

    // MARK: - Restore

    func restoreSession() {
        let uid = kv.string(forKey: "auth_uid") ?? local.string(forKey: "auth_uid") ?? ""
        guard !uid.isEmpty else { return }
        userID      = uid
        displayName = kv.string(forKey: "auth_name")  ?? local.string(forKey: "auth_name")  ?? "Oyuncu"
        email       = kv.string(forKey: "auth_email") ?? local.string(forKey: "auth_email") ?? ""
        isAuthenticated = true
    }

    // MARK: - Apple Sign-In

    func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let cred = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
            let uid = "apple_" + cred.user

            var name = [cred.fullName?.givenName, cred.fullName?.familyName]
                .compactMap { $0 }.joined(separator: " ")
            if name.isEmpty {
                name = kv.string(forKey: "auth_name") ?? local.string(forKey: "auth_name") ?? "Oyuncu"
            }
            let mail = cred.email
                ?? kv.string(forKey: "auth_email")
                ?? local.string(forKey: "auth_email")
                ?? ""
            completeSignIn(uid: uid, name: name.isEmpty ? "Oyuncu" : name, email: mail)

        case .failure(let err):
            let ns = err as NSError
            guard ns.domain == ASAuthorizationError.errorDomain,
                  ns.code  == ASAuthorizationError.canceled.rawValue else {
                authError = err.localizedDescription
                return
            }
        }
    }

    // MARK: - Sign Out

    func signOut() {
        for key in ["auth_uid", "auth_name", "auth_email"] {
            kv.removeObject(forKey: key)
            local.removeObject(forKey: key)
        }
        kv.synchronize()
        userID = ""; displayName = ""; email = ""
        isAuthenticated = false
    }

    // App Store ekran görüntüsü modu — otomatik misafir girişi (yalnız HOODER_SHOTS env'inde çağrılır)
    func enterScreenshotMode() {
        completeSignIn(uid: "shots_demo", name: "Yatırımcı", email: "")
    }

    // MARK: - Helpers

    private func completeSignIn(uid: String, name: String, email: String) {
        userID = uid; displayName = name; self.email = email
        isAuthenticated = true

        kv.set(uid,   forKey: "auth_uid");   local.set(uid,   forKey: "auth_uid")
        kv.set(name,  forKey: "auth_name");  local.set(name,  forKey: "auth_name")
        kv.set(email, forKey: "auth_email"); local.set(email, forKey: "auth_email")
        kv.synchronize()
    }

    @objc private func kvChanged(_ notification: Notification) {
        if !isAuthenticated { restoreSession() }
    }
}
