//
//  EDroneApp.swift
//  EDrone
//
//  Created by pawan on 29/10/25.
//

import SwiftUI
import UIKit

@main
struct EDroneApp: App {
    @StateObject private var appState = AppState()
    @State private var flowState: FlowState
    @State private var hasSeenOnboarding: Bool

    init() {
        let seen = TokenManager.shared.hasSeenOnboarding
        _flowState = State(initialValue: .splash)
        _hasSeenOnboarding = State(initialValue: seen)
    }

    var body: some Scene {
        WindowGroup {
            switch flowState {
            case .splash:
                SplashView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        flowState = hasSeenOnboarding ? .main : .roleIntro
                    }
                }
            case .roleIntro:
                RoleIntroView(
                    onSelect: { audience in
                        if let role = UserRole(rawValue: audience.rawValue) {
                            TokenManager.shared.onboardingPreferredRole = role
                        }
                        withAnimation(.easeInOut(duration: 0.3)) {
                            flowState = .onboarding(audience)
                        }
                    },
                    onHelp: openSupportEmail
                )
            case .onboarding(let audience):
                OnboardingView(
                    audience: audience,
                    onSkip: completeOnboarding,
                    onFinish: completeOnboarding
                )
            case .main:
                ContentView()
                    .environmentObject(appState)
                    .transition(.opacity)
            }
        }
    }

    private func completeOnboarding() {
        TokenManager.shared.hasSeenOnboarding = true
        hasSeenOnboarding = true
        withAnimation(.easeInOut(duration: 0.3)) {
            flowState = .main
        }
    }

    private func openSupportEmail() {
        guard let url = URL(string: "mailto:support@edrone.local") else { return }
        UIApplication.shared.open(url)
    }

    private enum FlowState {
        case splash
        case roleIntro
        case onboarding(OnboardingAudience)
        case main
    }
}
