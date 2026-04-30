import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct AuthView: View {

    @EnvironmentObject var appVM: AppViewModel

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.primaryPurple,
                    Color(red: 0.18, green: 0.16, blue: 0.28),
                    Color(red: 0.07, green: 0.07, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Decorative circles
            GeometryReader { geo in
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 300)
                    .offset(x: -80, y: -80)
                Circle()
                    .fill(Color.accentBlue.opacity(0.12))
                    .frame(width: 200)
                    .offset(x: geo.size.width - 60, y: geo.size.height * 0.3)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 110, height: 110)
                    Image(systemName: "house.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 32)

                // Title
                Text("Family Hub")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Your family command center")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 8)
                    .padding(.bottom, 48)

                // Feature bullets
                VStack(alignment: .leading, spacing: 14) {
                    FeatureBullet(icon: "checkmark.circle.fill",  color: .accentGreen,  text: "Shared tasks & chores")
                    FeatureBullet(icon: "star.fill",             color: .accentOrange, text: "Gamified points & rewards")
                    FeatureBullet(icon: "calendar",              color: .accentBlue,   text: "Family calendar sync")
                    FeatureBullet(icon: "cart.fill",             color: Color(red: 1, green: 0.6, blue: 0.8), text: "Grocery list & budget tracking")
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 52)

                // Sign in button area
                VStack(spacing: 16) {
                    if appVM.isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.3)
                            .frame(height: 50)
                    } else {
                        GoogleSignInButtonWrapper {
                            Task { await signIn() }
                        }
                        .frame(height: 50)
                        .cornerRadius(12)
                        .padding(.horizontal, 32)
                    }

                    if let error = appVM.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(Color.accentRed.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }

                Spacer()

                Text("Sign in with your Google account to get started")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.bottom, 32)
            }
        }
    }

    private func signIn() async {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        await appVM.signIn(presenting: rootVC)
    }
}

// MARK: - Google Sign-In Button Wrapper

private struct GoogleSignInButtonWrapper: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(red: 0.26, green: 0.52, blue: 0.96))
                Text("Sign in with Google")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.white)
            .cornerRadius(12)
        }
    }
}

// MARK: - Feature Bullet

private struct FeatureBullet: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
        }
    }
}
