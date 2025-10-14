//
//  ImagePicker.swift
//  MathsX
//
//  Created by Stanislas Paquin on 13/10/2025.
//

import SwiftUI
import UIKit
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    let sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        
        // Vérifier la disponibilité de la source
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            // Si la source n'est pas disponible, créer un controller vide et fermer
            let alertController = UIAlertController(
                title: "Non disponible",
                message: sourceType == .camera ? "La caméra n'est pas disponible sur cet appareil" : "La galerie photo n'est pas disponible",
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                DispatchQueue.main.async {
                    dismiss()
                }
            })
            
            let hostingController = UIHostingController(rootView: EmptyView())
            DispatchQueue.main.async {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = scene.windows.first {
                    window.rootViewController?.present(alertController, animated: true)
                }
            }
            return picker
        }
        
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        
        // Configurer les types de média autorisés
        if sourceType == .camera {
            picker.cameraCaptureMode = .photo
            picker.cameraDevice = .rear
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
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Multiple Image Picker
struct MultipleImagePicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 0 // 0 = unlimited
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MultipleImagePicker
        
        init(_ parent: MultipleImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard !results.isEmpty else { return }
            
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                        if let image = image as? UIImage {
                            DispatchQueue.main.async {
                                self?.parent.images.append(image)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Single Image Picker for Camera
struct SingleImagePickerForCamera: UIViewControllerRepresentable {
    let onImageSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            let alertController = UIAlertController(
                title: "Non disponible",
                message: "La caméra n'est pas disponible sur cet appareil",
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                DispatchQueue.main.async {
                    dismiss()
                }
            })
            
            let hostingController = UIHostingController(rootView: EmptyView())
            DispatchQueue.main.async {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = scene.windows.first {
                    window.rootViewController?.present(alertController, animated: true)
                }
            }
            return picker
        }
        
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        picker.cameraCaptureMode = .photo
        picker.cameraDevice = .rear
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: SingleImagePickerForCamera
        
        init(_ parent: SingleImagePickerForCamera) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageSelected(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

