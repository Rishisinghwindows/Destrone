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

private enum DashboardTab: Hashable {
    case farmer
    case owner
    case profile
}

private struct MainDashboardView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selection: DashboardTab = .farmer
    @State private var hasLoaded = false

    var body: some View {
        TabView(selection: $selection) {
            if appState.availableRoles.contains(.farmer) {
                FarmerDashboardView()
                    .tabItem {
                        Label("Farmer", systemImage: "leaf")
                    }
                    .tag(DashboardTab.farmer)
            }

            if appState.availableRoles.contains(.owner) {
                OwnerDashboardView()
                    .tabItem {
                        Label("Owner", systemImage: "airplane")
                    }
                    .tag(DashboardTab.owner)
            }

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
            .tag(DashboardTab.profile)
        }
        .onAppear {
            if !hasLoaded {
                hasLoaded = true
                Task { await appState.refreshData() }
            }
            syncSelectionWithRole()
        }
        .onChange(of: selection) { _, tab in
            switch tab {
            case .farmer:
                appState.switchRole(.farmer)
            case .owner:
                appState.switchRole(.owner)
            case .profile:
                break
            }
        }
        .onChange(of: appState.selectedRole) { _ in
            syncSelectionWithRole()
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

    private func syncSelectionWithRole() {
        if let role = appState.selectedRole {
            switch role {
            case .farmer where appState.availableRoles.contains(.farmer):
                selection = .farmer
            case .owner where appState.availableRoles.contains(.owner):
                selection = .owner
            default:
                selection = .profile
            }
        } else if selection != .profile {
            selection = .profile
        }
    }
}
