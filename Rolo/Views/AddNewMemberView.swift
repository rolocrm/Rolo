//
//  AddNewMemberView.swift
//  Rolo
//
//  Created by tsuriel.eichenstein on 5/5/25.
//

import SwiftUI

enum CustomFieldType: String, CaseIterable, Identifiable {
    case string = "String"
    case number = "Number"
    case date = "Date"
    case boolean = "Boolean"
    var id: String { rawValue }
}

struct FieldTypeInfo {
    let label: String
    let caption: String
}

let fieldTypeInfo: [CustomFieldType: FieldTypeInfo] = [
    .string: FieldTypeInfo(label: "Text", caption: "For words, sentences, or names"),
    .number: FieldTypeInfo(label: "Number", caption: "For amounts, ages, or counts"),
    .date: FieldTypeInfo(label: "Date", caption: "For birthdays or anniversaries"),
    .boolean: FieldTypeInfo(label: "Yes/No", caption: "For checkboxes or simple choices")
]

struct CustomFieldDraft {
    var name: String = ""
    var type: CustomFieldType = .string
    var stringValue: String = ""
    var numberValue: String = ""
    var dateValue: Date = Date()
    var boolValue: Bool = false
    var addAsDefault: Bool = false
}

struct AddNewMemberView: View {
    @Environment(\.dismiss) private var dismiss
    // MARK: - State Variables
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
    @State private var gender: Gender = .male
    @State private var colorTag: ColorTag = .none
    @State private var birthdayPreference: BirthdayPreference = .gregorian
    @State private var tribe: Tribe = .yisroel
    @State private var aliyaName = ""
    @State private var instagram = ""
    @State private var tiktok = ""
    @State private var linkedin = ""
    @State private var facebook = ""
    @State private var weblinks: [String] = []
    @State private var household: [HouseholdMember] = [HouseholdMember(name: "Mushky Cohen", relationship: "Wife")]
    @State private var newHouseholdName = ""
    @State private var newHouseholdRelationship = ""
    @FocusState private var focusedField: Field?
    // State for significant dates and notes
    @State private var significantDates: [SignificantDate] = [
        SignificantDate(occasion: "Fathers Yahrzeit", note: "דוד בן ישי", eventDate: Date(timeIntervalSince1970: 1288656000), hebrewDate: "20 Cheshvan, 5771")
    ]
    @State private var notes: [NoteEntry] = [NoteEntry(title: "", note: "")]
    // State for donations
    @State private var monthlyMembership: String = "$ 0.00"
    @State private var collectionDay: String = "24th of the month"
    @State private var membershipEnds: String = "n/a"
    @State private var pastDonations: String = "$ 0.00"
    @State private var paymentMethod: String = "Credit Card"
    @State private var cardOnFile: String = ""
    @State private var fullCardNumber: String = ""
    @State private var showFullCard: Bool = false
    @State private var cardExpiration: String = ""
    @State private var cardholderName: String = ""
    @State private var cardSecurityCode: String = ""
    @State private var cardZipcode: String = ""
    @State private var metAt: String = ""
    @FocusState private var isCardNumberFocused: Bool
    @State private var displayedCardNumber: String = ""
    @StateObject private var keyboard = KeyboardObserver()
    // Custom fields state
    @State private var customFields: [CustomField] = []
    // Section open/close state
    enum Section { case personalInfo, significantDates, customFields, donations, notes, lists }
    @State private var openSection: Section? = .personalInfo
    
    // Add new state variables for new fields
    @State private var middleName = ""
    @State private var nickname = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var apartment = ""
    @State private var country = ""
    @State private var maritalStatus = ""
    @State private var hasChildren = false
    @State private var jewishStatus: JewishStatus = .yes
    @State private var jewishMemberName = ""
    @State private var mothersHebrewName = ""
    @State private var fathersHebrewName = ""
    @State private var tags: [String] = []
    
    // New model
    struct AssociateDraft: Identifiable {
        let id = UUID()
        var label: String = ""
        var relativeName: String = ""
        var linkedMemberID: String? = nil
    }
    @State private var associates: [AssociateDraft] = []
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
    
    enum Gender: String, CaseIterable, Identifiable { case male, female; var id: String { rawValue } }
    enum BirthdayPreference: String, CaseIterable, Identifiable { case hebrew = "Hebrew date", gregorian = "Gregorian date"; var id: String { rawValue } }
    enum Tribe: String, CaseIterable, Identifiable { case cohen = "Cohen", levi = "Levi", yisroel = "Yisroel"; var id: String { rawValue } }
    enum JewishStatus: String, CaseIterable, Identifiable { case yes = "Yes", no = "No"; var id: String { rawValue } }
    struct HouseholdMember: Identifiable { let id = UUID(); var name: String; var relationship: String }
    enum Field: Hashable {
        case firstName, middleName, lastName, nickname, email, address, city, state, zipCode, apartment, country, occupation, phone, maritalStatus, hasChildren, metAt, jewishMemberName, tribe, dateOfBirth, memberSince, gender, colorTag, birthdayPreference, tags, aliyaName, mothersHebrewName, fathersHebrewName, instagram, tiktok, linkedin, facebook, newHouseholdName, newHouseholdRelationship
    }
    
    var body: some View {
        ZStack (alignment: .bottom) {
            ScrollView {
                VStack {
                    PersonalInfoSection(
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
                        removeHouseholdMember: removeHouseholdMember,
                        updateHouseholdMember: updateHouseholdMember,
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
                    SignificantDatesSection(dates: $significantDates, openSection: $openSection)
                    CustomFieldsSection(customFields: $customFields, openSection: $openSection)
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
                    NotesSection(notes: $notes, firstName: firstName, openSection: $openSection)
                    ListsSection(
                        selectedLists: $selectedLists,
                        availableLists: $availableLists,
                        openSection: $openSection,
                        showingCreateListSheet: $showingCreateListSheet,
                        newListName: $newListName,
                        newListDescription: $newListDescription
                    )
                    Spacer(minLength: 120)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Add Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(GlobalTheme.brandPrimary)
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                ImagePicker(image: $inputImage, profilePhotoFileName: $profilePhotoFileName)
            }
                .sheet(isPresented: $showingCreateListSheet) {
                    CreateListSheet(
                        newListName: $newListName,
                        newListDescription: $newListDescription,
                        errorMessage: $listCreationError,
                        onSave: createNewList
                    )
                }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .onTapGesture { focusedField = nil }
            if !keyboard.isKeyboardVisible {
                VStack {
                    RoloBigButton(
                        title: "Add member",
                        backgroundColor: GlobalTheme.brandPrimary,
                        foregroundColor: GlobalTheme.highlightGreen,
//                        strokeColor: GlobalTheme.highlightGreen,
                        action: {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                printResults()
                            }
                        }
                    )
                        .padding(.horizontal)
                        .padding(.bottom)
                        .padding(.top, 30)
                }
//                .background(
//                    ZStack {
//                        Color.white
//                            .mask(
//                                LinearGradient(
//                                    gradient: Gradient(stops: [
//                                        .init(color: .white.opacity(1), location: 0),
//                                        .init(color: .white.opacity(1), location: 0.75),
//                                        .init(color: .white.opacity(0), location: 1)
//                                    ]),
//                                    startPoint: .bottom,
//                                    endPoint: .top
//                                )
//                            )
//                    }
//                        .ignoresSafeArea(edges: .bottom)
//                )
            }
        }
        .sheet(isPresented: $showLabelSheet) {
            if let idx = editingAssociateIndex {
                LabelSelectionSheet(selectedLabel: $associates[idx].label)
            }
        }
        .sheet(isPresented: $showMemberSheet) {
            if let idx = editingAssociateIndex {
                MemberSelectionSheet(
                    associate: $associates[idx],
                    onSelect: {
                        isProgrammaticAssociateUpdate = true
                    },
                    onDismiss: {
                        isProgrammaticAssociateUpdate = false
                        focusedAssociateIndex = nil
                    }
                )
            }
        }
    }
    
    // MARK: - Personal Info Section
    struct PersonalInfoSection: View {
        @Binding var firstName: String
        @Binding var lastName: String
        @Binding var email: String
        @Binding var address: String
        @Binding var occupation: String
        @Binding var phoneNumber: String
        @Binding var dateOfBirth: Date
        @Binding var memberSince: Date
        @Binding var gender: AddNewMemberView.Gender
        @Binding var colorTag: ColorTag
        @Binding var birthdayPreference: AddNewMemberView.BirthdayPreference
        @FocusState.Binding var focusedField: AddNewMemberView.Field?
        @Binding var metAt: String
        @Binding var profileImage: Image?
        @Binding var showingImagePicker: Bool
        @Binding var inputImage: UIImage?
        @Binding var profilePhotoFileName: String
        @Binding var tribe: AddNewMemberView.Tribe
        @Binding var aliyaName: String
        @Binding var instagram: String
        @Binding var tiktok: String
        @Binding var linkedin: String
        @Binding var facebook: String
        @Binding var weblinks: [String]
        @Binding var household: [AddNewMemberView.HouseholdMember]
        @Binding var newHouseholdName: String
        @Binding var newHouseholdRelationship: String
        var addHouseholdMember: () -> Void
        var removeHouseholdMember: (AddNewMemberView.HouseholdMember) -> Void
        var updateHouseholdMember: (AddNewMemberView.HouseholdMember, String?, String?) -> Void
        @Binding var openSection: AddNewMemberView.Section?
        @Binding var middleName: String
        @Binding var nickname: String
        @Binding var city: String
        @Binding var state: String
        @Binding var zipCode: String
        @Binding var apartment: String
        @Binding var country: String
        @Binding var maritalStatus: String
        @Binding var hasChildren: Bool
        @Binding var jewishStatus: AddNewMemberView.JewishStatus
        @Binding var mothersHebrewName: String
        @Binding var fathersHebrewName: String
        @Binding var associates: [AssociateDraft]
        @Binding var showLabelSheet: Bool
        @Binding var showMemberSheet: Bool
        @Binding var editingAssociateIndex: Int?
        @FocusState.Binding var focusedAssociateIndex: Int?
        @Binding var isProgrammaticAssociateUpdate: Bool
        @Binding var tags: [String]
        
        var body: some View {
            VStack(alignment: .center) {
                // Profile Photo Section (always visible)
                VStack {
                    ZStack {
                        if let image = profileImage {
                            Button(action: { showingImagePicker = true }) {
                                image
                                    .resizable()
                                    .scaledToFill()
                            }
                        } else {
                            Button(action: { showingImagePicker = true }) {
                                Image(systemName: "plus")
                                    .resizable()
                                    .frame(width: 36, height: 36)
                                    .foregroundColor(GlobalTheme.highlightGreen)
                            }
                        }
                    }
                    .frame(width: 142, height: 142)
                    .background(GlobalTheme.brandPrimary)
                    .clipShape(Circle())
                    .padding(.top, 48)
                    .padding(.bottom, 12)
                    Text("Max profile \n photo size: 2MB")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom,20)
                
                ShareFormCard()
                
                Button(action: {
                    withAnimation {
                        openSection = openSection == .personalInfo ? nil : .personalInfo
                    }
                }) {
                    HStack {
                        Text("Personal info")
                            .font(.headline.bold())
                            .foregroundStyle(GlobalTheme.brandPrimary)
                            .padding(.vertical)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(GlobalTheme.brandPrimary)
                            .font(.system(size: 16, weight: .semibold))
                            .rotationEffect(.degrees(openSection == .personalInfo ? 0 : 90))
                            .animation(.easeInOut, value: openSection == .personalInfo)
                    }
                }
                
                // Personal Info
                VStack(alignment: .leading, spacing: 24) {
                    if openSection == .personalInfo {
                        VStack {
                            // Main personal info fields
                            VStack(alignment: .leading, spacing: 10) {
                                // Row 1: First name* | Middle name
                                HStack(spacing: 10) {
                                    VStack(alignment: .leading) {
                                        Text("First name*").font(.caption).foregroundColor(.gray)
                                        TextField("First name", text: $firstName)
                                            .textFieldStyle(.roundedBorder)
                                            .focused($focusedField, equals: .firstName)
                                    }
                                    VStack(alignment: .leading) {
                                        Text("Middle name").font(.caption).foregroundColor(.gray)
                                        TextField("Middle name", text: $middleName)
                                            .textFieldStyle(.roundedBorder)
                                            .focused($focusedField, equals: .middleName)
                                    }
                                }
                                // Row 2: Last name*
                                VStack(alignment: .leading) {
                                    Text("Last name*").font(.caption).foregroundColor(.gray)
                                    TextField("Last name", text: $lastName)
                                        .textFieldStyle(.roundedBorder)
                                        .focused($focusedField, equals: .lastName)
                                }
                                // Row 3: Nickname
                                VStack(alignment: .leading) {
                                    Text("Nickname").font(.caption).foregroundColor(.gray)
                                    TextField("Nickname", text: $nickname)
                                        .textFieldStyle(.roundedBorder)
                                        .focused($focusedField, equals: .nickname)
                                }
                                // Row 4: Phone | Email
                                HStack(spacing: 10) {
                                    VStack(alignment: .leading) {
                                        Text("Phone").font(.caption).foregroundColor(.gray)
                                        TextField("Phone", text: $phoneNumber)
                                            .textFieldStyle(.roundedBorder)
                                            .focused($focusedField, equals: .phone)
                                    }
                                    VStack(alignment: .leading) {
                                        Text("Email").font(.caption).foregroundColor(.gray)
                                        TextField("Email", text: $email)
                                            .textFieldStyle(.roundedBorder)
                                            .focused($focusedField, equals: .email)
                                    }
                                }
                                // Row 5: Occupation
                                VStack(alignment: .leading) {
                                    Text("Occupation").font(.caption).foregroundColor(.gray)
                                    TextField("Occupation", text: $occupation)
                                        .textFieldStyle(.roundedBorder)
                                        .focused($focusedField, equals: .occupation)
                                }
                                // Row 6: Address (2/3) | Apartment (1/3)
                                HStack(spacing: 10) {
                                    VStack(alignment: .leading) {
                                        Text("Address").font(.caption).foregroundColor(.gray)
                                        TextField("Address", text: $address)
                                            .textFieldStyle(.roundedBorder)
                                            .focused($focusedField, equals: .address)
                                    }
                                    .frame(maxWidth: .infinity)
                                    VStack(alignment: .leading) {
                                        Text("Apartment").font(.caption).foregroundColor(.gray)
                                        TextField("Apt", text: $apartment)
                                            .textFieldStyle(.roundedBorder)
                                            .focused($focusedField, equals: .apartment)
                                    }
                                    .frame(width: 100)
                                }
                                // Row 7: City | State | Zip code
                                HStack(spacing: 10) {
                                    VStack(alignment: .leading) {
                                        Text("City").font(.caption).foregroundColor(.gray)
                                        TextField("City", text: $city)
                                            .textFieldStyle(.roundedBorder)
                                            .focused($focusedField, equals: .city)
                                    }
                                    VStack(alignment: .leading) {
                                        Text("State").font(.caption).foregroundColor(.gray)
                                        TextField("State", text: $state)
                                            .textFieldStyle(.roundedBorder)
                                            .focused($focusedField, equals: .state)
                                    }
                                    VStack(alignment: .leading) {
                                        Text("Zip code").font(.caption).foregroundColor(.gray)
                                        TextField("Zip code", text: $zipCode)
                                            .textFieldStyle(.roundedBorder)
                                            .focused($focusedField, equals: .zipCode)
                                    }
                                }
                                // Row 8: Country (full width)
                                VStack(alignment: .leading) {
                                    Text("Country").font(.caption).foregroundColor(.gray)
                                    TextField("Country", text: $country)
                                        .textFieldStyle(.roundedBorder)
                                        .focused($focusedField, equals: .country)
                                }
                                // Row 9: Date of birth | Birthday Preference
                                HStack(spacing: 10) {
                                    VStack(alignment: .leading) {
                                        Text("Date of birth").font(.caption).foregroundColor(.gray)
                                        DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                                            .labelsHidden()
                                            .datePickerStyle(.compact)
                                    }
                                    VStack(alignment: .leading) {
                                        Text("Birthday Preference").font(.caption).foregroundColor(.gray)
                                        Picker("Birthday Preference", selection: $birthdayPreference) {
                                            ForEach(AddNewMemberView.BirthdayPreference.allCases) { pref in
                                                Text(pref.rawValue).tag(pref)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                    }
                                }
                                // Row 9: Marital status
                                VStack(alignment: .leading) {
                                    Text("Marital status").font(.caption).foregroundColor(.gray)
                                    Picker("Marital status", selection: $maritalStatus) {
                                        Text("Select").foregroundColor(.gray).tag("")
                                        ForEach(["Single", "Married", "Divorced", "Widowed"], id: \ .self) { status in
                                            Text(status).tag(status)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                                // Row 10: Has any children
                                VStack(alignment: .leading) {
                                    Text("Has any children").font(.caption).foregroundColor(.gray)
                                    Picker("Has any children", selection: $hasChildren) {
                                        Text("Yes").tag(true)
                                        Text("No").tag(false)
                                    }
                                    .pickerStyle(.menu)
                                }
                                // Row 11: Gender
                                VStack(alignment: .leading) {
                                    Text("Gender").font(.caption).foregroundColor(.gray)
                                    Picker("Gender", selection: $gender) {
                                        ForEach(AddNewMemberView.Gender.allCases) { g in
                                            Text(g.rawValue.capitalized).tag(g)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                }
                                // Row 12: Color tag
                                VStack(alignment: .leading) {
                                    Text("Color tag").font(.caption).foregroundColor(.gray)
                                    ColorTagPicker(selectedTag: $colorTag)
                                }
                                // Row 13: Member since | Met at
                                HStack(spacing: 10) {
                                    VStack(alignment: .leading) {
                                        Text("Member since").font(.caption).foregroundColor(.gray)
                                        DatePicker("", selection: $memberSince, displayedComponents: .date)
                                            .labelsHidden()
                                            .datePickerStyle(.compact)
                                    }
                                    VStack(alignment: .leading) {
                                        Text("Met at").font(.caption).foregroundColor(.gray)
                                        TextField("Met at", text: $metAt)
                                            .textFieldStyle(.roundedBorder)
                                            .focused($focusedField, equals: .metAt)
                                    }
                                }
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                            
                            // Torah
                            VStack(alignment: .leading, spacing: 18) {
                                Text("Religious Info").font(.headline)
                                
                                // Is Jewish picker
                                HStack(spacing: 12) {
                                    Text("Is Jewish?").font(.caption).foregroundColor(.gray)
                                    Picker("Is Jewish?", selection: $jewishStatus) {
                                        ForEach(AddNewMemberView.JewishStatus.allCases) { status in
                                            Text(status.rawValue).tag(status)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                }
                                
                                // Conditional religious fields - only show if jewishStatus is yes
                                if jewishStatus == .yes {
                                    HStack(spacing: 12) {
                                        Text("Tribe").font(.caption).foregroundColor(.gray)
                                        Picker("Tribe", selection: $tribe) {
                                            ForEach(AddNewMemberView.Tribe.allCases) { t in
                                                Text(t.rawValue).tag(t)
                                            }
                                        }
                                        .pickerStyle(.segmented)
                                    }
                                    VStack(alignment: .leading) {
                                        Text("Jewish member name").font(.caption).foregroundColor(.gray)
                                        TextField("אריאל בן דוד", text: $aliyaName)
                                            .textFieldStyle(.roundedBorder)
                                            .focused($focusedField, equals: .aliyaName)
                                            .submitLabel(.done)
                                            .onSubmit { focusedField = nil }
                                    }
                                    VStack(alignment: .leading) {
                                        Text("Father's Hebrew name").font(.caption).foregroundColor(.gray)
                                        TextField("Father's Hebrew name", text: $fathersHebrewName)
                                            .textFieldStyle(.roundedBorder)
                                            .focused($focusedField, equals: .fathersHebrewName)
                                            .submitLabel(.done)
                                            .onSubmit { focusedField = nil }
                                    }
                                    VStack(alignment: .leading) {
                                        Text("Mother's Hebrew name").font(.caption).foregroundColor(.gray)
                                        TextField("Mother's Hebrew name", text: $mothersHebrewName)
                                            .textFieldStyle(.roundedBorder)
                                            .focused($focusedField, equals: .mothersHebrewName)
                                            .submitLabel(.done)
                                            .onSubmit { focusedField = nil }
                                    }
                                }
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                            
                            // Household
                            VStack(alignment: .leading, spacing: 18) {
                                Text("Household / Associates").font(.headline)
                                if associates.isEmpty {
                                    Button(action: { associates.append(AssociateDraft()) }) {
                                        HStack {
                                            Text("Add associate")
                                                .foregroundColor(GlobalTheme.brandPrimary)
                                            Spacer()
                                            Image(systemName: "plus.circle")
                                                .foregroundColor(GlobalTheme.brandPrimary)
                                        }
                                        .padding()
                                        .background(Color(hex: "F2F2F7"))
                                        .cornerRadius(12)
                                    }
                                } else {
                                    ForEach(Array(associates.enumerated()), id: \ .element.id) { idx, associate in
                                        HStack(spacing: 8) {
                                            // Delete button
                                            Button(action: { associates.remove(at: idx) }) {
                                                Image(systemName: "minus.circle.fill").foregroundColor(.red)
                                            }
                                            // Label field as TextField with trailing arrow
                                            ZStack(alignment: .trailing) {
                                                TextField("Label", text: $associates[idx].label)
                                                    .textFieldStyle(.roundedBorder)
                                                    .padding(.trailing, 32)
                                                Button(action: {
                                                    editingAssociateIndex = idx
                                                    showLabelSheet = true
                                                }) {
                                                    Image(systemName: "chevron.right")
                                                        .foregroundColor(.gray)
                                                        .padding(.trailing, 8)
                                                }
                                            }
                                            // Relative name field with bold overlay if linked and not focused
                                            ZStack(alignment: .trailing) {
                                                if associates[idx].linkedMemberID != nil && focusedAssociateIndex != idx {
                                                    HStack {
                                                        Text(associates[idx].relativeName)
                                                            .font(.system(size: 16, weight: .semibold))
                                                            .foregroundColor(.primary)
                                                        Image(systemName: "link")
                                                            .foregroundColor(.green)
                                                    }
                                                    .padding(.vertical, 8)
                                                    .padding(.horizontal, 12)
                                                    .background(Color(.systemBackground))
                                                    .onTapGesture { focusedAssociateIndex = idx }
                                                }
                                                TextField("Relative name", text: $associates[idx].relativeName)
                                                    .textFieldStyle(.roundedBorder)
                                                    .font(.body)
                                                    .padding(.trailing, associates[idx].linkedMemberID != nil ? 52 : 32)
                                                    .opacity(associates[idx].linkedMemberID != nil && focusedAssociateIndex != idx ? 0 : 1)
                                                    .focused($focusedAssociateIndex, equals: idx)
                                                    .onChange(of: associates[idx].relativeName) { newValue, oldValue in
                                                        if !isProgrammaticAssociateUpdate && associates[idx].linkedMemberID != nil {
                                                            associates[idx].linkedMemberID = nil
                                                        }
                                                    }
                                                    .onChange(of: focusedAssociateIndex) { newValue, oldValue in
                                                        // Optional: handle focus exit logic here if needed
                                                    }
                                                Button(action: {
                                                    editingAssociateIndex = idx
                                                    showMemberSheet = true
                                                }) {
                                                    Image(systemName: "chevron.right")
                                                        .foregroundColor(.gray)
                                                        .padding(.trailing, 8)
                                                }
                                            }
                                        }
                                    }
                                    Button(action: { associates.append(AssociateDraft()) }) {
                                        HStack {
                                            Text("Add associate")
                                                .foregroundColor(GlobalTheme.brandPrimary)
                                            Spacer()
                                            Image(systemName: "plus.circle")
                                                .foregroundColor(GlobalTheme.brandPrimary)
                                        }
                                        .padding()
                                        .background(Color(hex: "F2F2F7"))
                                        .cornerRadius(12)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                            
                            // Social Media
                            SocialMediaSection(
                                linkedin: $linkedin,
                                facebook: $facebook,
                                instagram: $instagram,
                                tiktok: $tiktok,
                                weblinks: $weblinks
                            )
                            
                            // Tags Section
                            TagsSection(tags: $tags)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    var initials: String {
        let first = firstName.first.map { String($0) } ?? "Y"
        let last = lastName.first.map { String($0) } ?? "Z"
        return first + last
    }
    func loadImage() {
        guard let inputImage = inputImage else { return }
        profileImage = Image(uiImage: inputImage)
    }
    func addHouseholdMember() {
        let name = newHouseholdName.trimmingCharacters(in: .whitespacesAndNewlines)
        let rel = newHouseholdRelationship.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty && !rel.isEmpty else { return }
        household.append(HouseholdMember(name: name, relationship: rel))
        newHouseholdName = ""
        newHouseholdRelationship = ""
    }
    func removeHouseholdMember(_ member: HouseholdMember) {
        household.removeAll { $0.id == member.id }
    }
    func updateHouseholdMember(_ member: HouseholdMember, _ name: String?, _ relationship: String?) {
        if let idx = household.firstIndex(where: { $0.id == member.id }) {
            if let name = name { household[idx].name = name }
            if let relationship = relationship { household[idx].relationship = relationship }
        }
    }
    
    func createNewList() {
        let trimmedName = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Clear previous error
        listCreationError = nil
        
        // Validation checks with specific error messages
        guard !trimmedName.isEmpty else {
            listCreationError = "List name cannot be empty"
            return
        }
        guard trimmedName != "All" else {
            listCreationError = "List name 'All' is reserved"
            return
        }
        guard trimmedName != "Membership" else {
            listCreationError = "List name 'Membership' is reserved"
            return
        }
        guard !availableLists.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) else {
            listCreationError = "A list with this name already exists"
            return
        }
        
        // Check for special characters only (no letters or numbers)
        let hasValidCharacters = trimmedName.rangeOfCharacter(from: CharacterSet.alphanumerics) != nil
        guard hasValidCharacters else {
            listCreationError = "List name must contain at least one letter or number"
            return
        }
        
        let newList = MemberList(
            id: UUID(),
            communityId: UUID(), // This should be the actual community ID
            name: trimmedName,
            description: newListDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : newListDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            color: "#007AFF", // Default color
            emoji: nil, // No emoji
            isDefault: false,
            createdBy: UUID(), // This should be the actual user ID
            createdAt: Date(),
            updatedAt: Date(),
            memberCount: 0
        )
        
        availableLists.append(newList)
        selectedLists.insert(newList.id)
        
        // Reset form
        newListName = ""
        newListDescription = ""
        showingCreateListSheet = false
    }
    func printResults() {
        memberID = UUID().uuidString
        let member = NewMember(
            communityID: communityID,
            memberID: memberID,
            profilePhotoFileName: profilePhotoFileName,
            firstName: firstName,
            middleName: middleName,
            lastName: lastName,
            nickname: nickname,
            email: email,
            address: address,
            city: city,
            state: state,
            zipCode: zipCode,
            occupation: occupation,
            phoneNumber: phoneNumber,
            dateOfBirth: dateOfBirth,
            memberSince: memberSince,
            maritalStatus: maritalStatus,
            hasChildren: hasChildren,
            gender: gender,
            colorTag: colorTag,
            birthdayPreference: birthdayPreference,
            tribe: tribe,
            jewishMemberName: aliyaName,
            mothersHebrewName: mothersHebrewName,
            fathersHebrewName: fathersHebrewName,
            aliyaName: aliyaName,
            instagram: instagram,
            tiktok: tiktok,
            linkedin: linkedin,
            facebook: facebook,
            weblinks: weblinks,
            household: household,
            metAt: metAt,
            tags: tags
        )
        print(member)
        print("\nSignificant Dates:")
        for date in significantDates {
            print("- Occasion: \(date.occasion), Note: \(date.note), Event Date: \(date.eventDate), Hebrew Date: \(date.hebrewDate)")
        }
        print("\nYour Fields:")
        for field in customFields {
            print("- \(field.label): \(field.value)")
        }
        print("\nDonations:")
        print("- Monthly Membership: \(monthlyMembership)")
        print("- Collected on: \(collectionDay)")
        print("- Membership Ends: \(membershipEnds)")
        print("- Past Donations: \(pastDonations)")
        print("- Payment Method: \(paymentMethod)")
        if paymentMethod == "Credit Card" {
            print("- Card Number: \(fullCardNumber)")
            print("- Cardholder Name: \(cardholderName)")
            print("- Expiration Date: \(cardExpiration)")
            print("- Security Code: \(cardSecurityCode)")
            print("- Zipcode: \(cardZipcode)")
        }
        print("\nNotes:")
        for note in notes {
            print("- Title: \(note.title), Note: \(note.note)")
        }
        print("\nAssociates:")
        for associate in associates {
            print("\(associate.label), \(associate.relativeName), LinkedMemberID: \(associate.linkedMemberID ?? "nil")")
        }
    }
    private func addWeblink() {
        let trimmed = newWeblink.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !weblinks.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) else { return }
        weblinks.append(trimmed)
        newWeblink = ""
        isWeblinkInputFocused = true
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            // Extract file name if available
            if let url = info[.imageURL] as? URL {
                parent.profilePhotoFileName.wrappedValue = url.lastPathComponent
            } else {
                parent.profilePhotoFileName.wrappedValue = ""
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
    @Environment(\.presentationMode) var presentationMode
    @Binding var image: UIImage?
    // Add a binding for the file name
    var profilePhotoFileName: Binding<String> = .constant("")
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

// MARK: - Data Model for Export/Save
struct NewMember: CustomStringConvertible {
    var communityID: String
    var memberID: String
    var profilePhotoFileName: String
    var firstName: String
    var middleName: String
    var lastName: String
    var nickname: String
    var email: String
    var address: String
    var city: String
    var state: String
    var zipCode: String
    var occupation: String
    var phoneNumber: String
    var dateOfBirth: Date
    var memberSince: Date
    var maritalStatus: String
    var hasChildren: Bool
    var gender: AddNewMemberView.Gender
    var colorTag: ColorTag
    var birthdayPreference: AddNewMemberView.BirthdayPreference
    var tribe: AddNewMemberView.Tribe
    var jewishMemberName: String
    var mothersHebrewName: String
    var fathersHebrewName: String
    var aliyaName: String
    var instagram: String
    var tiktok: String
    var linkedin: String
    var facebook: String
    var weblinks: [String]
    var household: [AddNewMemberView.HouseholdMember]
    var metAt: String
    var tags: [String]
    // Note: profileImage is not included as Image is not serializable; you may add a placeholder if needed.
    var description: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dob = dateFormatter.string(from: dateOfBirth)
        let memberSinceStr = dateFormatter.string(from: memberSince)
        return """
        NewMember:
          Profile Photo File Name: \(profilePhotoFileName)
          CommunityID: \(communityID)
          MemberID: \(memberID)
          First Name: \(firstName)
          Middle Name: \(middleName)
          Last Name: \(lastName)
          Nickname: \(nickname)
          Email: \(email)
          Address: \(address)
          City: \(city)
          State: \(state)
          Zip Code: \(zipCode)
          Occupation: \(occupation)
          Phone: \(phoneNumber)
          Date of Birth: \(dob)
          Member Since: \(memberSinceStr)
          Marital Status: \(maritalStatus)
          Has Children: \(hasChildren)
          Gender: \(gender.rawValue)
          Color Tag: \(colorTag)
          Birthday Preference: \(birthdayPreference.rawValue)
          Tribe: \(tribe.rawValue)
          Jewish Member Name: \(jewishMemberName)
          Mother's Hebrew Name: \(mothersHebrewName)
          Father's Hebrew Name: \(fathersHebrewName)
          Aliya Name: \(aliyaName)
          Instagram: \(instagram)
          TikTok: \(tiktok)
          LinkedIn: \(linkedin)
          Facebook: \(facebook)
          Weblinks: \(weblinks)
          Met at: \(metAt)
          Tags: \(tags)
             Household UUID here if in the system to be able to quickly connect
        """
    }
}

// MARK: - Significant Dates Section
struct SignificantDate: Identifiable {
    let id = UUID()
    var occasion: String
    var note: String
    var eventDate: Date
    var hebrewDate: String
}

struct SignificantDatesSection: View {
    @Binding var dates: [SignificantDate]
    @Binding var openSection: AddNewMemberView.Section?
    @State private var occasions = ["Fathers Yahrzeit", "Mothers Yahrzeit", "Anniversary", "Birthday"]
    var body: some View {
        HStack {
            Button(action: {
                withAnimation {
                    openSection = openSection == .significantDates ? nil : .significantDates
                }
            }) {
                Text("Significant dates")
                    .font(.headline.bold())
                    .foregroundStyle(GlobalTheme.brandPrimary)
                    .padding(.vertical)
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(GlobalTheme.brandPrimary)
                    .font(.system(size: 16, weight: .semibold))
                    .rotationEffect(.degrees(openSection == .significantDates ? 0 : 90))
                    .animation(.easeInOut, value: openSection == .significantDates)
            }
        }
        VStack(alignment: .leading, spacing: 24) {
            if openSection == .significantDates {
                ForEach($dates) { $date in
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Occasion").font(.caption).foregroundColor(.gray)
                                Picker("Occasion", selection: $date.occasion) {
                                    ForEach(occasions, id: \ .self) { occ in
                                        Text(occ).tag(occ)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            VStack(alignment: .leading) {
                                Text("Note").font(.caption).foregroundColor(.gray)
                                TextField("Add note about occasion", text: $date.note)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Event date").font(.caption).foregroundColor(.gray)
                                DatePicker("", selection: $date.eventDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .datePickerStyle(.compact)
                            }
                            VStack(alignment: .leading) {
                                Text("Hebrew date").font(.caption).foregroundColor(.gray)
                                TextField("Hebrew date", text: $date.hebrewDate)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                        Divider().opacity(0.4)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                }
                Button(action: {
                    dates.append(SignificantDate(occasion: "", note: "", eventDate: Date(), hebrewDate: ""))
                }) {
                    Text("Add another occasion")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.4), lineWidth: 1))
                }
            }
        }
    }
}

// MARK: - Custom Field Model
struct CustomField: Identifiable {
    let id = UUID()
    var label: String
    var value: String
}

struct CustomFieldsSection: View {
    @Binding var customFields: [CustomField]
    @Binding var openSection: AddNewMemberView.Section?
    // New state for adding a field
    @State private var isAddingField: Bool = false
    @State private var newFieldDraft: CustomFieldDraft = CustomFieldDraft()
    // Simulate global field names (replace with real source if needed)
    @State private var globalFieldNames: [String] = []
    var addGlobalField: ((String, CustomFieldType) -> Void)? = nil // closure to add global field

    var body: some View {
        HStack {
            Button(action: {
                withAnimation {
                    openSection = openSection == .customFields ? nil : .customFields
                }
            }) {
                Text("Custom fields")
                    .font(.headline.bold())
                    .foregroundStyle(GlobalTheme.brandPrimary)
                    .padding(.vertical)
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(GlobalTheme.brandPrimary)
                    .font(.system(size: 16, weight: .semibold))
                    .rotationEffect(.degrees(openSection == .customFields ? 0 : 90))
                    .animation(.easeInOut, value: openSection == .customFields)
            }
        }
        VStack(alignment: .leading, spacing: 24) {
            if openSection == .customFields {
                // Inline editor for new custom field
                if isAddingField {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Field name*").font(.caption).foregroundColor(.gray)
                            Spacer()
                            Button(action: {
                                isAddingField = false
                                newFieldDraft = CustomFieldDraft()
                            }) {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                            }
                        }
                        TextField("Label", text: $newFieldDraft.name)
                            .textFieldStyle(.roundedBorder)
                        Text("Field type").font(.caption).foregroundColor(.gray)
                        Picker("Type", selection: $newFieldDraft.type) {
                            ForEach(CustomFieldType.allCases) { type in
                                Text(fieldTypeInfo[type]?.label ?? type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        if let info = fieldTypeInfo[newFieldDraft.type] {
                            Text(info.caption)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        // Field value input based on type
                        Group {
                            switch newFieldDraft.type {
                            case .string:
                                TextField("Value", text: $newFieldDraft.stringValue)
                                    .textFieldStyle(.roundedBorder)
                            case .number:
                                TextField("Value", text: $newFieldDraft.numberValue)
                                    .keyboardType(.numbersAndPunctuation)
                                    .textFieldStyle(.roundedBorder)
                            case .date:
                                DatePicker("Value", selection: $newFieldDraft.dateValue, displayedComponents: .date)
                                    .labelsHidden()
                                    .datePickerStyle(.compact)
                            case .boolean:
                                Toggle("Value", isOn: $newFieldDraft.boolValue)
                            }
                        }
                        Toggle(isOn: $newFieldDraft.addAsDefault) {
                            Text("Add as default field for all future and existing members")
                        }
                        .padding(.top, 4)
                        Text("Only the field will be added to all members. The value you enter here will only be saved for this member.")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Button(action: {
                            // Validation
                            let trimmedName = newFieldDraft.name.trimmingCharacters(in: .whitespacesAndNewlines)
                            let isUnique = !customFields.contains(where: { $0.label.caseInsensitiveCompare(trimmedName) == .orderedSame }) &&
                                !globalFieldNames.contains(where: { $0.caseInsensitiveCompare(trimmedName) == .orderedSame })
                            guard !trimmedName.isEmpty && isUnique else { return }
                            // Add global field if needed
                            if newFieldDraft.addAsDefault {
                                addGlobalField?(trimmedName, newFieldDraft.type)
                                globalFieldNames.append(trimmedName)
                            }
                            // Add to this member
                            let value: String
                            switch newFieldDraft.type {
                            case .string:
                                value = newFieldDraft.stringValue
                            case .number:
                                value = newFieldDraft.numberValue
                            case .date:
                                value = ISO8601DateFormatter().string(from: newFieldDraft.dateValue)
                            case .boolean:
                                value = newFieldDraft.boolValue ? "true" : "false"
                            }
                            customFields.append(CustomField(label: trimmedName, value: value))
                            // Reset
                            isAddingField = false
                            newFieldDraft = CustomFieldDraft()
                        }) {
                            Text("Add Field")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(
                                            (newFieldDraft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                            customFields.contains(where: { $0.label.caseInsensitiveCompare(newFieldDraft.name.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame }) ||
                                            globalFieldNames.contains(where: { $0.caseInsensitiveCompare(newFieldDraft.name.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame })
                                            ) ? Color.gray.opacity(0.3) : GlobalTheme.highlightGreen
                                        )
                                )
                                .foregroundColor(.white)
                        }
                        .disabled(
                            newFieldDraft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                            customFields.contains(where: { $0.label.caseInsensitiveCompare(newFieldDraft.name.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame }) ||
                            globalFieldNames.contains(where: { $0.caseInsensitiveCompare(newFieldDraft.name.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame })
                        )
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                }
                // List of custom fields
                ForEach($customFields) { $field in
                    HStack(spacing: 12) {
                        TextField("Label", text: $field.label)
                            .textFieldStyle(.roundedBorder)
                        TextField("Value", text: $field.value)
                            .textFieldStyle(.roundedBorder)
                        Button(action: {
                            if let idx = customFields.firstIndex(where: { $0.id == field.id }) {
                                customFields.remove(at: idx)
                            }
                        }) {
                            Image(systemName: "minus.circle.fill").foregroundColor(.red)
                        }
                    }
                }
                // Add custom field button
                if !isAddingField {
                    Button(action: {
                        isAddingField = true
                        newFieldDraft = CustomFieldDraft()
                    }) {
                        Text("Add custom field")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.4), lineWidth: 1))
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                }
            }
        }
    }
}

// MARK: - Donations Section
struct DonationsSection: View {
    @Binding var monthlyMembership: String
    @Binding var collectionDay: String
    @Binding var membershipEnds: String
    @Binding var pastDonations: String
    @Binding var paymentMethod: String
    @Binding var cardOnFile: String
    @Binding var fullCardNumber: String
    @Binding var cardExpiration: String
    @Binding var cardholderName: String
    @Binding var cardSecurityCode: String
    @Binding var cardZipcode: String
    let paymentOptions = ["Cash", "Check", "PayPal", "Credit Card", "Debit Card", "Bank Transfer", "Venmo", "Other"]
    @FocusState private var isCardNumberFocused: Bool
    @State private var displayedCardNumber: String = ""
    @Binding var openSection: AddNewMemberView.Section?

    var body: some View {
        HStack {
            Button(action: {
                withAnimation {
                    openSection = openSection == .donations ? nil : .donations
                }
            }) {
                Text("Donations")
                    .font(.headline.bold())
                    .foregroundStyle(GlobalTheme.brandPrimary)
                    .padding(.vertical)
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(GlobalTheme.brandPrimary)
                    .font(.system(size: 16, weight: .semibold))
                    .rotationEffect(.degrees(openSection == .donations ? 0 : 90))
                    .animation(.easeInOut, value: openSection == .donations)
            }
        }
        VStack(alignment: .leading, spacing: 24) {
            if openSection == .donations {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Membership").font(.headline)
                        .foregroundStyle(GlobalTheme.brandPrimary)
                    Divider().opacity(0.4)
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Monthly").font(.caption).foregroundColor(.gray)
                            TextField("$ 0.00", text: $monthlyMembership)
                                .textFieldStyle(.roundedBorder)
                        }
                        VStack(alignment: .leading) {
                            Text("Collected on the").font(.caption).foregroundColor(.gray)
                            TextField("24th of the month", text: $collectionDay)
                                .textFieldStyle(.roundedBorder)
                        }
                        VStack(alignment: .leading) {
                            Text("Ends").font(.caption).foregroundColor(.gray)
                            TextField("n/a", text: $membershipEnds)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    Text("Donations").font(.headline)
                        .foregroundStyle(GlobalTheme.brandPrimary)
                    Divider().opacity(0.4)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Given in the past").font(.caption).foregroundColor(.gray)
                        TextField("$ 0.00", text: $pastDonations)
                            .textFieldStyle(.roundedBorder)
                        Text("Payment Method").font(.caption).foregroundColor(.gray)
                        Picker("Payment Method", selection: $paymentMethod) {
                            ForEach(paymentOptions, id: \ .self) { method in
                                Text(method).tag(method)
                            }
                        }
                        .pickerStyle(.menu)
                        if paymentMethod == "Credit Card" {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Cardholder Name").font(.caption).foregroundColor(.gray)
                                TextField("Name on Card", text: $cardholderName)
                                    .textFieldStyle(.roundedBorder)
                                Text("Card Number").font(.caption).foregroundColor(.gray)
                                TextField("Card Number", text: $displayedCardNumber)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.roundedBorder)
                                    .focused($isCardNumberFocused)
                                    .onChange(of: displayedCardNumber) { newValue, oldValue in
                                        if isCardNumberFocused {
                                            // Only allow numbers, max 19 digits (standard for credit cards)
                                            let filtered = newValue.filter { $0.isNumber }
                                            if filtered != fullCardNumber {
                                                fullCardNumber = String(filtered.prefix(19))
                                            }
                                            displayedCardNumber = fullCardNumber
                                        }
                                    }
                                    .onChange(of: isCardNumberFocused) { newValue, oldValue in
                                        if newValue {
                                            // Show real number when focused
                                            displayedCardNumber = fullCardNumber
                                        } else {
                                            // Show masked when not focused
                                            let last4 = fullCardNumber.suffix(4)
                                            let masked = String(repeating: "•", count: max(0, fullCardNumber.count - 4)) + last4
                                            displayedCardNumber = masked
                                        }
                                    }
                                    .onAppear {
                                        // On appear, show masked if not focused
                                        if !isCardNumberFocused {
                                            let last4 = fullCardNumber.suffix(4)
                                            let masked = String(repeating: "•", count: max(0, fullCardNumber.count - 4)) + last4
                                            displayedCardNumber = masked
                                        }
                                    }
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading) {
                                        Text("Expiration").font(.caption).foregroundColor(.gray)
                                        TextField("MM/YY", text: $cardExpiration)
                                            .keyboardType(.numbersAndPunctuation)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                    VStack(alignment: .leading) {
                                        Text("Security Code").font(.caption).foregroundColor(.gray)
                                        SecureField("CVV", text: $cardSecurityCode)
                                            .keyboardType(.numberPad)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                    VStack(alignment: .leading) {
                                        Text("Zipcode").font(.caption).foregroundColor(.gray)
                                        TextField("Zipcode", text: $cardZipcode)
                                            .keyboardType(.numberPad)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
            }
        }
    }
}

// MARK: - Notes Section
struct NoteEntry: Identifiable {
    let id = UUID()
    var title: String
    var note: String
}

struct NotesSection: View {
    @Binding var notes: [NoteEntry]
    var firstName: String
    @Binding var openSection: AddNewMemberView.Section?
    var displayName: String { firstName.isEmpty ? "member" : firstName }
    @FocusState private var focusedNoteIndex: Int?
    var body: some View {
        HStack {
            Button(action: {
                withAnimation {
                    openSection = openSection == .notes ? nil : .notes
                }
            }) {
                Text("Notes")
                    .font(.headline.bold())
                    .foregroundStyle(GlobalTheme.brandPrimary)
                    .padding(.top, 8)
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(GlobalTheme.brandPrimary)
                    .font(.system(size: 16, weight: .semibold))
                    .rotationEffect(.degrees(openSection == .notes ? 0 : 90))
                    .animation(.easeInOut, value: openSection == .notes)
            }
        }
        VStack(alignment: .leading, spacing: 24) {
            if openSection == .notes {
                VStack {
                    Text("Add notes to \(displayName)'s profile.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    ForEach(Array(notes.enumerated()), id: \ .element.id) { idx, _ in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Title", text: $notes[idx].title)
                                .textFieldStyle(.roundedBorder)
                            TextEditor(text: $notes[idx].note)
                                .frame(height: 80)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
                                .focused($focusedNoteIndex, equals: idx)
                        }
                        .padding(.vertical, 4)
                    }
                    Button(action: {
                        notes.append(NoteEntry(title: "", note: ""))
                    }) {
                        Text("Add a note")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.4), lineWidth: 1))
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                .onTapGesture {
                    focusedNoteIndex = nil
                }
            }
        }
    }
}

// MARK: - Keyboard Observer
class KeyboardObserver: ObservableObject {
    @Published var isKeyboardVisible: Bool = false
    private var willShow: NSObjectProtocol?
    private var willHide: NSObjectProtocol?
    init() {
        willShow = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] _ in
            self?.isKeyboardVisible = true
        }
        willHide = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] _ in
            self?.isKeyboardVisible = false
        }
    }
    deinit {
        if let willShow = willShow { NotificationCenter.default.removeObserver(willShow) }
        if let willHide = willHide { NotificationCenter.default.removeObserver(willHide) }
    }
}

struct ShareFormCard: View {
    @State private var showCopied = false
    var body: some View {
        ZStack(alignment: .top) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Have them fill it out")
                        .font(.headline)
                        .foregroundColor(GlobalTheme.brandPrimary)
                    Text("Share this form so they can enter their info")
                        .font(.footnote)
                        .foregroundColor(Color(.systemGray))
                }
                Spacer()
                Button(action: {
                    UIPasteboard.general.string = "https://your-form-link.com"
                    showCopied = true
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showCopied = false
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(GlobalTheme.roloLight)
                            .frame(width: 36, height: 36)
                        Image(systemName: "doc.on.doc")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(GlobalTheme.brandPrimary)
                    }
                }
                .accessibilityLabel("Copy form link")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray3).opacity(0.6), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 19.1, x: 0, y: 2)
            .padding(.bottom, 12)
            if showCopied {
                Text("Link copied!")
                    .font(.caption.bold())
                    .foregroundColor(GlobalTheme.highlightGreen)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(GlobalTheme.tertiaryGreen)
                    .clipShape(Capsule())
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
                    .padding(.top, -15)
            }
        }
        .animation(.easeInOut, value: showCopied)
    }
}

// MARK: - New Sheets
struct LabelSelectionSheet: View {
    @Binding var selectedLabel: String
    @Environment(\.dismiss) var dismiss
    @State private var search = ""
    let labels = ["Father", "Mother", "Son", "Daughter", "Brother", "Sister", "Grandfather", "Grandmother", "Coworker", "Colleague", "Best friend", "Aunt", "Uncle", "Cousin", "Neighbor", "Boss"]
    var filtered: [String] { search.isEmpty ? labels : labels.filter { $0.localizedCaseInsensitiveContains(search) } }
    var body: some View {
        NavigationView {
            List {
                Section {
                    TextField("Search", text: $search)
                }
                ForEach(filtered, id: \.self) { label in
                    Button(action: {
                        selectedLabel = label
                        dismiss()
                    }) {
                        Text(label)
                    }
                }
                Button(action: { /* Add custom label logic */ }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add custom label")
                    }
                }
            }
            .navigationTitle("Labels")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: { dismiss() }) } }
        }
    }
}

// 1. Define MemberPlaceholder
struct MemberPlaceholder: Identifiable {
    let memberID: String
    let name: String
    var id: String { memberID }
}

// 2. Update MemberSelectionSheet
struct MemberSelectionSheet: View {
    @Binding var associate: AddNewMemberView.AssociateDraft
    var onSelect: (() -> Void)? = nil
    var onDismiss: (() -> Void)? = nil
    @Environment(\.dismiss) var dismiss
    @State private var search = ""
    let members: [MemberPlaceholder] = {
        let broomfieldMembers = BroomfieldDataLoader.shared.getBroomfieldMembers()
        return Array(broomfieldMembers.prefix(20)).map { member in
            MemberPlaceholder(memberID: member.id.uuidString, name: member.name)
        }
    }()
    var filtered: [MemberPlaceholder] { search.isEmpty ? members : members.filter { $0.name.localizedCaseInsensitiveContains(search) } }
    var body: some View {
        NavigationView {
            List {
                Section {
                    TextField("Search", text: $search)
                }
                ForEach(filtered) { member in
                    Button(action: {
                        onSelect?()
                        associate.relativeName = member.name
                        associate.linkedMemberID = member.memberID
                        print("Selected member: \(member.name), id: \(member.memberID)")
                        dismiss()
                        onDismiss?()
                    }) {
                        Text(member.name)
                    }
                }
            }
            .navigationTitle("Your members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                        onDismiss?()
                    }
                }
            }
        }
    }
}

// --- FLOW LAYOUT (iOS 17+) ---
import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        var width: CGFloat = 0
        var height: CGFloat = 0
        var rowHeight: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if width + size.width > maxWidth {
                width = 0
                height += rowHeight + spacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            width += size.width + spacing
        }
        height += rowHeight
        return CGSize(width: maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: size.width, height: size.height))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

struct TagsSection: View {
    @Binding var tags: [String]
    @State private var newTag: String = ""
    @FocusState private var isInputFocused: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.headline)
                .foregroundColor(GlobalTheme.roloLightGrey)
            // Tag pills
            if !tags.isEmpty {
                FlowLayout(spacing: 10) {
                    ForEach(tags, id: \.self) { tag in
                        HStack(spacing: 2) {
                            Text(tag)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(GlobalTheme.brandPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                            Button(action: {
                                if let idx = tags.firstIndex(of: tag) {
                                    tags.remove(at: idx)
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .resizable()
                                    .frame(width: 12, height: 12)
                                    .foregroundColor(GlobalTheme.highlightGreen)
                                    .padding(.trailing, 6)
                            }
                        }
                        .background(GlobalTheme.tertiaryGreen)
                        .cornerRadius(24)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            // Add tag input
            HStack {
                TextField("Add tag", text: $newTag)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color(hex: "F2F2F7"))
                    .cornerRadius(8)
                    .focused($isInputFocused)
                    .onSubmit(addTag)
                Button(action: addTag) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "D9D9D9"))
                            .frame(width: 32, height: 32)
                        Image(systemName: "plus")
                            .foregroundColor(Color(hex: "0F1F1C"))
                    }
                }
                .padding(.leading, 4)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !tags.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) else { return }
        tags.append(trimmed)
        newTag = ""
        isInputFocused = true
    }
}

// Add this new subview at file scope (private):
private struct SocialMediaSection: View {
    @Binding var linkedin: String
    @Binding var facebook: String
    @Binding var instagram: String
    @Binding var tiktok: String
    @Binding var weblinks: [String]
    @State private var newWeblink: String = ""
    @FocusState private var isWeblinkInputFocused: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Social Media")
                .font(.headline)
                .foregroundColor(Color(hex: "65675F"))
            // LinkedIn & Facebook (disabled)
            VStack(spacing: 12) {
                TextField("LinkedIn", text: $linkedin)
                    .padding()
                    .background(Color(hex: "F2F2F7"))
                    .cornerRadius(8)
                    .foregroundColor(.gray)
                TextField("Facebook", text: $facebook)
                    .padding()
                    .background(Color(hex: "F2F2F7"))
                    .cornerRadius(8)
                    .foregroundColor(.gray)
            }
            // Instagram & TikTok (editable)
            VStack(spacing: 20) {
                HStack {
                    HStack {
                        Text("Instagram")
                            .font(.body.bold())
                            .foregroundColor(Color(hex: "0F1F1C"))
                        Spacer()
                    }
                    .frame(width: 90)
                    Text("@")
                        .font(.body)
                        .foregroundColor(Color(hex: "0F1F1C"))
                    TextField("username", text: $instagram)
                        .foregroundColor(.gray)
                }
                HStack {
                    HStack {
                        Text("TikTok")
                            .font(.body.bold())
                            .foregroundColor(Color(hex: "0F1F1C"))
                        Spacer()
                    }
                    .frame(width: 90)
                    Text("@")
                        .font(.body)
                        .foregroundColor(Color(hex: "0F1F1C"))
                    TextField("username", text: $tiktok)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            // Weblinks
            ForEach(weblinks.indices, id: \.self) { idx in
                HStack {
                    Button(action: { weblinks.remove(at: idx) }) {
                        Image(systemName: "minus.circle.fill").foregroundColor(.red)
                    }
                    Image(systemName: "link")
                    TextField("Add weblink", text: $weblinks[idx])
                        .textFieldStyle(.plain)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 4)
                }
                .background(Color.white)
                .cornerRadius(8)
                .padding(.vertical, 2)
            }
            // Add Weblink input (always visible, like tags)
            HStack {
                TextField("Add weblink", text: $newWeblink)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color(hex: "F2F2F7"))
                    .cornerRadius(8)
                    .focused($isWeblinkInputFocused)
                    .onSubmit(addWeblink)
                Button(action: addWeblink) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "D9D9D9"))
                            .frame(width: 32, height: 32)
                        Image(systemName: "plus")
                            .foregroundColor(Color(hex: "0F1F1C"))
                    }
                }
                .padding(.leading, 4)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
    private func addWeblink() {
        let trimmed = newWeblink.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !weblinks.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) else { return }
        weblinks.append(trimmed)
        newWeblink = ""
        isWeblinkInputFocused = true
    }
}

// MARK: - Lists Section
struct ListsSection: View {
    @Binding var selectedLists: Set<UUID>
    @Binding var availableLists: [MemberList]
    @Binding var openSection: AddNewMemberView.Section?
    @Binding var showingCreateListSheet: Bool
    @Binding var newListName: String
    @Binding var newListDescription: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: {
                    withAnimation {
                        openSection = openSection == .lists ? nil : .lists
                    }
                }) {
                    Text("Add to list")
                        .font(.headline.bold())
                        .foregroundStyle(GlobalTheme.brandPrimary)
                        .padding(.top, 8)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(GlobalTheme.brandPrimary)
                        .font(.system(size: 16, weight: .semibold))
                        .rotationEffect(.degrees(openSection == .lists ? 180 : 0))
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            if openSection == .lists {
                VStack(alignment: .leading, spacing: 12) {
                    // Selected lists display
                    if !selectedLists.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Selected lists:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 120), spacing: 8)
                            ], spacing: 8) {
                                ForEach(availableLists.filter { selectedLists.contains($0.id) }) { list in
                                    HStack(spacing: 6) {
                                        Text(list.name)
                                            .font(.caption)
                                            .lineLimit(1)
                                        Spacer()
                                        Button(action: {
                                            selectedLists.remove(list.id)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(simpleListBackground())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Available lists
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Available lists:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        if availableLists.isEmpty {
                            VStack(spacing: 12) {
                                Text("No lists created yet")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Button(action: {
                                    showingCreateListSheet = true
                                }) {
                                    HStack {
                                        Image(systemName: "plus")
                                        Text("Create your first list")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(GlobalTheme.brandPrimary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(GlobalTheme.brandPrimary, lineWidth: 1)
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 120), spacing: 8)
                            ], spacing: 8) {
                                ForEach(availableLists.filter { !selectedLists.contains($0.id) }) { list in
                                    Button(action: {
                                        selectedLists.insert(list.id)
                                    }) {
                                        HStack(spacing: 6) {
                                            Text(list.name)
                                                .font(.caption)
                                                .lineLimit(1)
                                                .foregroundColor(.primary)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .frame(maxWidth: .infinity)
                                        .background(simpleListBackground())
                                    }
                                }
                                
                                // Add new list button
                                Button(action: {
                                    showingCreateListSheet = true
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "plus")
                                            .font(.caption)
                                        Text("New list")
                                            .font(.caption)
                                            .lineLimit(1)
                                    }
                                    .foregroundColor(GlobalTheme.brandPrimary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(GlobalTheme.brandPrimary, lineWidth: 1)
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
    
    private func simpleListBackground() -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Create List Sheet
struct CreateListSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var newListName: String
    @Binding var newListDescription: String
    @Binding var errorMessage: String?
    let onSave: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // List name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("List name")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Example: Work, Friends", text: $newListName)
                        .textFieldStyle(.roundedBorder)
                        .font(.body)
                        .onChange(of: newListName) { _ in
                            // Clear error when user starts typing
                            errorMessage = nil
                        }
                }
                
                // Description input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description (optional)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Brief description of this list", text: $newListDescription)
                        .textFieldStyle(.roundedBorder)
                        .font(.body)
                }
                
                // Error message display
                if let errorMessage = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Create List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(newListName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddNewMemberView()
}

