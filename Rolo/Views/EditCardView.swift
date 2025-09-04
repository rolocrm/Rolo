import SwiftUI

// MARK: - Edit Card View
struct EditCardView: View {
    let title: String
    let description: String
    let editTemplate: Bool
    let text: Binding<String>
    @Binding var isEditing: Bool
    let onEditTemplate: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Spacer()
                        .frame(height: 24)
                    Text(title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(GlobalTheme.brandPrimary)
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(GlobalTheme.brandPrimary.opacity(0.6))
                }
                .padding(.horizontal, 20)
                
                Divider()
                    .background(GlobalTheme.brandPrimary.opacity(0.1))
                    .padding(.horizontal, 20)
                    
                
                TextEditor(text: text)
                    .font(.system(size: 16))
                    .foregroundColor(GlobalTheme.brandPrimary)
                    .padding(12)
                    .frame(minHeight: 180)
                    .background(GlobalTheme.inputGrey)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(GlobalTheme.brandPrimary, lineWidth: 2)
                    )
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 24)
                
                HStack(spacing: 12) {
                    Button("Cancel") {
                        isEditing = false
                    }
                    .buttonStyle(BigButtonStyle(
                        backgroundColor: .clear,
                        foregroundColor: GlobalTheme.brandPrimary,
                        strokeColor: GlobalTheme.brandPrimary.opacity(0.6)
                    ))
                    
                    Button("Save") {
                        isEditing = false
                    }
                    .buttonStyle(BigButtonStyle(
                        backgroundColor: GlobalTheme.brandPrimary,
                        foregroundColor: GlobalTheme.highlightGreen
                    ))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                
                Spacer()
            }
            .background(GlobalTheme.roloLight)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isEditing = false
                    }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(GlobalTheme.brandPrimary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Spacer()
                }
                if editTemplate {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Edit template") {
                            onEditTemplate()
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(GlobalTheme.brandPrimary)
                    }
                }
            }
        }
    }
}

// MARK: - Preview Provider
struct EditCardView_Previews: PreviewProvider {
    static var previews: some View {
        EditCardView(
            title: "Reach out",
            description: "Sent out after a 6 month period of time that you haven't been in contact with a member.",
            editTemplate: true,
            text: .constant("Sample message content"),
            isEditing: .constant(true),
            onEditTemplate: {}
        )
        .previewLayout(.sizeThatFits)
    }
}
