import SwiftUI

struct ProfileEditorView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    let profile: Profile
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var phone: String
    @State private var gradeText: String
    @State private var selectedMemberRole: MemberRole?
    @State private var emergencyContactName: String
    @State private var emergencyContactPhone: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    @FocusState private var focusedField: Field?
    
    private enum Field {
        case firstName, lastName, phone, grade, emergencyName, emergencyPhone
    }
    
    init(profile: Profile) {
        self.profile = profile
        _firstName = State(initialValue: profile.firstName ?? "")
        _lastName = State(initialValue: profile.lastName ?? "")
        _phone = State(initialValue: profile.phone ?? "")
        _gradeText = State(initialValue: profile.grade.map { String($0) } ?? "")
        _selectedMemberRole = State(initialValue: profile.memberRole)
        _emergencyContactName = State(initialValue: profile.emergencyContactName ?? "")
        _emergencyContactPhone = State(initialValue: profile.emergencyContactPhone ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(L10n.Settings.profileDetailsTitle) {
                    TextField(L10n.Settings.profileFirstName, text: $firstName)
                        .textContentType(.givenName)
                        .submitLabel(.next)
                        .focused($focusedField, equals: .firstName)
                    
                    TextField(L10n.Settings.profileLastName, text: $lastName)
                        .textContentType(.familyName)
                        .submitLabel(.next)
                        .focused($focusedField, equals: .lastName)
                    
                    Text(profile.email)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .font(.callout)
                        .accessibilityLabel(L10n.Settings.profileEmailLabel(profile.email))
                }
                
                Section(L10n.Settings.profileContactTitle) {
                    TextField(L10n.Settings.profilePhone, text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .focused($focusedField, equals: .phone)
                    
                    TextField(L10n.Settings.profileGrade, text: $gradeText)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .grade)
                        .accessibilityHint(L10n.Settings.profileGradeHint)
                }
                
                Section("Team Information") {
                    // Show member role picker (driver, programmer, builder, etc.)
                    Picker(L10n.Settings.profileMemberRole, selection: $selectedMemberRole) {
                        Text(L10n.Settings.profileMemberRoleNone).tag(MemberRole?.none)
                        ForEach(MemberRole.allCases, id: \.self) { role in
                            Text(role.displayName).tag(Optional(role))
                        }
                    }
                    .pickerStyle(.menu)
                    
                    // Show team role but don't allow editing (only coach can assign)
                    if let teamRole = profile.teamRole {
                        HStack {
                            Text("Team Role")
                            Spacer()
                            Text(teamRole.displayName)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Team Role")
                        .accessibilityValue(teamRole.displayName)
                    }
                }
                
                Section(L10n.Settings.profileEmergencyTitle) {
                    TextField(L10n.Settings.profileEmergencyName, text: $emergencyContactName)
                        .focused($focusedField, equals: .emergencyName)
                    
                    TextField(L10n.Settings.profileEmergencyPhone, text: $emergencyContactPhone)
                        .keyboardType(.phonePad)
                        .focused($focusedField, equals: .emergencyPhone)
                }
                
                if let errorMessage {
                    Section {
                        Label {
                            Text(errorMessage)
                                .foregroundColor(DesignSystem.Colors.error)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(DesignSystem.Colors.error)
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .disabled(isSaving)
            .navigationTitle(L10n.Settings.profileEditorTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.General.actionClose) {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveProfile) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text(L10n.Settings.profileSaveAction)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
        .navigationViewStyle(.stack)
        .interactiveDismissDisabled(isSaving)
    }
    
    private func saveProfile() {
        guard let currentProfile = authService.currentUser, currentProfile.id == profile.id else {
            errorMessage = L10n.Settings.profileUnavailable
            return
        }
        
        focusedField = nil
        isSaving = true
        errorMessage = nil
        
        let sanitizedFirst = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedLast = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedEmergencyPhone = emergencyContactPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedEmergencyName = emergencyContactName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let gradeValue: Int? = {
            let trimmed = gradeText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, let value = Int(trimmed), value > 0 else { return nil }
            return value
        }()
        
        let updatedProfile = Profile(
            id: profile.id,
            teamId: profile.teamId,
            role: profile.role,
            teamRole: profile.teamRole,
            firstName: sanitizedFirst.isEmpty ? nil : sanitizedFirst,
            lastName: sanitizedLast.isEmpty ? nil : sanitizedLast,
            email: profile.email,
            phone: sanitizedPhone.isEmpty ? nil : sanitizedPhone,
            grade: gradeValue,
            memberRole: selectedMemberRole,
            experienceBadges: profile.experienceBadges,
            emergencyContactName: sanitizedEmergencyName.isEmpty ? nil : sanitizedEmergencyName,
            emergencyContactPhone: sanitizedEmergencyPhone.isEmpty ? nil : sanitizedEmergencyPhone,
            passwordResetVerified: profile.passwordResetVerified,
            createdAt: profile.createdAt,
            updatedAt: Date()
        )
        
        Task {
            do {
                try await authService.updateProfile(updatedProfile)
                DesignSystem.Haptics.notify(.success)
                isSaving = false
                dismiss()
            } catch {
                DesignSystem.Haptics.notify(.error)
                errorMessage = error.localizedDescription
                isSaving = false
            }
        }
    }
}

#if DEBUG
struct ProfileEditorView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileEditorView(profile: .sample)
            .environmentObject(AuthService())
    }
}
#endif

