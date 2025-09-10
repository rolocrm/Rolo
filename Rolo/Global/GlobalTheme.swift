import SwiftUI

enum GlobalTheme {
    // MARK: - Dark Colors
    static let brandPrimary = Color(hex: "0F1F1C")    // #0F1F1C
    static let secondaryGreen = Color(hex: "142C28")   // #142C28
    static let coloredGrey = Color(hex: "5B6966")      // #5B6966
    
    // MARK: - Light Colors
    static let highlightGreen = Color(hex: "7CA646")   // #7CA646
    static let roloLight = Color(hex: "F6F6F3")        // #F6F6F3
    static let tertiaryGreen = Color(hex: "E9F0E4")    // #E9F0E4
    
    // MARK: - Grey Colors
    static let roloDarkGrey = Color(hex: "656762")     // #656762
    static let roloLightGrey = Color(hex: "BBBBBB")    // #BBBBBB
    static let inputGrey = Color(hex: "F8F8F8")        // #F8F8F8
    static let roloLightGrey60 = roloLightGrey.opacity(0.6)
    static let roloLightGrey40 = roloLightGrey.opacity(0.4)
    static let roloLightGrey20 = roloLightGrey.opacity(0.2)
    
    // MARK: - Color Tags
    static let colorTagRed = Color(hex: "EA603E")     
    static let colorTagYellow = Color(hex: "F6C15F")
    static let colorTagGreen = Color(hex: "74BA1A")
    static let colorTagBlue = Color(hex: "509CE4")
    static let colorTagPurple = Color(hex: "A974EA")
    static let colorTagBrown = Color(hex: "BB7853")
    
    // MARK: - Accent Colors
    static let roloRed = Color(hex: "E5655C")         // #E5655C
    
    // MARK: - Gradient Colors
    static let roloAIGradient = LinearGradient(
        colors: [
            Color(hex: "4D672C"),  // #4D672C
            Color(hex: "7CA646"),  // #7CA646
            Color(hex: "E9F0E4")   // #E9F0E4
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

enum ColorTag: String, CaseIterable, Identifiable, Codable {
    case none, red, yellow, green, blue, purple, brown

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .none: return .clear
        case .red: return GlobalTheme.colorTagRed
        case .yellow: return GlobalTheme.colorTagYellow
        case .green: return GlobalTheme.colorTagGreen
        case .blue: return GlobalTheme.colorTagBlue
        case .purple: return GlobalTheme.colorTagPurple
        case .brown: return GlobalTheme.colorTagBrown
        }
    }
} 
