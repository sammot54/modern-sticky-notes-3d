import SwiftUI
import PhotosUI
import UIKit

@MainActor
final class PhotoManager: ObservableObject {
    @Published var selectedImages: [PhotosPickerItem] = []
    @Published var loadedImages: [UIImage] = []
    @Published var isLoading = false
    
    func loadSelectedImages() async {
        isLoading = true
        loadedImages.removeAll()
        
        for item in selectedImages {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    loadedImages.append(image)
                }
            } catch {
                print("Failed to load image: \(error)")
            }
        }
        
        isLoading = false
    }
    
    func clearImages() {
        selectedImages.removeAll()
        loadedImages.removeAll()
    }
    
    func saveImageData() -> [Data] {
        return loadedImages.compactMap { image in
            image.jpegData(compressionQuality: 0.8)
        }
    }
    
    static func loadImage(from data: Data) -> UIImage? {
        return UIImage(data: data)
    }
}

struct ModernPhotoPicker: View {
    @StateObject private var photoManager = PhotoManager()
    @Binding var selectedImageData: Data?
    @Binding var hasImage: Bool
    
    let onImageSelected: (UIImage) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Photos Picker Button
            PhotosPicker(
                selection: $photoManager.selectedImages,
                maxSelectionCount: 1,
                matching: .images
            ) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.title2)
                    Text("Add Photo")
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .onChange(of: photoManager.selectedImages) { oldValue, newValue in
                Task {
                    await photoManager.loadSelectedImages()
                }
            }
            .onChange(of: photoManager.loadedImages) { oldValue, newValue in
                if let firstImage = newValue.first {
                    selectedImageData = firstImage.jpegData(compressionQuality: 0.8)
                    hasImage = true
                    onImageSelected(firstImage)
                }
            }
            
            // Loading indicator
            if photoManager.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading image...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Display selected image
            if let image = photoManager.loadedImages.first {
                VStack(spacing: 8) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                    
                    Button(action: {
                        photoManager.clearImages()
                        selectedImageData = nil
                        hasImage = false
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Remove Photo")
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .padding()
    }
}

struct ImagePreview: View {
    let imageData: Data
    @State private var showingFullScreen = false
    
    var body: some View {
        if let image = UIImage(data: imageData) {
            Button(action: {
                showingFullScreen = true
            }) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            }
            .fullScreenCover(isPresented: $showingFullScreen) {
                FullScreenImageView(image: image)
            }
        }
    }
}

struct FullScreenImageView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastScaleValue: CGFloat = 1.0
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView([.horizontal, .vertical]) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }
                .background(Color.black)
                .navigationTitle("Image")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                    }
                }
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScaleValue
                            lastScaleValue = value
                            scale = min(max(scale * delta, 0.5), 3.0)
                        }
                        .onEnded { value in
                            lastScaleValue = 1.0
                        }
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = value.translation
                        }
                        .onEnded { value in
                            withAnimation {
                                offset = .zero
                            }
                        }
                )
            }
        }
    }
}

struct CameraCaptureView: View {
    @Binding var capturedImage: UIImage?
    @Binding var isPresented: Bool
    
    var body: some View {
        ImagePicker(
            selectedImage: $capturedImage,
            sourceType: .camera
        )
        .onChange(of: capturedImage) { oldValue, newValue in
            if newValue != nil {
                isPresented = false
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        
        // Configure camera settings
        if sourceType == .camera {
            picker.cameraCaptureMode = .photo
            picker.cameraDevice = .rear
            picker.allowsEditing = true
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage
            parent.selectedImage = image
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ImageAttachmentView: View {
    @Binding var imageData: Data?
    @Binding var hasImage: Bool
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Attachments")
                .font(.headline)
            
            if let imageData = imageData {
                HStack {
                    ImagePreview(imageData: imageData)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Image attached")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Text("\(imageData.count.formatted(.byteCount(style: .file)))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        self.imageData = nil
                        hasImage = false
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
            
            // Attachment options
            HStack(spacing: 12) {
                Button(action: {
                    showingImagePicker = true
                }) {
                    VStack {
                        Image(systemName: "photo")
                            .font(.title2)
                        Text("Gallery")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }
                
                Button(action: {
                    showingCamera = true
                }) {
                    VStack {
                        Image(systemName: "camera")
                            .font(.title2)
                        Text("Camera")
                            .font(.caption)
                    }
                    .foregroundColor(.green)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $capturedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(selectedImage: $capturedImage, sourceType: .camera)
        }
        .onChange(of: capturedImage) { oldValue, newValue in
            if let image = newValue {
                imageData = image.jpegData(compressionQuality: 0.8)
                hasImage = true
            }
        }
    }
}

#Preview {
    VStack {
        ModernPhotoPicker(
            selectedImageData: .constant(nil),
            hasImage: .constant(false)
        ) { image in
            print("Image selected")
        }
        
        ImageAttachmentView(
            imageData: .constant(nil),
            hasImage: .constant(false)
        )
    }
    .padding()
}