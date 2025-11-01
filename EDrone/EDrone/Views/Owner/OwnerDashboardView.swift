import SwiftUI

struct OwnerDashboardView: View {
    var body: some View {
        NavigationStack {
            OwnerDroneListView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
