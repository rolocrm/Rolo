import SwiftUI

struct AddCustomFieldDialog: View {
    @Binding var isPresented: Bool
    var existingFieldNames: [String]
    var onAdd: (CustomFieldDraft) -> Void

    @State private var draft = CustomFieldDraft()
    @FocusState private var isNameFocused: Bool
    @FocusState private var isValueFocused: Bool

    private var trimmedName: String { draft.name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isDuplicate: Bool {
        existingFieldNames.contains { $0.caseInsensitiveCompare(trimmedName) == .orderedSame }
    }
    private var isValid: Bool {
        !trimmedName.isEmpty && !isDuplicate
    }
    private var valuePlaceholder: String {
        switch draft.type {
        case .string: return "Value"
        case .number: return "Value"
        case .date: return ""
        case .boolean: return ""
        }
    }
    private var helpText: String {
        switch draft.type {
        case .string: return "For example; words, names, or sentences."
        case .number: return "For example; amounts, ages, or counts."
        case .date: return "For example; birthdays or anniversaries."
        case .boolean: return "For example; checkboxes or simple choices."
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack(spacing: 12) {
                        Toggle("", isOn: $draft.addAsDefault)
                            .toggleStyle(SwitchToggleStyle(tint: GlobalTheme.highlightGreen))
                            .labelsHidden()
                        Text("Set as default")
                            .font(.body)
                            .foregroundColor(Color(.label))
                        Spacer()
                        Button(action: { isPresented = false }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Color(.systemGray2))
                                .padding(8)
                        }
                        .accessibilityLabel("Close")
                    }
                    // Name input
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Name*")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("Name", text: $draft.name)
                            .textFieldStyle(.roundedBorder)
                            .focused($isNameFocused)
                            .submitLabel(.next)
                            .onSubmit { isValueFocused = true }
                    }
                    // Field type row
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Field type")
                            .font(.caption)
                            .foregroundColor(.gray)
                        HStack(spacing: 12) {
                            Picker("Type", selection: $draft.type) {
                                ForEach(CustomFieldType.allCases) { type in
                                    Text(fieldTypeInfo[type]?.label ?? type.rawValue).tag(type)
                                }
                            }
                            .tint(GlobalTheme.brandPrimary)
                            .pickerStyle(.menu)
                            .background(
                                Color(hex: "#F2F2F7")
                                    .cornerRadius(8)
                            )
                            
//                            .frame(width: 110)
                            Group {
                                switch draft.type {
                                case .string:
                                    TextField(valuePlaceholder, text: $draft.stringValue)
                                        .textFieldStyle(.roundedBorder)
                                        .focused($isValueFocused)
                                case .number:
                                    TextField(valuePlaceholder, text: $draft.numberValue)
                                        .keyboardType(.numbersAndPunctuation)
                                        .textFieldStyle(.roundedBorder)
                                        .focused($isValueFocused)
                                case .date:
                                    DatePicker("", selection: $draft.dateValue, displayedComponents: .date)
                                        .labelsHidden()
                                        .datePickerStyle(.compact)
                                case .boolean:
                                    Toggle("Value*", isOn: $draft.boolValue)
                                        .labelsHidden()
                                }
                            }
                        }
                        Text(helpText)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                // Add field button
                Button(action: {
                    if isValid {
                        onAdd(draft)
                        isPresented = false
                    }
                }) {
                    HStack(spacing: 8) {
                        Text("Add field")
                            .font(.headline)
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValid ? GlobalTheme.tertiaryGreen : GlobalTheme.roloLightGrey20)
                    .foregroundColor(isValid ? GlobalTheme.highlightGreen : GlobalTheme.roloLightGrey)
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 8)
                .disabled(!isValid)
                // Footer
                Text("If 'Set as default' is enabled, the field will be added to all members. The value you enter here will only apply to this member.")
                    .font(.system(size: 9.5))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 4)
            )
            .frame(maxWidth: 400)
            .padding(.horizontal, 24)
        }
        .onAppear { isNameFocused = true }
    }
}

// Preview
#Preview {
    AddCustomFieldDialog(
        isPresented: .constant(true),
        existingFieldNames: ["Birthday", "Anniversary"],
        onAdd: { _ in }
    )
} 
