import SwiftUI

struct AssetCard: ExpandableCard {
    let id: UUID
    let title: String
    let date: Date
    let fileType: FileType
    let fileSize: Int64
    let lastModified: Date
    let description: String
    let image: String
    let isCompleted: Bool
    
    enum FileType: String {
        case document, image, video, audio, other
        
        var icon: String {
            switch self {
            case .document: return "doc.fill"
            case .image: return "photo.fill"
            case .video: return "video.fill"
            case .audio: return "waveform"
            case .other: return "doc.fill"
            }
        }
    }
    
    var type: CardType { .asset }
    
    func expandedView() -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 16) {
                // File Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: fileType.icon)
                            .font(.title)
                        VStack(alignment: .leading) {
                            Text(title)
                                .font(.headline)
                            Text("\(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "clock")
                        Text("Last modified: \(lastModified.formatted(date: .long, time: .shortened))")
                    }
                    .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Description
                Text(description)
                    .font(.body)
                    .lineSpacing(4)
                
                // Actions
                HStack(spacing: 20) {
                    Button(action: {}) {
                        Label("Download", systemImage: "arrow.down.circle")
                    }
                    Button(action: {}) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
                .buttonStyle(.bordered)
                .padding(.top)
            }
            .padding()
        )
    }
}

// MARK: - Preview Provider
struct AssetCard_Previews: PreviewProvider {
    static var previews: some View {
        AssetCard(
            id: UUID(),
            title: "Annual Report 2023.pdf",
            date: Date(),
            fileType: .document,
            fileSize: 2_500_000, // 2.5 MB
            lastModified: Date().addingTimeInterval(-86400), // Yesterday
            description: "Complete annual report for the fiscal year 2023, including financial statements and operational highlights.",
            image: "Placeholder member profile 1",
            isCompleted: false
        )
        .expandedView()
    }
} 
