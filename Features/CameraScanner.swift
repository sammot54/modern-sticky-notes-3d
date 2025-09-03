import SwiftUI
import VisionKit
import Vision

struct CameraScanner: UIViewControllerRepresentable {
    @Binding var recognizedText: String
    @Binding var isPresented: Bool
    let onTextRecognized: (String) -> Void
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: CameraScanner
        
        init(_ parent: CameraScanner) {
            self.parent = parent
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            // Process scanned pages
            var allText = ""
            
            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                
                // Perform OCR on the image
                recognizeText(in: image) { text in
                    allText += text + "\n\n"
                    
                    if pageIndex == scan.pageCount - 1 {
                        DispatchQueue.main.async {
                            self.parent.recognizedText = allText
                            self.parent.onTextRecognized(allText)
                            self.parent.isPresented = false
                        }
                    }
                }
            }
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Document scanner failed with error: \(error)")
            parent.isPresented = false
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.isPresented = false
        }
        
        private func recognizeText(in image: UIImage, completion: @escaping (String) -> Void) {
            guard let cgImage = image.cgImage else {
                completion("")
                return
            }
            
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    print("Text recognition error: \(error)")
                    completion("")
                    return
                }
                
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                completion(recognizedText)
            }
            
            // Configure for accurate text recognition
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US"]
            request.usesLanguageCorrection = true
            
            do {
                try requestHandler.perform([request])
            } catch {
                print("Failed to perform text recognition: \(error)")
                completion("")
            }
        }
    }
}

struct LiveTextScanner: View {
    @State private var showingCamera = false
    @State private var recognizedText = ""
    @Environment(\.modelContext) private var modelContext
    
    let onTextRecognized: (String) -> Void
    
    var body: some View {
        Button(action: {
            showingCamera = true
        }) {
            HStack {
                Image(systemName: "doc.text.viewfinder")
                    .font(.title2)
                Text("Scan Text")
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding()
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .sheet(isPresented: $showingCamera) {
            CameraScanner(
                recognizedText: $recognizedText,
                isPresented: $showingCamera,
                onTextRecognized: onTextRecognized
            )
        }
        .accessibilityLabel("Scan text with camera")
        .accessibilityHint("Opens camera to scan and recognize text from documents")
    }
}

struct TextRecognitionView: View {
    @State private var selectedImage: UIImage?
    @State private var recognizedText = ""
    @State private var isProcessing = false
    @State private var showingImagePicker = false
    
    let onTextRecognized: (String) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary, lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(height: 200)
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("Select an image to scan")
                                .foregroundColor(.secondary)
                        }
                    )
            }
            
            HStack(spacing: 16) {
                Button(action: {
                    showingImagePicker = true
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("Choose Image")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                
                if selectedImage != nil {
                    Button(action: {
                        processImage()
                    }) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "text.viewfinder")
                            }
                            Text(isProcessing ? "Processing..." : "Extract Text")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(isProcessing ? Color.gray : Color.green)
                        .cornerRadius(10)
                    }
                    .disabled(isProcessing)
                }
            }
            
            if !recognizedText.isEmpty {
                ScrollView {
                    Text(recognizedText)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .textSelection(.enabled)
                }
                
                Button(action: {
                    onTextRecognized(recognizedText)
                }) {
                    Text("Create Note from Text")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }
    
    private func processImage() {
        guard let image = selectedImage,
              let cgImage = image.cgImage else { return }
        
        isProcessing = true
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { request, error in
            DispatchQueue.main.async {
                self.isProcessing = false
                
                if let error = error {
                    print("Text recognition error: \(error)")
                    return
                }
                
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                self.recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
            }
        }
        
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]
        request.usesLanguageCorrection = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    print("Failed to perform text recognition: \(error)")
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
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
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    VStack {
        LiveTextScanner { text in
            print("Recognized text: \(text)")
        }
        
        TextRecognitionView { text in
            print("Text from image: \(text)")
        }
    }
}