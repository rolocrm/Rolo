import SwiftUI

struct MemberProfilePage: View {
    let member: Member
    @State private var showingEditMember = false
    @Environment(\.dismiss) private var dismiss
    
    // Get the full member data from Broomfield data
    private var fullMemberData: BroomfieldMember? {
        let data = BroomfieldDataLoader.shared.loadBroomfieldData()
        // Match by name since the ID conversion from string to UUID creates random UUIDs
        let found = data?.members.first { $0.name == member.name }
        print("DEBUG: Looking for member with name: \(member.name)")
        print("DEBUG: Found member data: \(found != nil ? "YES" : "NO")")
        if let found = found {
            print("DEBUG: Found member - firstName: \(found.firstName ?? "nil"), lastName: \(found.lastName ?? "nil"), email: \(found.email ?? "nil")")
        }
        return found
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with profile image and basic info
                    ProfileHeaderSection(member: member, fullMemberData: fullMemberData)
                    
                    // Membership Status Section
                    MembershipStatusSection(member: member, fullMemberData: fullMemberData)
                    
                    // Personal Information Section
                    MemberPersonalInfoSection(member: member, fullMemberData: fullMemberData)
                    
                    // Contact Information Section
                    ContactInfoSection(member: member, fullMemberData: fullMemberData)
                    
                    // Jewish Information Section
                    JewishInfoSection(member: member, fullMemberData: fullMemberData)
                    
                    // Social Media Section
                    MemberSocialMediaSection(member: member, fullMemberData: fullMemberData)
                    
                    // Family & Household Section
                    FamilyHouseholdSection(member: member, fullMemberData: fullMemberData)
                    
                    // Notes Section
                    MemberNotesSection(member: member, fullMemberData: fullMemberData)
                    
                    Spacer(minLength: 100)
                }
            }
            .navigationTitle("Member Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditMember = true
                    }
                    .foregroundColor(GlobalTheme.brandPrimary)
                }
            }
        }
        .sheet(isPresented: $showingEditMember) {
            NavigationStack {
                EditMemberView(member: member)
            }
        }
    }
}

// MARK: - Profile Header Section
struct ProfileHeaderSection: View {
    let member: Member
    let fullMemberData: BroomfieldMember?
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Image
            ZStack(alignment: .bottomTrailing) {
                ProfileFromInitials(name: member.name, size: 100, initials: member.initials)
                    .frame(width: 100, height: 100)
                    .aspectRatio(contentMode: .fill)
                
                Image(member.profileImageName ?? "Default Profile Pic icon")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .background(Circle().fill(Color(.sRGB, red: 0.06, green: 0.12, blue: 0.11, opacity: 1)))
                    .opacity(member.hasProfileImage ? 1 : 0)
                
                // Color tag overlay
                Circle()
                    .fill(member.colorTag.color)
                    .frame(width: 24, height: 24)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .opacity(member.colorTag == .none ? 0 : 1)
                    .offset(x: 4, y: 4)
            }
            
            // Name and basic info
            VStack(spacing: 4) {
                Text(member.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(GlobalTheme.brandPrimary)
                
                if let occupation = fullMemberData?.occupation, !occupation.isEmpty {
                    Text(occupation)
                        .font(.subheadline)
                        .foregroundColor(GlobalTheme.coloredGrey)
                }
                
                if let memberSince = fullMemberData?.memberSince, !memberSince.isEmpty {
                    Text("Member since \(memberSince)")
                        .font(.caption)
                        .foregroundColor(GlobalTheme.coloredGrey)
                }
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
    }
}

// MARK: - Membership Status Section
struct MembershipStatusSection: View {
    let member: Member
    let fullMemberData: BroomfieldMember?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Membership Status")
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: member.isMember ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(member.isMember ? GlobalTheme.highlightGreen : .red)
                        Text(member.isMember ? "Active Member" : "Not a Member")
                            .font(.headline)
                            .foregroundColor(GlobalTheme.brandPrimary)
                    }
                    
                    if member.isMember {
                        if let amount = member.membershipAmount {
                            HStack {
                                Text("Membership Amount:")
                                    .font(.subheadline)
                                    .foregroundColor(GlobalTheme.coloredGrey)
                                Spacer()
                                Text("$\(String(format: "%.0f", amount))")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(GlobalTheme.highlightGreen)
                            }
                        }
                        
                        if let monthly = fullMemberData?.monthlyMembership, !monthly.isEmpty {
                            HStack {
                                Text("Monthly Membership:")
                                    .font(.subheadline)
                                    .foregroundColor(GlobalTheme.coloredGrey)
                                Spacer()
                                Text(monthly)
                                    .font(.subheadline)
                                    .foregroundColor(GlobalTheme.brandPrimary)
                            }
                        }
                        
                        if let collectionDay = fullMemberData?.collectionDay, !collectionDay.isEmpty {
                            HStack {
                                Text("Collection Day:")
                                    .font(.subheadline)
                                    .foregroundColor(GlobalTheme.coloredGrey)
                                Spacer()
                                Text(collectionDay)
                                    .font(.subheadline)
                                    .foregroundColor(GlobalTheme.brandPrimary)
                            }
                        }
                        
                        if let membershipEnds = fullMemberData?.membershipEnds, !membershipEnds.isEmpty && membershipEnds != "n/a" {
                            HStack {
                                Text("Membership Ends:")
                                    .font(.subheadline)
                                    .foregroundColor(GlobalTheme.coloredGrey)
                                Spacer()
                                Text(membershipEnds)
                                    .font(.subheadline)
                                    .foregroundColor(GlobalTheme.brandPrimary)
                            }
                        }
                        
                        if let paymentMethod = fullMemberData?.paymentMethod, !paymentMethod.isEmpty {
                            HStack {
                                Text("Payment Method:")
                                    .font(.subheadline)
                                    .foregroundColor(GlobalTheme.coloredGrey)
                                Spacer()
                                Text(paymentMethod)
                                    .font(.subheadline)
                                    .foregroundColor(GlobalTheme.brandPrimary)
                            }
                        }
                    }
                }
                Spacer()
            }
        }
        .padding()
        .background(Color.white)
    }
}

// MARK: - Personal Information Section
struct MemberPersonalInfoSection: View {
    let member: Member
    let fullMemberData: BroomfieldMember?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Personal Information")
            
            VStack(spacing: 8) {
                if let firstName = fullMemberData?.firstName, !firstName.isEmpty {
                    InfoRow(label: "First Name", value: firstName)
                }
                
                if let middleName = fullMemberData?.middleName, !middleName.isEmpty {
                    InfoRow(label: "Middle Name", value: middleName)
                }
                
                if let lastName = fullMemberData?.lastName, !lastName.isEmpty {
                    InfoRow(label: "Last Name", value: lastName)
                }
                
                if let nickname = fullMemberData?.nickname, !nickname.isEmpty {
                    InfoRow(label: "Nickname", value: nickname)
                }
                
                if let dateOfBirth = fullMemberData?.dateOfBirth, !dateOfBirth.isEmpty {
                    InfoRow(label: "Date of Birth", value: dateOfBirth)
                }
                
                if let gender = fullMemberData?.gender, !gender.isEmpty {
                    InfoRow(label: "Gender", value: gender)
                }
                
                if let maritalStatus = fullMemberData?.maritalStatus, !maritalStatus.isEmpty {
                    InfoRow(label: "Marital Status", value: maritalStatus)
                }
                
                if let hasChildren = fullMemberData?.hasChildren, !hasChildren.isEmpty {
                    InfoRow(label: "Has Children", value: hasChildren)
                }
            }
        }
        .padding()
        .background(Color.white)
    }
}

// MARK: - Contact Information Section
struct ContactInfoSection: View {
    let member: Member
    let fullMemberData: BroomfieldMember?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Contact Information")
            
            VStack(spacing: 8) {
                if !member.email.isEmpty {
                    InfoRow(label: "Email", value: member.email)
                }
                
                if let phone = fullMemberData?.phone, !phone.isEmpty {
                    InfoRow(label: "Phone", value: phone)
                }
                
                if let address = fullMemberData?.address, !address.isEmpty {
                    InfoRow(label: "Address", value: address)
                }
                
                if let apartmentNumber = fullMemberData?.apartmentNumber, !apartmentNumber.isEmpty {
                    InfoRow(label: "Apartment", value: apartmentNumber)
                }
                
                if let city = fullMemberData?.city, !city.isEmpty {
                    InfoRow(label: "City", value: city)
                }
                
                if let state = fullMemberData?.state, !state.isEmpty {
                    InfoRow(label: "State", value: state)
                }
                
                if let zipCode = fullMemberData?.zipCode, !zipCode.isEmpty {
                    InfoRow(label: "Zip Code", value: zipCode)
                }
            }
        }
        .padding()
        .background(Color.white)
    }
}

// MARK: - Jewish Information Section
struct JewishInfoSection: View {
    let member: Member
    let fullMemberData: BroomfieldMember?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Jewish Information")
            
            VStack(spacing: 8) {
                if let jewishMemberName = fullMemberData?.jewishMemberName, !jewishMemberName.isEmpty {
                    InfoRow(label: "Jewish Name", value: jewishMemberName)
                }
                
                if let motherHebrewName = fullMemberData?.motherHebrewName, !motherHebrewName.isEmpty {
                    InfoRow(label: "Mother's Hebrew Name", value: motherHebrewName)
                }
                
                if let fatherHebrewName = fullMemberData?.fatherHebrewName, !fatherHebrewName.isEmpty {
                    InfoRow(label: "Father's Hebrew Name", value: fatherHebrewName)
                }
                
                if let aliyaName = fullMemberData?.aliyaName, !aliyaName.isEmpty {
                    InfoRow(label: "Aliya Name", value: aliyaName)
                }
                
                if let tribe = fullMemberData?.tribe, !tribe.isEmpty {
                    InfoRow(label: "Tribe", value: tribe)
                }
                
                if let isJewish = fullMemberData?.isJewish, !isJewish.isEmpty {
                    InfoRow(label: "Jewish", value: isJewish)
                }
                
                if let birthdayPreference = fullMemberData?.birthdayPreference, !birthdayPreference.isEmpty {
                    InfoRow(label: "Birthday Preference", value: birthdayPreference)
                }
            }
        }
        .padding()
        .background(Color.white)
    }
}

// MARK: - Social Media Section
struct MemberSocialMediaSection: View {
    let member: Member
    let fullMemberData: BroomfieldMember?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Social Media & Web")
            
            VStack(spacing: 8) {
                if let instagram = fullMemberData?.instagram, !instagram.isEmpty {
                    InfoRow(label: "Instagram", value: instagram)
                }
                
                if let tiktok = fullMemberData?.tiktok, !tiktok.isEmpty {
                    InfoRow(label: "TikTok", value: tiktok)
                }
                
                if let linkedin = fullMemberData?.linkedin, !linkedin.isEmpty {
                    InfoRow(label: "LinkedIn", value: linkedin)
                }
                
                if let facebook = fullMemberData?.facebook, !facebook.isEmpty {
                    InfoRow(label: "Facebook", value: facebook)
                }
                
                if let webLinks = fullMemberData?.webLinks, !webLinks.isEmpty {
                    InfoRow(label: "Web Links", value: webLinks)
                }
            }
        }
        .padding()
        .background(Color.white)
    }
}

// MARK: - Family & Household Section
struct FamilyHouseholdSection: View {
    let member: Member
    let fullMemberData: BroomfieldMember?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Family & Household")
            
            VStack(spacing: 8) {
                if let householdMembers = fullMemberData?.householdMembers, !householdMembers.isEmpty {
                    InfoRow(label: "Household Members", value: householdMembers)
                }
                
                if let metAt = fullMemberData?.metAt, !metAt.isEmpty {
                    InfoRow(label: "Met At", value: metAt)
                }
            }
        }
        .padding()
        .background(Color.white)
    }
}

// MARK: - Notes Section
struct MemberNotesSection: View {
    let member: Member
    let fullMemberData: BroomfieldMember?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Notes")
            
            VStack(spacing: 8) {
                if let note = fullMemberData?.note, !note.isEmpty {
                    InfoRow(label: "Note", value: note)
                }
                
                if let notes = fullMemberData?.notes, !notes.isEmpty {
                    InfoRow(label: "Additional Notes", value: notes)
                }
                
                if let tags = fullMemberData?.tags, !tags.isEmpty {
                    InfoRow(label: "Tags", value: tags)
                }
            }
        }
        .padding()
        .background(Color.white)
    }
}

// MARK: - Helper Views
struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(GlobalTheme.brandPrimary)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .font(.subheadline)
                .foregroundColor(GlobalTheme.coloredGrey)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(GlobalTheme.brandPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    let sampleMember = Member(
        id: UUID(),
        name: "John Doe",
        colorTag: .blue,
        email: "john.doe@example.com",
        isMember: true,
        membershipAmount: 500.0,
        hasProfileImage: false,
        profileImageName: nil
    )
    
    return MemberProfilePage(member: sampleMember)
}
