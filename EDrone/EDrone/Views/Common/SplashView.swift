import SwiftUI
import UIKit

struct SplashView: View {
    @State private var progress: CGFloat = 0
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.background, AppTheme.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Image("splash-background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 28) {
                appIconImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .shadow(color: AppTheme.overlay.opacity(0.4), radius: 24, x: 0, y: 16)

                VStack(spacing: 8) {
                    Text("Destrone")
                        .font(AppTheme.font(36, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Precision Farming from Above")
                        .font(AppTheme.font(16, weight: .medium))
                        .foregroundStyle(AppTheme.subtle)
                }

                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(AppTheme.accent)
                    .frame(maxWidth: 220)
                    .padding(.top, 24)
            }
        }
        .onAppear(perform: start)
    }

    private func start() {
        withAnimation(.easeInOut(duration: 2.2)) {
            progress = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            onFinish()
        }
    }
}

private extension SplashView {
    var appIconImage: Image {
        guard
            let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primaryIcon = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
            let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
            let iconName = iconFiles.last,
            let uiImage = UIImage(named: iconName)
        else {
            return Image(systemName: "airplane.circle.fill")
        }
        return Image(uiImage: uiImage)
    }
}

#Preview {
    SplashView(onFinish: {})
}
