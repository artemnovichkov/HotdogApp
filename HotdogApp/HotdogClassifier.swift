import Foundation
import FoundationModels
import UIKit

@Generable
struct HotdogResult {
    @Guide(description: "true if the image contains a hotdog, false otherwise")
    var isHotdog: Bool
}

@MainActor
@Observable
final class HotdogClassifier {
    func classify(image: UIImage) async throws -> HotdogResult {
        let session = LanguageModelSession(
            instructions: "You are a hotdog detector. Analyze the image and determine if it contains a hotdog."
        )
        let response = try await session.respond(generating: HotdogResult.self) {
            "Does this image contain a hotdog?"
            Attachment(image)
        }
        return response.content
    }
}
