import SwiftUI
import CoreLocation
import UIKit

struct AuthFlowView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var locationManager = LocationManager.shared

    @State private var mobile: String = TokenManager.shared.mobile ?? ""
    @State private var name: String = ""
    @State private var otp: String = ""
    @State private var signupRole: UserRole = .farmer
    @State private var step: Step = .enterMobile
    @State private var isProcessing = false
    @State private var infoMessage: String?
    @State private var demoOTP: String?
    @State private var countdown: Int = 0
    @State private var otpLength: Int = 4

    @FocusState private var focusedField: FocusField?

    private enum Step {
        case enterMobile
        case verify
    }

    private enum FocusField: Hashable {
        case mobile
        case otp
        case name
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                header
                mobileInput
                actionButtons
                if let message = infoMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.subtle)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                if step == .verify {
                    Divider()
                        .overlay(AppTheme.stroke)
                    verificationSection
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .onAppear {
            LocationManager.shared.requestAccess()
        }
        .alert("Error", isPresented: Binding(
            get: { appState.errorMessage != nil },
            set: { if !$0 { appState.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { appState.errorMessage = nil }
        } message: {
            Text(appState.errorMessage ?? "Unknown error")
        }
        .onChange(of: mobile) { newValue in
            let digits = newValue.filter(\.isNumber)
            mobile = String(digits.prefix(10))
        }
        .onChange(of: otp) { newValue in
            let digits = newValue.filter(\.isNumber)
            otp = String(digits.prefix(otpLength))
        }
    }

    private var header: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(AppTheme.surface.opacity(0.4))
                    .frame(width: 72, height: 72)
                Image(systemName: "airplane.circle.fill")
                    .font(AppTheme.font(28, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
            }

            VStack(spacing: 6) {
                Text("Welcome Back, Farmer!")
                    .font(AppTheme.font(32, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                Text("Log in to manage your farm drones.")
                    .font(AppTheme.font(14, weight: .medium))
                    .foregroundStyle(AppTheme.subtle)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var mobileInput: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Enter your mobile number to get an OTP.")
                .font(AppTheme.font(14))
                .foregroundStyle(AppTheme.subtle)

            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(AppTheme.surface.opacity(0.65))

                HStack(spacing: 12) {
                    Text("+91")
                        .font(AppTheme.font(15, weight: .semibold))
                        .foregroundStyle(AppTheme.subtle)
                        .padding(.leading, 18)

                    Divider()
                        .frame(height: 28)
                        .overlay(AppTheme.stroke)

                    TextField("98765 43210", text: $mobile)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .mobile)
                        .textContentType(.telephoneNumber)
                        .font(AppTheme.font(16, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(.vertical, 14)
                        .onAppear { if mobile.isEmpty { focusedField = .mobile } }

                    Spacer(minLength: 8)

                    Button {
                        mobile = "9876543210"
                    } label: {
                        Image(systemName: "iphone")
                            .font(AppTheme.font(15, weight: .semibold))
                            .foregroundStyle(AppTheme.subtle)
                            .padding(12)
                            .background(AppTheme.surface.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                    }
                    .padding(.trailing, 12)
                }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 16) {
            Button(action: requestOTP) {
                HStack {
                    if isProcessing && step == .enterMobile { ProgressView().tint(AppTheme.textPrimary) }
                    Text("Send OTP")
                        .font(AppTheme.font(16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(AppTheme.textPrimary)
                .background(mobile.count == 10 ? AppTheme.accent : AppTheme.accentMuted.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            }
            .disabled(isProcessing || mobile.count < 10)
        }
    }

    private var verificationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Enter the \(otpLength)-digit code sent to your mobile.")
                .font(AppTheme.font(14))
                .foregroundStyle(AppTheme.subtle)

            OTPInputView(
                code: $otp,
                length: otpLength,
                isFirstResponder: Binding(
                    get: { focusedField == .otp },
                    set: { focusedField = $0 ? .otp : nil }
                )
            )
            .frame(height: 56)

            VStack(alignment: .leading, spacing: 12) {
                Text("Choose a role and confirm your name.")
                    .font(AppTheme.font(14))
                    .foregroundStyle(AppTheme.subtle)

                Picker("Role", selection: $signupRole) {
                    ForEach(UserRole.allCases) { role in
                        Text(role.label).tag(role)
                    }
                }
                .pickerStyle(.segmented)

                TextField(roleNamePlaceholder, text: $name)
                    .textInputAutocapitalization(.words)
                    .focused($focusedField, equals: .name)
                    .padding(16)
                    .background(AppTheme.surface)
                    .foregroundStyle(AppTheme.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                            .stroke(AppTheme.stroke)
                    )
            }

            Button(action: verifyOTP) {
                HStack {
                    if isProcessing && step == .verify { ProgressView().tint(AppTheme.textPrimary) }
                    Text("Verify & Login")
                        .font(AppTheme.font(16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canVerify ? AppTheme.accent : AppTheme.accentMuted.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                .foregroundStyle(AppTheme.textPrimary)
            }
            .disabled(!canVerify || isProcessing)

            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Text("Didn't receive the code?")
                        .font(AppTheme.font(14))
                        .foregroundStyle(AppTheme.subtle)
                    Button("Resend OTP" + (countdown > 0 ? " (\(countdown))" : "")) {
                        requestOTP()
                    }
                    .disabled(countdown > 0 || isProcessing)
                    .font(AppTheme.font(14, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                }

                Button("Contact Support") {
                    if let url = URL(string: "mailto:support@edrone.local") {
                        UIApplication.shared.open(url)
                    }
                }
                .font(AppTheme.font(14, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
            }
        }
    }

    private var roleNamePlaceholder: String {
        switch signupRole {
        case .farmer:
            return "Your name (farmer profile)"
        case .owner:
            return "Your name (owner profile)"
        }
    }

    private var canVerify: Bool {
        mobile.count == 10
            && otp.count == otpLength
            && !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func requestOTP() {
        guard mobile.count == 10 else { return }
        isProcessing = true
        Task {
            defer { isProcessing = false }
            do {
                let response = try await appState.authService.requestOTP(mobile: mobile)
                demoOTP = response.demoOtp
                otpLength = max(response.demoOtp?.count ?? 4, 4)
                infoMessage = "OTP sent to \(response.mobile)."
                otp = demoOTP ?? "1234"
                step = .verify
                startCountdown()
                focusedField = .otp
            } catch {
                appState.errorMessage = error.localizedDescription
            }
        }
    }

    private func verifyOTP() {
        guard canVerify else { return }
        let sanitizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        isProcessing = true
        let coordinate = locationManager.lastLocation?.coordinate
        Task {
            defer { isProcessing = false }
            do {
                let auth = try await appState.authService.verifyOTP(
                    mobile: mobile,
                    otp: otp,
                    role: signupRole,
                    name: sanitizedName,
                    lat: coordinate?.latitude,
                    lon: coordinate?.longitude
                )
                appState.updateToken(
                    auth.accessToken,
                    mobile: mobile,
                    activeRole: signupRole,
                    roles: auth.roles.compactMap(UserRole.init(rawValue:)),
                    profileName: auth.profileName ?? sanitizedName
                )
                if let serverName = auth.profileName {
                    name = serverName
                }
                infoMessage = "Signed in as \(signupRole.label)."
                focusedField = nil
            } catch {
                appState.errorMessage = error.localizedDescription
            }
        }
    }

private func startCountdown() {
    countdown = 30
    Task.detached(priority: .background) {
        while countdown > 0 {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run { countdown -= 1 }
        }
    }
}
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}

private struct OTPInputView: View {
    @Binding var code: String
    var length: Int = 6
    @Binding var isFirstResponder: Bool

    @FocusState private var isFocused: Bool

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 12) {
                ForEach(0..<length, id: \.self) { index in
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .fill(AppTheme.surface.opacity(0.6))
                        .frame(width: 48, height: 56)
                        .overlay(
                            Text(character(at: index))
                                .font(AppTheme.font(18, weight: .semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                        )
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .overlay {
                TextField("", text: Binding(
                    get: { code },
                    set: { newValue in
                        let filtered = newValue.filter(\.isNumber)
                        code = String(filtered.prefix(length))
                    }
                ))
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .frame(width: proxy.size.width, height: proxy.size.height)
                .opacity(0.01)
                .tint(.clear)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isFirstResponder = true
                isFocused = true
            }
            .onChange(of: isFirstResponder) { shouldFocus in
                if shouldFocus {
                    DispatchQueue.main.async { isFocused = true }
                } else {
                    isFocused = false
                }
            }
            .onChange(of: isFocused) { focused in
                if !focused {
                    isFirstResponder = false
                }
            }
            .onAppear {
                if isFirstResponder {
                    DispatchQueue.main.async { isFocused = true }
                }
            }
        }
        .frame(height: 56)
    }

    private func character(at index: Int) -> String {
        guard index < code.count else { return "" }
        let charIndex = code.index(code.startIndex, offsetBy: index)
        return String(code[charIndex])
    }
}
