//
//  MultiImagePicker.swift
//  MathsX
//
//  Created by Assistant on 15/10/2025.
//

import SwiftUI
import PhotosUI
import UIKit

struct MultiImagePicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    var selectionLimit: Int = 0 // 0 = unlimited

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = selectionLimit
        configuration.filter = .images
        configuration.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MultiImagePicker

        init(_ parent: MultiImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard !results.isEmpty else {
                picker.dismiss(animated: true)
                return
            }

            let itemProviders = results.map { $0.itemProvider }
            var loadedImages: [UIImage] = []

            let dispatchGroup = DispatchGroup()

            for provider in itemProviders where provider.canLoadObject(ofClass: UIImage.self) {
                dispatchGroup.enter()
                provider.loadObject(ofClass: UIImage.self) { object, error in
                    defer { dispatchGroup.leave() }
                    if let image = object as? UIImage {
                        loadedImages.append(image)
                    }
                }
            }

            dispatchGroup.notify(queue: .main) {
                // Append to existing images
                self.parent.images.append(contentsOf: loadedImages)
                picker.dismiss(animated: true)
            }
        }
    }
}
