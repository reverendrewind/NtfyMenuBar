//
//  CreateUserSheet.swift
//  NtfyMenuBar
//
//  Created by Claude on 20/09/2025.
//

import SwiftUI

struct CreateUserSheet: View {
    @ObservedObject var userService: UserManagementService
    @Environment(\.dismiss) private var dismiss

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var selectedRole: UserRole = .user
    @State private var isCreating: Bool = false
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Create New User")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .disabled(isCreating)
            }

            VStack(alignment: .leading, spacing: 16) {
                // Username
                VStack(alignment: .leading, spacing: 8) {
                    Text("Username")
                        .font(.headline)

                    TextField("Enter username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .disabled(isCreating)

                    Text("3-32 characters, letters, numbers, dashes, and underscores only")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Password
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.headline)

                    SecureField("Enter password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .disabled(isCreating)

                    Text("Minimum 8 characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Confirm Password
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm Password")
                        .font(.headline)

                    SecureField("Confirm password", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
                        .disabled(isCreating)
                }

                // Role Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Role")
                        .font(.headline)

                    VStack(spacing: 8) {
                        ForEach(UserRole.allCases, id: \.self) { role in
                            RoleSelectionRow(
                                role: role,
                                isSelected: selectedRole == role,
                                onSelect: { selectedRole = role }
                            )
                            .disabled(isCreating)
                        }
                    }
                }

                // Validation Messages
                VStack(alignment: .leading, spacing: 4) {
                    if !isValidUsername && !username.isEmpty {
                        ValidationMessage(
                            icon: "exclamationmark.triangle",
                            message: "Invalid username format",
                            color: .orange
                        )
                    }

                    if !isValidPassword && !password.isEmpty {
                        ValidationMessage(
                            icon: "exclamationmark.triangle",
                            message: "Password must be at least 8 characters",
                            color: .orange
                        )
                    }

                    if !passwordsMatch && !confirmPassword.isEmpty {
                        ValidationMessage(
                            icon: "exclamationmark.triangle",
                            message: "Passwords do not match",
                            color: .orange
                        )
                    }

                    if canCreateUser {
                        ValidationMessage(
                            icon: "checkmark.circle",
                            message: "Ready to create user",
                            color: .green
                        )
                    }
                }
            }

            Spacer()

            // Footer
            HStack {
                Spacer()

                if isCreating {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Creating user...")
                            .foregroundColor(.secondary)
                    }
                } else {
                    Button("Create User") {
                        createUser()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canCreateUser)
                }
            }
        }
        .padding(20)
        .frame(width: 450, height: 500)
        .background(Color.theme.windowBackground)
        .alert("Error Creating User", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Validation

    private var isValidUsername: Bool {
        let pattern = "^[a-zA-Z0-9_-]+$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: username.utf16.count)

        return !username.isEmpty &&
               username.count >= 3 &&
               username.count <= 32 &&
               regex?.firstMatch(in: username, options: [], range: range) != nil
    }

    private var isValidPassword: Bool {
        return password.count >= 8
    }

    private var passwordsMatch: Bool {
        return password == confirmPassword
    }

    private var canCreateUser: Bool {
        return isValidUsername && isValidPassword && passwordsMatch && !isCreating
    }

    // MARK: - Actions

    private func createUser() {
        isCreating = true

        Task {
            do {
                try await userService.createUser(
                    username: username,
                    password: password,
                    role: selectedRole
                )

                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    handleError(error)
                }
            }
        }
    }

    private func handleError(_ error: Error) {
        if let userError = error as? UserManagementError {
            errorMessage = userError.localizedDescription
        } else {
            errorMessage = error.localizedDescription
        }
        showingError = true
    }
}

struct RoleSelectionRow: View {
    let role: UserRole
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.secondary, lineWidth: 2)
                        .frame(width: 16, height: 16)

                    if isSelected {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                    }
                }

                // Role icon
                Image(systemName: role.systemImage)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .frame(width: 24)

                // Role info
                VStack(alignment: .leading, spacing: 2) {
                    Text(role.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .blue : .primary)

                    Text(role.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.secondary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ValidationMessage: View {
    let icon: String
    let message: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)

            Text(message)
                .font(.caption)
                .foregroundColor(color)
        }
    }
}

#Preview {
    CreateUserSheet(userService: UserManagementService(settings: .default))
}