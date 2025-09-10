import SwiftUI

struct EditMemberView: View {
    let member: Member
    @Environment(\.dismiss) private var dismiss
    
    // Get the full member data from Broomfield data
    private var fullMemberData: BroomfieldMember? {
        let data = BroomfieldDataLoader.shared.loadBroomfieldData()
        // Match by name since the ID conversion from string to UUID creates random UUIDs
        return data?.members.first { $0.name == member.name }
    }
    
    // MARK: - State Variables (similar to AddNewMemberView)
    @State private var profileImage: Image? = nil
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage? = nil
    @State private var communityID = ""
    @State private var memberID = ""
    @State private var profilePhotoFileName: String = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var address = ""
    @State private var occupation = ""
    @State private var phoneNumber = ""
    @State private var dateOfBirth = Date()
    @State private var memberSince = Date()
    @State private var gender: AddNewMemberView.Gender = .male
    @State private var colorTag: ColorTag = .none
    @State private var birthdayPreference: AddNewMemberView.BirthdayPreference = .gregorian
    @State private var tribe: AddNewMemberView.Tribe = .yisroel
    @State private var aliyaName = ""
    @State private var instagram = ""
    @State private var tiktok = ""
    @State private var linkedin = ""
    @State private var facebook = ""
    @State private var weblinks: [String] = []
    @State private var household: [AddNewMemberView.HouseholdMember] = []
    @State private var newHouseholdName = ""
    @State private var newHouseholdRelationship = ""
    @FocusState private var focusedField: AddNewMemberView.Field?
    
    // State for significant dates and notes
    @State private var significantDates: [SignificantDate] = []
    @State private var notes: [NoteEntry] = []
    
    // State for donations
    @State private var monthlyMembership: String = ""
    @State private var collectionDay: String = ""
    @State private var membershipEnds: String = ""
    @State private var pastDonations: String = ""
    @State private var paymentMethod: String = ""
    @State private var cardOnFile: String = ""
    @State private var fullCardNumber: String = ""
    @State private var showFullCard: Bool = false
    @State private var cardExpiration: String = ""
    @State private var cardholderName: String = ""
    @State private var cardSecurityCode: String = ""
    @State private var cardZipcode: String = ""
    @State private var metAt = ""
    @FocusState private var isCardNumberFocused: Bool
    @State private var displayedCardNumber: String = ""
    @StateObject private var keyboard = KeyboardObserver()
    
    // Custom fields state
    @State private var customFields: [CustomField] = []
    
    // Section open/close state
    @State private var openSection: AddNewMemberView.Section? = .personalInfo
    
    // Additional fields
    @State private var middleName = ""
    @State private var nickname = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var apartment = ""
    @State private var country = ""
    @State private var maritalStatus = ""
    @State private var hasChildren = false
    @State private var jewishStatus: AddNewMemberView.JewishStatus = .yes
    @State private var jewishMemberName = ""
    @State private var mothersHebrewName = ""
    @State private var fathersHebrewName = ""
    @State private var tags: [String] = []
    
    // Associates
    @State private var associates: [AddNewMemberView.AssociateDraft] = []
    @State private var showLabelSheet: Bool = false
    @State private var showMemberSheet: Bool = false
    @State private var editingAssociateIndex: Int? = nil
    @FocusState private var focusedAssociateIndex: Int?
    @State private var isProgrammaticAssociateUpdate = false
    
    // List-related state variables
    @State private var selectedLists: Set<UUID> = []
    @State private var availableLists: [MemberList] = []
    @State private var showingCreateListSheet = false
    @State private var newListName = ""
    @State private var newListDescription = ""
    @State private var listCreationError: String?
    
    // New state variables for PersonalInfoSection
    @State private var newWeblink: String = ""
    @FocusState private var isWeblinkInputFocused: Bool
    
    // Helper functions to break up complex expressions
    private var removeHouseholdMemberClosure: (AddNewMemberView.HouseholdMember) -> Void {
        return { member in
            if let index = household.firstIndex(where: { $0.id == member.id }) {
                removeHouseholdMember(at: index)
            }
        }
    }
    
    private var updateHouseholdMemberClosure: (AddNewMemberView.HouseholdMember, String?, String?) -> Void {
        return { member, name, relationship in
            if let index = household.firstIndex(where: { $0.id == member.id }) {
                updateHouseholdMember(at: index, name: name ?? "", relationship: relationship ?? "")
            }
        }
    }
    
    private var personalInfoSection: some View {
        AddNewMemberView.PersonalInfoSection(
            firstName: $firstName,
            lastName: $lastName,
            email: $email,
            address: $address,
            occupation: $occupation,
            phoneNumber: $phoneNumber,
            dateOfBirth: $dateOfBirth,
            memberSince: $memberSince,
            gender: $gender,
            colorTag: $colorTag,
            birthdayPreference: $birthdayPreference,
            focusedField: $focusedField,
            metAt: $metAt,
            profileImage: $profileImage,
            showingImagePicker: $showingImagePicker,
            inputImage: $inputImage,
            profilePhotoFileName: $profilePhotoFileName,
            tribe: $tribe,
            aliyaName: $aliyaName,
            instagram: $instagram,
            tiktok: $tiktok,
            linkedin: $linkedin,
            facebook: $facebook,
            weblinks: $weblinks,
            household: $household,
            newHouseholdName: $newHouseholdName,
            newHouseholdRelationship: $newHouseholdRelationship,
            addHouseholdMember: addHouseholdMember,
            removeHouseholdMember: removeHouseholdMemberClosure,
            updateHouseholdMember: updateHouseholdMemberClosure,
            openSection: $openSection,
            middleName: $middleName,
            nickname: $nickname,
            city: $city,
            state: $state,
            zipCode: $zipCode,
            apartment: $apartment,
            country: $country,
            maritalStatus: $maritalStatus,
            hasChildren: $hasChildren,
            jewishStatus: $jewishStatus,
            mothersHebrewName: $mothersHebrewName,
            fathersHebrewName: $fathersHebrewName,
            associates: $associates,
            showLabelSheet: $showLabelSheet,
            showMemberSheet: $showMemberSheet,
            editingAssociateIndex: $editingAssociateIndex,
            focusedAssociateIndex: $focusedAssociateIndex,
            isProgrammaticAssociateUpdate: $isProgrammaticAssociateUpdate,
            tags: $tags
        )
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack {
                    personalInfoSection
                    
                    SignificantDatesSection(
                        dates: $significantDates,
                        openSection: $openSection
                    )
                    
                    CustomFieldsSection(
                        customFields: $customFields,
                        openSection: $openSection
                    )
                    
                    DonationsSection(
                        monthlyMembership: $monthlyMembership,
                        collectionDay: $collectionDay,
                        membershipEnds: $membershipEnds,
                        pastDonations: $pastDonations,
                        paymentMethod: $paymentMethod,
                        cardOnFile: $cardOnFile,
                        fullCardNumber: $fullCardNumber,
                        cardExpiration: $cardExpiration,
                        cardholderName: $cardholderName,
                        cardSecurityCode: $cardSecurityCode,
                        cardZipcode: $cardZipcode,
                        openSection: $openSection
                    )
                    
                    NotesSection(
                        notes: $notes,
                        firstName: firstName,
                        openSection: $openSection
                    )
                    
                    ListsSection(
                        selectedLists: $selectedLists,
                        availableLists: $availableLists,
                        openSection: $openSection,
                        showingCreateListSheet: $showingCreateListSheet,
                        newListName: $newListName,
                        newListDescription: $newListDescription
                    )
                }
            }
            
            // Bottom action buttons
            VStack {
                Spacer()
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                    
                    Button("Save Changes") {
                        saveChanges()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(GlobalTheme.brandPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding()
                .background(Color.white)
            }
        }
        .navigationTitle("Edit Member")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadMemberData()
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $inputImage)
        }
        .onChange(of: inputImage) { _, newImage in
            if let newImage = newImage {
                profileImage = Image(uiImage: newImage)
            }
        }
        .sheet(isPresented: $showingCreateListSheet) {
            CreateListSheet(
                newListName: $newListName,
                newListDescription: $newListDescription,
                errorMessage: $listCreationError,
                onSave: {
                    createNewList()
                }
            )
        }
    }
    
    // MARK: - Data Loading
    private func loadMemberData() {
        guard let fullData = fullMemberData else { return }
        
        // Load basic information
        firstName = fullData.firstName ?? ""
        lastName = fullData.lastName ?? ""
        email = fullData.email ?? ""
        address = fullData.address ?? ""
        occupation = fullData.occupation ?? ""
        phoneNumber = fullData.phone ?? ""
        middleName = fullData.middleName ?? ""
        nickname = fullData.nickname ?? ""
        city = fullData.city ?? ""
        state = fullData.state ?? ""
        zipCode = fullData.zipCode ?? ""
        apartment = fullData.apartmentNumber ?? ""
        maritalStatus = fullData.maritalStatus ?? ""
        hasChildren = fullData.hasChildren == "true"
        jewishMemberName = fullData.jewishMemberName ?? ""
        mothersHebrewName = fullData.motherHebrewName ?? ""
        fathersHebrewName = fullData.fatherHebrewName ?? ""
        aliyaName = fullData.aliyaName ?? ""
        instagram = fullData.instagram ?? ""
        tiktok = fullData.tiktok ?? ""
        linkedin = fullData.linkedin ?? ""
        facebook = fullData.facebook ?? ""
        metAt = fullData.metAt ?? ""
        
        // Load membership information
        monthlyMembership = fullData.monthlyMembership ?? ""
        collectionDay = fullData.collectionDay ?? ""
        membershipEnds = fullData.membershipEnds ?? ""
        pastDonations = fullData.pastDonations ?? ""
        paymentMethod = fullData.paymentMethod ?? ""
        
        // Load enums
        if let genderString = fullData.gender {
            gender = AddNewMemberView.Gender(rawValue: genderString.lowercased()) ?? .male
        }
        
        if let tribeString = fullData.tribe {
            tribe = AddNewMemberView.Tribe(rawValue: tribeString.lowercased()) ?? .yisroel
        }
        
        if let birthdayPrefString = fullData.birthdayPreference {
            birthdayPreference = AddNewMemberView.BirthdayPreference(rawValue: birthdayPrefString) ?? .gregorian
        }
        
        if let jewishStatusString = fullData.isJewish {
            jewishStatus = AddNewMemberView.JewishStatus(rawValue: jewishStatusString) ?? .yes
        }
        
        // Load color tag
        colorTag = Rolo.colorTag(from: fullData.colorTag)
        
        // Load dates
        if let dateOfBirthString = fullData.dateOfBirth, !dateOfBirthString.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            dateOfBirth = formatter.date(from: dateOfBirthString) ?? Date()
        }
        
        if let memberSinceString = fullData.memberSince, !memberSinceString.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            memberSince = formatter.date(from: memberSinceString) ?? Date()
        }
        
        // Load web links
        if let webLinksString = fullData.webLinks, !webLinksString.isEmpty {
            weblinks = webLinksString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        }
        
        // Load household members
        if let householdString = fullData.householdMembers, !householdString.isEmpty {
            // Parse household members (this is a simplified parser)
            let components = householdString.components(separatedBy: ",")
            household = components.map { component in
                let parts = component.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " - ")
                return AddNewMemberView.HouseholdMember(
                    name: parts.first ?? "",
                    relationship: parts.count > 1 ? parts[1] : ""
                )
            }
        }
        
        // Load tags
        if let tagsString = fullData.tags, !tagsString.isEmpty {
            tags = tagsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        }
        
        // Load notes
        if let noteString = fullData.note, !noteString.isEmpty {
            notes = [NoteEntry(title: "Note", note: noteString)]
        }
        
        if let notesString = fullData.notes, !notesString.isEmpty {
            if notes.isEmpty {
                notes = [NoteEntry(title: "Additional Notes", note: notesString)]
            } else {
                notes.append(NoteEntry(title: "Additional Notes", note: notesString))
            }
        }
    }
    
    // MARK: - Helper Functions
    private func saveChanges() {
        // TODO: Implement save functionality
        // This would typically involve updating the member data in the backend
        print("Saving changes for member: \(member.name)")
        dismiss()
    }
    
    // MARK: - Household Member Functions
    private func addHouseholdMember() {
        let newMember = AddNewMemberView.HouseholdMember(name: newHouseholdName, relationship: newHouseholdRelationship)
        household.append(newMember)
        newHouseholdName = ""
        newHouseholdRelationship = ""
    }
    
    private func removeHouseholdMember(at index: Int) {
        household.remove(at: index)
    }
    
    private func updateHouseholdMember(at index: Int, name: String, relationship: String) {
        household[index].name = name
        household[index].relationship = relationship
    }
    
    // MARK: - Associate Functions
    private func addAssociate() {
        let newAssociate = AddNewMemberView.AssociateDraft()
        associates.append(newAssociate)
    }
    
    private func removeAssociate(at index: Int) {
        associates.remove(at: index)
    }
    
    private func updateAssociate(at index: Int, label: String, relativeName: String, linkedMemberID: String?) {
        associates[index].label = label
        associates[index].relativeName = relativeName
        associates[index].linkedMemberID = linkedMemberID
    }
    
    // MARK: - Weblink Functions
    private func addWeblink() {
        if !newWeblink.isEmpty {
            weblinks.append(newWeblink)
            newWeblink = ""
        }
    }
    
    private func removeWeblink(at index: Int) {
        weblinks.remove(at: index)
    }
    
    // MARK: - Significant Date Functions
    private func addSignificantDate() {
        let newDate = SignificantDate(occasion: "", note: "", eventDate: Date(), hebrewDate: "")
        significantDates.append(newDate)
    }
    
    private func removeSignificantDate(at index: Int) {
        significantDates.remove(at: index)
    }
    
    private func updateSignificantDate(at index: Int, occasion: String, note: String, eventDate: Date, hebrewDate: String) {
        significantDates[index].occasion = occasion
        significantDates[index].note = note
        significantDates[index].eventDate = eventDate
        significantDates[index].hebrewDate = hebrewDate
    }
    
    // MARK: - Custom Field Functions
    private func addCustomField() {
        let newField = CustomField(label: "", value: "")
        customFields.append(newField)
    }
    
    private func removeCustomField(at index: Int) {
        customFields.remove(at: index)
    }
    
    private func updateCustomField(at index: Int, name: String, type: CustomFieldType, stringValue: String, numberValue: String, dateValue: Date, boolValue: Bool) {
        customFields[index].label = name
        customFields[index].value = stringValue
    }
    
    // MARK: - Note Functions
    private func addNote() {
        let newNote = NoteEntry(title: "", note: "")
        notes.append(newNote)
    }
    
    private func removeNote(at index: Int) {
        notes.remove(at: index)
    }
    
    private func updateNote(at index: Int, title: String, note: String) {
        notes[index].title = title
        notes[index].note = note
    }
    
    // MARK: - List Functions
    private func createNewList() {
        let trimmedName = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Clear previous error
        listCreationError = nil
        
        // Validation checks
        guard !trimmedName.isEmpty else {
            listCreationError = "List name cannot be empty"
            return
        }
        
        guard !availableLists.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) else {
            listCreationError = "A list with this name already exists"
            return
        }
        
        let newList = MemberList(
            id: UUID(),
            communityId: UUID(),
            name: trimmedName,
            description: newListDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : newListDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            color: "#007AFF",
            emoji: nil,
            isDefault: false,
            createdBy: UUID(),
            createdAt: Date(),
            updatedAt: Date(),
            memberCount: 0
        )
        
        availableLists.append(newList)
        
        // Reset form
        newListName = ""
        newListDescription = ""
        showingCreateListSheet = false
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
    
    return NavigationStack {
        EditMemberView(member: sampleMember)
    }
}
