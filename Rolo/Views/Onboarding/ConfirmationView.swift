import SwiftUI

struct ConfirmationView: View {
    @ObservedObject var authService: AuthService
    let onStepChange: (OnboardingStep) -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Success Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)
            
            // Success Message
            VStack(spacing: 16) {
                Text("You're all set!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Want to go further?")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            // Next Steps
            VStack(spacing: 16) {
                Text("Suggested next steps:")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(spacing: 12) {
                    NextStepItem(
                        icon: "person.2.badge.plus",
                        title: "Invite teammates",
                        description: "Add more people to your community"
                    )
                    
                    NextStepItem(
                        icon: "envelope.badge",
                        title: "Connect Email",
                        description: "Set up email notifications"
                    )
                    
                    NextStepItem(
                        icon: "message.badge",
                        title: "Connect SMS",
                        description: "Enable SMS notifications"
                    )
                    
                    NextStepItem(
                        icon: "calendar.badge.plus",
                        title: "Integrate with Google Calendar",
                        description: "Sync your events automatically"
                    )
                }
            }
            .padding(.horizontal, 20)
            
            // Action Button
            Button(action: {
                onStepChange(.dashboard)
            }) {
                Text("Continue to Dashboard")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.vertical, 40)
    }
}

struct NextStepItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
} 