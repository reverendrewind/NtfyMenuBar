//
//  UserManagementView.swift
//  NtfyMenuBar
//
//  Created by Claude on 20/09/2025.
//

import SwiftUI

struct UserManagementView: View {
    @EnvironmentObject var viewModel: NtfyViewModel
    @StateObject private var userService: UserManagementService
    @Environment(\.dismiss) private var dismiss

    @State private var showingCreateSheet = false
    @State private var selectedUser: NtfyUser?
    @State private var showingDeleteConfirmation = false
    @State private var userToDelete: NtfyUser?
    @State private var showingError = false
    @State private var errorMessage = ""

    init(settings: NtfySettings) {
        _userService = StateObject(wrappedValue: UserManagementService(settings: settings))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("User Management")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("New User") {
                    showingCreateSheet = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(userService.isLoading)
            }

            if userService.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading users...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 40)
            } else if userService.users.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.2")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No Users Found")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Create your first user to get started")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("Create User") {
                        showingCreateSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 40)
            } else {
                // Users List
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Users (\(userService.users.count))")
                            .font(.headline)

                        Spacer()

                        Button("Refresh") {
                            Task {
                                await userService.loadUsers()
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(userService.isLoading)
                    }

                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(userService.users) { user in
                                UserRowView(
                                    user: user,
                                    currentUsername: viewModel.settings.username,
                                    onDelete: { userToDelete in
                                        self.userToDelete = userToDelete
                                        showingDeleteConfirmation = true
                                    },
                                    onChangeRole: { user, newRole in
                                        Task {
                                            do {
                                                try await userService.changeUserRole(user, to: newRole)
                                            } catch {
                                                handleError(error)
                                            }
                                        }
                                    },
                                    onChangePassword: { user in
                                        selectedUser = user
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Spacer()

            // Footer
            HStack {
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Spacer()
            }
        }
        .padding(20)
        .frame(width: 650, height: 550)
        .background(Color.theme.windowBackground)
        .onAppear {
            userService.updateSettings(viewModel.settings)
            Task {
                await userService.loadUsers()
            }
        }
        .onChange(of: viewModel.settings) {
            userService.updateSettings(viewModel.settings)
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateUserSheet(userService: userService)
        }
        .confirmationDialog(
            "Delete User",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let user = userToDelete {
                    Task {
                        do {
                            try await userService.deleteUser(user)
                        } catch {
                            handleError(error)
                        }
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let user = userToDelete {
                Text("Are you sure you want to delete user '\(user.username)'? This action cannot be undone.")
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(item: $selectedUser) { user in
            ChangePasswordSheet(user: user, userService: userService)
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

struct UserRowView: View {
    let user: NtfyUser
    let currentUsername: String
    let onDelete: (NtfyUser) -> Void
    let onChangeRole: (NtfyUser, UserRole) -> Void
    let onChangePassword: (NtfyUser) -> Void

    var body: some View {
        HStack(spacing: 12) {
            // User Icon
            ZStack {
                Circle()
                    .fill(roleColor)
                    .frame(width: 36, height: 36)

                Image(systemName: user.isAdmin ? "crown.fill" : "person.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(user.username)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if user.username == currentUsername {
                        Text("(You)")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }

                    if user.isSystemUser {
                        Text("System")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(4)
                    }

                    Spacer()
                }

                HStack(spacing: 16) {
                    Label(user.displayRole, systemImage: user.isAdmin ? "crown" : "person")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if user.hasWildcardAccess {
                        Label("All Topics", systemImage: "globe")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if user.topicCount > 0 {
                        Label("\(user.topicCount) Topics", systemImage: "tag")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            }

            Spacer()

            // Actions
            HStack(spacing: 8) {
                // Role Change Menu
                if !user.isSystemUser {
                    Menu {
                        ForEach(UserRole.allCases, id: \.self) { role in
                            Button(role.displayName) {
                                onChangeRole(user, role)
                            }
                            .disabled(role.rawValue == user.role)
                        }
                    } label: {
                        Label("Role", systemImage: "person.badge.key")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                // Password Change
                if !user.isSystemUser {
                    Button("Password") {
                        onChangePassword(user)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                // Delete User
                if !user.isSystemUser && user.username != currentUsername {
                    Button("Delete") {
                        onDelete(user)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundColor(.red)
                }
            }
        }
        .padding(12)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }

    private var roleColor: Color {
        switch user.role.lowercased() {
        case "admin":
            return Color.red
        case "user":
            return Color.blue
        case "anonymous":
            return Color.gray
        default:
            return Color.secondary
        }
    }
}

struct ChangePasswordSheet: View {
    let user: NtfyUser
    @ObservedObject var userService: UserManagementService
    @Environment(\.dismiss) private var dismiss

    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isChanging: Bool = false
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Change Password")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .disabled(isChanging)
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("User: \(user.username)")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("New Password")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    SecureField("Enter new password", text: $newPassword)
                        .textFieldStyle(.roundedBorder)
                        .disabled(isChanging)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm Password")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    SecureField("Confirm new password", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
                        .disabled(isChanging)
                }

                if !passwordsMatch && !confirmPassword.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("Passwords do not match")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                if !isValidPassword && !newPassword.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("Password must be at least 8 characters long")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            // Footer
            HStack {
                Spacer()

                if isChanging {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Changing password...")
                            .foregroundColor(.secondary)
                    }
                } else {
                    Button("Change Password") {
                        changePassword()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canChangePassword)
                }
            }
        }
        .padding(20)
        .frame(width: 400, height: 300)
        .background(Color.theme.windowBackground)
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private var passwordsMatch: Bool {
        newPassword == confirmPassword
    }

    private var isValidPassword: Bool {
        newPassword.count >= 8
    }

    private var canChangePassword: Bool {
        isValidPassword && passwordsMatch && !isChanging
    }

    private func changePassword() {
        isChanging = true

        Task {
            do {
                try await userService.changeUserPassword(user, newPassword: newPassword)

                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isChanging = false
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

#Preview {
    UserManagementView(settings: .default)
}