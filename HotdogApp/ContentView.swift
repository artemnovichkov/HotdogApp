import SwiftUI
import PhotosUI
import FoundationModels

struct ContentView: View {
    @State private var classifier = HotdogClassifier()
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var result: HotdogResult?
    @State private var isClassifying = false
    @State private var errorMessage: String?
    @State private var showCamera = false

    private let model = SystemLanguageModel.default

    var body: some View {
        switch model.availability {
        case .available:
            mainView
        case .unavailable(.appleIntelligenceNotEnabled):
            unavailableView("Enable Apple Intelligence in Settings to use this app.")
        case .unavailable(.deviceNotEligible):
            unavailableView("This device doesn't support Apple Intelligence.")
        case .unavailable(.modelNotReady):
            unavailableView("Apple Intelligence model is downloading…")
        case .unavailable:
            unavailableView("Apple Intelligence is unavailable.")
        }
    }

    private var mainView: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Photo card fills all available space
                photoView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(alignment: .bottom) {
                        // Status badge floats over the photo bottom
                        statusView
                            .padding(.bottom, 16)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.horizontal)

                // Buttons pinned below the card
                HStack(spacing: 12) {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button {
                            showCamera = true
                        } label: {
                            Label("Take Photo", systemImage: "camera")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.glass)
                    }

                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Choose Photo", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.glass)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .padding(.top, 8)
            .navigationTitle("Hotdog?")
        }
        .overlay {
            if let result, result.isHotdog {
                ConfettiView()
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraView(image: $selectedImage)
        }
        .onChange(of: selectedItem) {
            loadPhoto()
        }
        .onChange(of: selectedImage) {
            classify()
        }
    }

    @ViewBuilder
    private var photoView: some View {
        Color(.systemGroupedBackground)
            .overlay {
                if let selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(.tint)
                        Text("Take or choose a photo\nto find out if it's a hotdog")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
    }

    @ViewBuilder
    private var statusView: some View {
        if isClassifying {
            ProgressView("Analyzing…")
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .glassEffect(in: .capsule)
        } else if let result {
            Text(result.isHotdog ? "🌭 Hotdog!" : "🚫 Not Hotdog!")
                .font(.title.bold())
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .glassEffect(.regular.tint(result.isHotdog ? .green : .red), in: .capsule)
        } else if let errorMessage {
            Text(errorMessage)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding()
                .glassEffect(in: .rect(cornerRadius: 16))
        }
    }

    private func unavailableView(_ message: String) -> some View {
        ContentUnavailableView(
            "Apple Intelligence Unavailable",
            systemImage: "brain",
            description: Text(message)
        )
    }

    private func loadPhoto() {
        guard let item = selectedItem else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImage = image
            }
        }
    }

    private func classify() {
        guard let image = selectedImage else { return }
        result = nil
        errorMessage = nil
        isClassifying = true
        Task {
            do {
                result = try await classifier.classify(image: image)
            } catch {
                errorMessage = error.localizedDescription
            }
            isClassifying = false
        }
    }
}

#Preview {
    ContentView()
}
