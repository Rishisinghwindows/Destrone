//
//  ContentView.swift
//  EDrone
//
//  Created by pawan on 29/10/25.
//

import SwiftUI
struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.token == nil {
                AuthFlowView()
            } else if appState.selectedRole == nil && appState.availableRoles.count > 1 {
                RoleSelectView()
            } else {
                MainDashboardView()
            }
        }
        .environmentObject(appState)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}

private struct MainDashboardView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        switch appState.selectedRole {
        case .farmer:
            FarmerTabScaffold()
        case .owner:
            OwnerTabScaffold()
        case .none:
            ProfileView()
        }
    }
}

private struct FarmerTabScaffold: View {
    @EnvironmentObject private var appState: AppState
    @State private var selection: FarmerTab = .drones
    @State private var hasLoaded = false

    var body: some View {
        TabView(selection: $selection) {
            FarmerDashboardView()
                .tabItem {
                    Label("Drones", systemImage: "leaf")
                }
                .tag(FarmerTab.drones)

            BookingsView()
                .environmentObject(appState)
                .tabItem {
                    Label("Bookings", systemImage: "calendar")
                }
                .tag(FarmerTab.bookings)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
            .tag(FarmerTab.profile)
        }
        .onAppear {
            if !hasLoaded {
                hasLoaded = true
                Task { await appState.refreshData() }
            }
        }
        .onChange(of: selection) { _, tab in
            switch tab {
            case .drones, .bookings:
                appState.switchRole(.farmer)
            case .profile:
                break
            }
        }
        .overlay(alignment: .bottom) {
            if appState.isLoading {
                LoadingView()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                    .padding()
            }
        }
    }
}

private enum FarmerTab: Hashable {
    case drones
    case bookings
    case profile
}

private struct OwnerTabScaffold: View {
    @EnvironmentObject private var appState: AppState
    @State private var selection: OwnerTab = .drones
    @State private var hasLoaded = false

    var body: some View {
        TabView(selection: $selection) {
            OwnerDroneListView()
                .environmentObject(appState)
                .tabItem {
                    Label("My Drones", systemImage: "airplane")
                }
                .tag(OwnerTab.drones)

            BookingsView()
                .environmentObject(appState)
                .tabItem {
                    Label("Bookings", systemImage: "calendar")
                }
                .tag(OwnerTab.bookings)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
            .tag(OwnerTab.profile)
        }
        .onAppear {
            if !hasLoaded {
                hasLoaded = true
                Task { await appState.refreshData() }
            }
            appState.switchRole(.owner)
        }
        .onChange(of: selection) { _, tab in
            switch tab {
            case .drones, .bookings:
                appState.switchRole(.owner)
            case .profile:
                break
            }
        }
        .overlay(alignment: .bottom) {
            if appState.isLoading {
                LoadingView()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                    .padding()
            }
        }
    }
}

private enum OwnerTab: Hashable {
    case drones
    case bookings
    case profile
}
