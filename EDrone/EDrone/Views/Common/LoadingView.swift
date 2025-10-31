import SwiftUI

struct LoadingView: View {
    var body: some View {
        ProgressView()
            .progressViewStyle(.circular)
            .padding()
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
