import SwiftUI
import AuthenticationServices
import GoogleSignIn

struct LoginScreen: View {
    @EnvironmentObject var auth: AuthService

    private var googleConfigured: Bool {
        GIDSignIn.sharedInstance.configuration != nil
    }

    var body: some View {
        ZStack {
            C.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                ZStack {
                    RoundedRectangle(cornerRadius: R.xl)
                        .fill(
                            LinearGradient(
                                colors: [C.primary.opacity(0.8), C.purple.opacity(0.6)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88, height: 88)
                    Image(systemName: "building.2.crop.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white)
                }
                .shadow(color: C.primary.opacity(0.4), radius: 20)

                Spacer().frame(height: Sp.x3)

                Text("HOODER")
                    .font(.system(size: 34, weight: .black))
                    .tracked(6)
                    .foregroundColor(C.text)

                Spacer().frame(height: Sp.sm)

                Text("Gayrimenkul İmparatorluğunu Kur")
                    .font(.body_)
                    .foregroundColor(C.textMuted)

                Spacer().frame(height: Sp.x4 * 2)

                VStack(spacing: Sp.md) {

                    // Apple Sign-In
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            auth.handleAppleResult(result)
                        }
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 54)
                    .cornerRadius(R.lg)

                    // Google Sign-In (only shown if configured)
                    if googleConfigured {
                        Button {
                            auth.authError = nil
                            auth.signInWithGoogle()
                        } label: {
                            HStack(spacing: Sp.md) {
                                Image(systemName: "g.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(Color(hex: "#EA4335"))
                                Text("Google ile Giriş Yap")
                                    .font(.bodyBold)
                                    .foregroundColor(Color(hex: "#1f1f1f"))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.white)
                            .cornerRadius(R.lg)
                        }
                    }
                }
                .padding(.horizontal, Sp.x3)

                if let err = auth.authError {
                    Text(err)
                        .font(.caption_)
                        .foregroundColor(C.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Sp.x3)
                        .padding(.top, Sp.md)
                }

                Spacer().frame(height: Sp.x3)

                Text("Giriş yaparak hesabın tüm cihazlarında korunur.\nUygulama silinse bile verilerini kurtarabilirsin.")
                    .font(.caption_)
                    .foregroundColor(C.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Sp.x3)

                Spacer()

                Text("Giriş yaparak Kullanım Koşullarını kabul etmiş sayılırsın.")
                    .font(.system(size: 11))
                    .foregroundColor(C.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Sp.x3)
                    .padding(.bottom, Sp.x3)
            }
        }
        .preferredColorScheme(.dark)
    }
}
