//
//  MathPixService.swift
//  MathsX
//
//  Created by Stanislas Paquin on 13/10/2025.
//

import Foundation
import UIKit

struct MathPixResponse: Codable {
    let text: String
    let latexStyled: String?
    let confidence: Double?
    
    enum CodingKeys: String, CodingKey {
        case text
        case latexStyled = "latex_styled"
        case confidence
    }
}

class MathPixService {
    static let shared = MathPixService()
    
    private init() {}
    
    func recognizeMath(from image: UIImage, appId: String, appKey: String) async throws -> String {
        // Redimensionner l'image si elle est trop grande
        let resizedImage = resizeImageIfNeeded(image)
        
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
            throw MathPixError.imageConversionFailed
        }
        
        print("Image size after resize: \(resizedImage.size)")
        print("Image data size: \(imageData.count) bytes")
        
        let url = URL(string: "https://api.mathpix.com/v3/text")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(appId, forHTTPHeaderField: "app_id")
        request.setValue(appKey, forHTTPHeaderField: "app_key")
        
        let base64Image = imageData.base64EncodedString()
        let body: [String: Any] = [
            "src": "data:image/jpeg;base64,\(base64Image)",
            "formats": ["text", "latex_styled"],
            "data_options": [
                "include_asciimath": true,
                "include_latex": true
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MathPixError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("MathPix Error Response: \(errorString)")
                // Vérifier si c'est une erreur de taille
                if errorString.contains("Request too large") {
                    throw MathPixError.requestTooLarge
                }
            }
            throw MathPixError.apiError(statusCode: httpResponse.statusCode, message: String(data: data, encoding: .utf8))
        }
        
        // Log de debug pour voir la réponse
        if let responseString = String(data: data, encoding: .utf8) {
            print("MathPix Response: \(responseString)")
        }
        
        do {
            let mathPixResponse = try JSONDecoder().decode(MathPixResponse.self, from: data)
            let result = mathPixResponse.latexStyled ?? mathPixResponse.text
            print("MathPix Result: \(result)")
            return result
        } catch {
            print("MathPix JSON Decode Error: \(error)")
            // Vérifier si c'est une réponse d'erreur de MathPix
            if let responseString = String(data: data, encoding: .utf8),
               responseString.contains("error") {
                if responseString.contains("Request too large") {
                    throw MathPixError.requestTooLarge
                }
                throw MathPixError.apiError(statusCode: 200, message: responseString)
            }
            throw MathPixError.jsonParseError(error.localizedDescription)
        }
    }
    
    private func resizeImageIfNeeded(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 3000 // Limite testée avec succès (4000x3000 accepté)
        let currentSize = image.size

        // Si l'image est déjà assez petite, la retourner telle quelle
        if currentSize.width <= maxDimension && currentSize.height <= maxDimension {
            return image
        }

        // Calculer le ratio pour maintenir les proportions
        let ratio = min(maxDimension / currentSize.width, maxDimension / currentSize.height)
        let newSize = CGSize(
            width: currentSize.width * ratio,
            height: currentSize.height * ratio
        )

        print("Resizing image from \(currentSize) to \(newSize)")

        // Redimensionner l'image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage ?? image
    }
}

enum MathPixError: LocalizedError {
    case imageConversionFailed
    case invalidResponse
    case requestTooLarge
    case apiError(statusCode: Int, message: String?)
    case jsonParseError(String)
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Impossible de convertir l'image"
        case .invalidResponse:
            return "Réponse invalide de MathPix"
        case .requestTooLarge:
            return "L'image dépasse 4000x3000 pixels. L'application va la redimensionner automatiquement."
        case .apiError(let statusCode, let message):
            if let message = message {
                return "Erreur MathPix (code \(statusCode)): \(message)"
            } else {
                return "Erreur MathPix (code \(statusCode))"
            }
        case .jsonParseError(let error):
            return "Erreur de parsing MathPix: \(error)"
        }
    }
}
