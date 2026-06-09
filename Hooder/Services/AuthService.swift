import Foundation
import AuthenticationServices
import GoogleSignIn

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

            // Apple provides name+email only on first sign-in; fall back to stored values afterwards
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

    // MARK: - Google Sign-In

    func signInWithGoogle() {
        // Verify a real Google client ID is configured (must end with .apps.googleusercontent.com)
        guard let cfg = GIDSignIn.sharedInstance.configuration,
              cfg.clientID.hasSuffix(".apps.googleusercontent.com") else {
            authError = "Google istemci kimliği yapılandırılmamış."
            return
        }

        // Find the topmost visible view controller
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let rootVC = windowScene.keyWindow?.rootViewController else {
            authError = "Pencere bulunamadı."
            return
        }
        var topVC = rootVC
        while let presented = topVC.presentedViewController { topVC = presented }

        GIDSignIn.sharedInstance.signIn(withPresenting: topVC) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let error {
                    let ns = error as NSError
                    // Ignore user cancellation (GIDSignInError.canceled = -5)
                    if ns.domain != "com.google.GIDSignIn" || ns.code != -5 {
                        self.authError = error.localizedDescription
                    }
                    return
                }
                guard let user = result?.user else { return }
                let uid  = "google_" + (user.userID ?? UUID().uuidString)
                let name = user.profile?.name ?? "Oyuncu"
                let mail = user.profile?.email ?? ""
                self.completeSignIn(uid: uid, name: name, email: mail)
            }
        }
    }

    // MARK: - Sign Out

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        for key in ["auth_uid", "auth_name", "auth_email"] {
            kv.removeObject(forKey: key)
            local.removeObject(forKey: key)
        }
        kv.synchronize()
        userID = ""; displayName = ""; email = ""
        isAuthenticated = false
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
