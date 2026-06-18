import SwiftUI
import AuthenticationServices

struct LoginScreen: View {
    @EnvironmentObject var auth: AuthService
    @State private var appeared = false

    var body: some View {
        ZStack {
            // Deep gradient background
            LinearGradient(
                colors: [
                    Color(hex: "#020407"),
                    Color(hex: "#040b18"),
                    Color(hex: "#081428"),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Ambient glow orbs
            ZStack {
                Circle()
                    .fill(C.primary.opacity(0.18))
                    .frame(width: 340, height: 340)
                    .blur(radius: 90)
                    .offset(x: -60, y: -160)
                    .scaleEffect(appeared ? 1.0 : 0.85)
                    .animation(
                        .easeInOut(duration: 3.5).repeatForever(autoreverses: true),
                        value: appeared
                    )

                Circle()
                    .fill(C.purple.opacity(0.12))
                    .frame(width: 280, height: 280)
                    .blur(radius: 80)
                    .offset(x: 90, y: 140)
                    .scaleEffect(appeared ? 1.0 : 0.88)
                    .animation(
                        .easeInOut(duration: 4.2).repeatForever(autoreverses: true).delay(1.2),
                        value: appeared
                    )

                Circle()
                    .fill(C.green.opacity(0.08))
                    .frame(width: 200, height: 200)
                    .blur(radius: 60)
                    .offset(x: -30, y: 80)
                    .scaleEffect(appeared ? 1.0 : 0.9)
                    .animation(
                        .easeInOut(duration: 5).repeatForever(autoreverses: true).delay(0.6),
                        value: appeared
                    )
            }

            VStack(spacing: 0) {
                Spacer()

                // App icon + title
                VStack(spacing: Sp.xl) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [C.primary.opacity(0.35), C.primary.opacity(0.05)],
                                    center: .center, startRadius: 20, endRadius: 56
                                )
                            )
                            .frame(width: 112, height: 112)
                            .blur(radius: 8)

                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 88, height: 88)
                            .overlay {
                                Circle()
                                    .stroke(C.specular, lineWidth: 1)
                            }

                        Image(systemName: "building.2.fill")
                            .font(.system(size: 38, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [C.primary, Color(hex: "#5bb3ff")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(spacing: Sp.sm) {
                        Text("HOODER")
                            .font(.display)
                            .tracked(4)
                            .foregroundStyle(C.text)

                        Text("Gayrimenkul İmparatorluğunu Kur")
                            .font(.body_)
                            .foregroundStyle(C.textSub)
                            .multilineTextAlignment(.center)
                    }

                    // Feature pills
                    HStack(spacing: Sp.sm) {
                        featurePill("35 Mülk", icon: "building.fill")
                        featurePill("7 Şehir", icon: "map.fill")
                        featurePill("3D Harita", icon: "globe.desk.fill")
                    }
                }
                .offset(y: appeared ? 0 : 32)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.75, dampingFraction: 0.8).delay(0.1), value: appeared)

                Spacer()

                // Glass sign-in card
                VStack(spacing: Sp.lg) {
                    VStack(spacing: Sp.xs) {
                        Text("Hesabınla giriş yap")
                            .font(.h4)
                            .foregroundStyle(C.text)
                        Text("Veriler tüm cihazlarında Apple hesabınla korunur.")
                            .font(.caption_)
                            .foregroundStyle(C.textSub)
                            .multilineTextAlignment(.center)
                    }

                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        auth.handleAppleResult(result)
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: R.lg, style: .continuous))

                    if let err = auth.authError {
                        Text(err)
                            .font(.caption_)
                            .foregroundStyle(C.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, Sp.x2)
                .padding(.vertical, Sp.x2)
                .background {
                    RoundedRectangle(cornerRadius: R.xl, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: R.xl, style: .continuous)
                                .stroke(C.specular, lineWidth: 0.5)
                        }
                }
                .padding(.horizontal, Sp.lg)
                .offset(y: appeared ? 0 : 40)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.75, dampingFraction: 0.8).delay(0.3), value: appeared)

                Spacer().frame(height: Sp.x2)

                Text("Giriş yaparak Kullanım Koşullarını kabul etmiş sayılırsın.")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(C.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Sp.x3)
                    .padding(.bottom, Sp.x3)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.4).delay(0.5), value: appeared)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { appeared = true }
    }

    @ViewBuilder
    private func featurePill(_ label: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(C.primary)
            Text(label)
                .font(.label_)
                .foregroundStyle(C.textSub)
        }
        .padding(.horizontal, Sp.md)
        .padding(.vertical, Sp.xs)
        .liquidGlass(in: Capsule())
        .overlay(Capsule().stroke(C.border, lineWidth: 0.5))
    }
}
