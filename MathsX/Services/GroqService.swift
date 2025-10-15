//
//  GroqService.swift
//  MathsX
//
//  Created by Stanislas Paquin on 13/10/2025.
//

import Foundation

struct GroqMessage: Codable {
    let role: String
    let content: String
}

struct GroqRequest: Codable {
    let model: String
    let messages: [GroqMessage]
    let temperature: Double
    let maxTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case maxTokens = "max_tokens"
    }
}

struct GroqResponse: Codable {
    let choices: [GroqChoice]
}

struct GroqChoice: Codable {
    let message: GroqMessage
}

class GroqService {
    static let shared = GroqService()
    
    private init() {}
    
    func generateFlashcards(latexContent: String, userInstructions: String, apiKey: String) async throws -> [Flashcard] {
        // Charger le prompt depuis le fichier
        guard let promptTemplate = loadPromptTemplate() else {
            throw GroqError.promptLoadFailed
        }
        
        // Remplacer les placeholders
        let prompt = promptTemplate
            .replacingOccurrences(of: "{latex_content}", with: latexContent)
            .replacingOccurrences(of: "{user_instructions}", with: userInstructions)
        
        let url = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let groqRequest = GroqRequest(
            model: "moonshotai/kimi-k2-instruct-0905",
            messages: [
                GroqMessage(role: "user", content: prompt)
            ],
            temperature: 0.3,
            maxTokens: 4000
        )
        
        request.httpBody = try JSONEncoder().encode(groqRequest)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GroqError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("Groq Error Response: \(errorMessage)")
            throw GroqError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        // Log de debug pour voir la réponse
        if let responseString = String(data: data, encoding: .utf8) {
            print("Groq Response: \(responseString)")
        }
        
        let groqResponse = try JSONDecoder().decode(GroqResponse.self, from: data)
        
        guard let content = groqResponse.choices.first?.message.content else {
            throw GroqError.noContent
        }
        
        print("Groq Content: \(content)")
        
        // Parser le JSON retourné par Groq
        return try parseFlashcardsFromJSON(content)
    }
    
    private func loadPromptTemplate() -> String? {
        guard let url = Bundle.main.url(forResource: "prompts", withExtension: "txt"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            // Fallback si le fichier n'est pas trouvé
            return """
            Tu es un assistant spécialisé dans la création de flashcards mathématiques.
            
            À partir du contenu LaTeX fourni et des instructions de l'utilisateur, génère un tableau JSON de flashcards.
            
            Format: [{"front": "question", "back": "réponse", "isLatex": true}]
            
            Contenu LaTeX: {latex_content}
            Instructions: {user_instructions}
            """
        }
        return content
    }
    
    private func parseFlashcardsFromJSON(_ jsonString: String) throws -> [Flashcard] {
        print("Raw JSON from Groq: \(jsonString)")
        
        // Nettoyer le JSON (enlever les markdown code blocks si présents)
        var cleanedJSON = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanedJSON.hasPrefix("```json") {
            cleanedJSON = cleanedJSON.replacingOccurrences(of: "```json", with: "")
        }
        if cleanedJSON.hasPrefix("```") {
            cleanedJSON = cleanedJSON.replacingOccurrences(of: "```", with: "")
        }
        if cleanedJSON.hasSuffix("```") {
            cleanedJSON = String(cleanedJSON.dropLast(3))
        }
        
        cleanedJSON = cleanedJSON.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Corriger les problèmes courants de LaTeX mal échappé
        cleanedJSON = fixLatexEscaping(cleanedJSON)
        
        print("Cleaned JSON: \(cleanedJSON)")
        
        struct FlashcardJSON: Codable {
            let front: String
            let back: String
            let isLatex: Bool?
        }
        
        guard let data = cleanedJSON.data(using: .utf8) else {
            print("Failed to convert cleaned JSON to data")
            throw GroqError.jsonParseFailed
        }
        
        do {
            let flashcardJSONs = try JSONDecoder().decode([FlashcardJSON].self, from: data)
            print("Successfully parsed \(flashcardJSONs.count) flashcards")
            
            return flashcardJSONs.map { json in
                let cleanFront = cleanLatexContent(json.front)
                let cleanBack = cleanLatexContent(json.back)
                return Flashcard(front: cleanFront, back: cleanBack, isLatex: json.isLatex ?? true)
            }
        } catch {
            print("JSON Decode Error: \(error)")
            print("Failed JSON: \(cleanedJSON)")
            throw GroqError.jsonParseFailed
        }
    }
    
    private func fixLatexEscaping(_ jsonString: String) -> String {
        var fixed = jsonString
        
        // Corriger les quadruples backslashes (\\\\text) → doubles backslashes (\\text)
        fixed = fixed.replacingOccurrences(of: "\\\\\\\\text", with: "\\\\text")
        fixed = fixed.replacingOccurrences(of: "\\\\\\\\frac", with: "\\\\frac")
        fixed = fixed.replacingOccurrences(of: "\\\\\\\\int", with: "\\\\int")
        fixed = fixed.replacingOccurrences(of: "\\\\\\\\sum", with: "\\\\sum")
        fixed = fixed.replacingOccurrences(of: "\\\\\\\\lim", with: "\\\\lim")
        
        return fixed
    }
    
    private func cleanLatexContent(_ content: String) -> String {
        var cleaned = content
        
        // Remplacer les commandes non supportées par SwiftMath
        cleaned = cleaned.replacingOccurrences(of: "\\implies", with: "\\Rightarrow")
        cleaned = cleaned.replacingOccurrences(of: "\\dots", with: "\\cdots")
        
        // Nettoyer les espacements excessifs
        cleaned = cleaned.replacingOccurrences(of: "  ", with: " ")
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned
    }
}

enum GroqError: LocalizedError {
    case promptLoadFailed
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case noContent
    case jsonParseFailed
    
    var errorDescription: String? {
        switch self {
        case .promptLoadFailed:
            return "Impossible de charger le template de prompt"
        case .invalidResponse:
            return "Réponse invalide de Groq"
        case .apiError(let statusCode, let message):
            return "Erreur Groq (code \(statusCode)): \(message)"
        case .noContent:
            return "Aucun contenu dans la réponse de Groq"
        case .jsonParseFailed:
            return "Impossible de parser le JSON généré par Groq"
        }
    }
}

