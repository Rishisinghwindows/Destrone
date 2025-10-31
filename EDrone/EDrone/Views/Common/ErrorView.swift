import SwiftUI

struct ErrorView: View {
    let message: String
    let retry: (() -> Void)?

    init(message: String, retry: (() -> Void)? = nil) {
        self.message = message
        self.retry = retry
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(.yellow)
            Text(message)
                .multilineTextAlignment(.center)
            if let retry = retry {
                Button("Retry", action: retry)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
