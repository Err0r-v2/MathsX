//
//  CreateDeckView.swift
//  MathsX
//
//  Created by Stanislas Paquin on 12/10/2025.
//

import SwiftUI
import UIKit

struct CreateDeckView: View {
    @ObservedObject var viewModel: DeckViewModel
    @ObservedObject var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedColor = "purple"
    @State private var rawImportText = ""
    @State private var importedCards: [Flashcard] = []
    @State private var importError: String? = nil
    @State private var isImportExpanded: Bool = false
    
    // IA States
    @State private var isAIExpanded: Bool = false
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var selectedImages: [UIImage] = []
    @State private var aiInstructions = ""
    @State private var isProcessingAI = false
    @State private var aiError: String? = nil
    @State private var aiGeneratedCards: [Flashcard] = []
    
    let folderId: UUID?
    let colors = ["purple", "blue", "green", "orange", "pink"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(GlowButtonStyle(verticalPadding: 8, horizontalPadding: 12))
                        
                        Spacer()
                        
                        Text("Nouveau Deck")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        Button(action: createDeck) {
                            Text("Créer")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(GlowButtonStyle(color: Theme.neon, verticalPadding: 8, horizontalPadding: 16))
                        .disabled(name.isEmpty)
                        .opacity(name.isEmpty ? 0.5 : 1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Nom")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.7))
                                
                                TextField("Ex: Trigonométrie", text: $name)
                                    .font(.body)
                                    .foregroundStyle(.white)
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color.white.opacity(0.06))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.7))
                                
                                TextField("Ex: Formules trigonométriques", text: $description)
                                    .font(.body)
                                    .foregroundStyle(.white)
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color.white.opacity(0.06))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                            }

                            // Raw JSON import section
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Import rapide (JSON brut)")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.7))
                                    Spacer()
                                    Button(action: { withAnimation { isImportExpanded.toggle() } }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: isImportExpanded ? "chevron.up" : "chevron.down")
                                            Text(isImportExpanded ? "Masquer" : "Afficher")
                                        }
                                        .font(.footnote.weight(.medium))
                                        .foregroundStyle(.white.opacity(0.9))
                                    }
                                }
                                if isImportExpanded {
                                    TextEditor(text: $rawImportText)
                                        .font(.system(size: 14, design: .monospaced))
                                        .foregroundStyle(.white)
                                        .frame(minHeight: 140)
                                        .scrollContentBackground(.hidden)
                                        .padding(12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(Color.white.opacity(0.06))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                        )
                                        .onChange(of: rawImportText) { _ in
                                            parseRawImport()
                                        }

                                    if let importError {
                                        HStack(spacing: 8) {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundStyle(.yellow)
                                            Text(importError)
                                                .font(.footnote)
                                        }
                                        .foregroundStyle(.white.opacity(0.9))
                                        .padding(10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(Color.yellow.opacity(0.1))
                                        )
                                    } else if !importedCards.isEmpty {
                                        HStack(spacing: 8) {
                                            Image(systemName: "checkmark.seal.fill")
                                                .foregroundStyle(Theme.neon)
                                            Text("\(importedCards.count) cartes prêtes à être ajoutées")
                                                .font(.footnote)
                                        }
                                        .foregroundStyle(.white.opacity(0.9))
                                        .padding(10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(Theme.neon.opacity(0.08))
                                        )
                                    } else {
                                        Text("Collez un tableau JSON d'objets { front, back, isLatex }.")
                                            .font(.footnote)
                                            .foregroundStyle(.white.opacity(0.6))
                                    }
                                }
                            }
                            
                            // AI Generation Section
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    HStack(spacing: 8) {
                                        Image(systemName: "sparkles")
                                            .foregroundStyle(Theme.neon)
                                        Text("Génération IA")
                                            .font(.subheadline)
                                            .foregroundStyle(.white.opacity(0.7))
                                    }
                                    Spacer()
                                    Button(action: { withAnimation { isAIExpanded.toggle() } }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: isAIExpanded ? "chevron.up" : "chevron.down")
                                            Text(isAIExpanded ? "Masquer" : "Afficher")
                                        }
                                        .font(.footnote.weight(.medium))
                                        .foregroundStyle(.white.opacity(0.9))
                                    }
                                }
                                
                                if isAIExpanded {
                                    // Images sélectionnées
                                    if !selectedImages.isEmpty {
                                        VStack(alignment: .leading, spacing: 12) {
                                            Text("\(selectedImages.count) image(s) sélectionnée(s)")
                                                .font(.caption)
                                                .foregroundStyle(.white.opacity(0.7))
                                            
                                            ScrollView(.horizontal, showsIndicators: false) {
                                                HStack(spacing: 12) {
                                                    ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                                                        ZStack(alignment: .topTrailing) {
                                                            Image(uiImage: image)
                                                                .resizable()
                                                                .scaledToFill()
                                                                .frame(width: 120, height: 120)
                                                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                                            
                                                            Button(action: { removeImage(at: index) }) {
                                                                Image(systemName: "xmark.circle.fill")
                                                                    .font(.title3)
                                                                    .foregroundStyle(.white)
                                                                    .background(Circle().fill(Color.black.opacity(0.5)))
                                                            }
                                                            .padding(6)
                                                        }
                                                    }
                                                    
                                                    // Bouton pour ajouter plus d'images
                                                    Button(action: openGallery) {
                                                        VStack(spacing: 8) {
                                                            Image(systemName: "plus")
                                                                .font(.title2)
                                                            Text("Ajouter")
                                                                .font(.caption)
                                                        }
                                                        .foregroundStyle(.white)
                                                        .frame(width: 120, height: 120)
                                                        .background(
                                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                                .fill(Color.white.opacity(0.06))
                                                        )
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                                        )
                                                    }
                                                }
                                            }
                                        }
                                    } else {
                                        HStack(spacing: 12) {
                                            Button(action: openCamera) {
                                                VStack(spacing: 8) {
                                                    Image(systemName: "camera.fill")
                                                        .font(.title2)
                                                    Text("Photo")
                                                        .font(.caption)
                                                }
                                                .foregroundStyle(.white)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 20)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .fill(Color.white.opacity(0.06))
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                                )
                                            }
                                            
                                            Button(action: openGallery) {
                                                VStack(spacing: 8) {
                                                    Image(systemName: "photo.fill")
                                                        .font(.title2)
                                                    Text("Galerie")
                                                        .font(.caption)
                                                }
                                                .foregroundStyle(.white)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 20)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .fill(Color.white.opacity(0.06))
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                                )
                                            }
                                        }
                                    }
                                    
                                    // Instructions
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Instructions pour l'IA")
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.7))
                                        
                                        TextField("Ex: Crée des flashcards pour réviser ces formules", text: $aiInstructions)
                                            .font(.body)
                                            .foregroundStyle(.white)
                                            .padding(14)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .fill(Color.white.opacity(0.06))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                            )
                                    }
                                    
                                    // Generate button
                                    Button(action: generateWithAI) {
                                        HStack(spacing: 8) {
                                            if isProcessingAI {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                Text("Génération en cours...")
                                            } else {
                                                Image(systemName: "sparkles")
                                                Text("Générer avec l'IA")
                                            }
                                        }
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(Theme.neon)
                                        )
                                    }
                                    .disabled(selectedImages.isEmpty || aiInstructions.isEmpty || isProcessingAI)
                                    .opacity(selectedImages.isEmpty || aiInstructions.isEmpty || isProcessingAI ? 0.5 : 1)
                                    
                                    // Error or success message
                                    if let aiError {
                                        HStack(spacing: 8) {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundStyle(.red)
                                            Text(aiError)
                                                .font(.footnote)
                                        }
                                        .foregroundStyle(.white.opacity(0.9))
                                        .padding(10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(Color.red.opacity(0.1))
                                        )
                                    } else if !aiGeneratedCards.isEmpty {
                                        HStack(spacing: 8) {
                                            Image(systemName: "checkmark.seal.fill")
                                                .foregroundStyle(Theme.neon)
                                            Text("\(aiGeneratedCards.count) cartes générées par l'IA")
                                                .font(.footnote)
                                        }
                                        .foregroundStyle(.white.opacity(0.9))
                                        .padding(10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(Theme.neon.opacity(0.08))
                                        )
                                    }
                                    
                                    // Info
                                    if settingsManager.settings.groqApiKey.isEmpty || settingsManager.settings.mathPixAppId.isEmpty {
                                        HStack(spacing: 8) {
                                            Image(systemName: "info.circle")
                                                .foregroundStyle(.orange)
                                            Text("Configurez vos clés API dans les réglages")
                                                .font(.footnote)
                                        }
                                        .foregroundStyle(.white.opacity(0.9))
                                        .padding(10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(Color.orange.opacity(0.1))
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showImagePicker) {
                MultipleImagePicker(images: $selectedImages)
            }
            .sheet(isPresented: $showCamera) {
                SingleImagePickerForCamera(onImageSelected: { image in
                    selectedImages.append(image)
                })
            }
        }
    }
    
    private func createDeck() {
        var newDeck = Deck(
            name: name,
            description: description,
            color: selectedColor,
            folderId: folderId
        )
        if !importedCards.isEmpty {
            newDeck.cards.append(contentsOf: importedCards)
        }
        if !aiGeneratedCards.isEmpty {
            newDeck.cards.append(contentsOf: aiGeneratedCards)
        }
        viewModel.addDeck(newDeck)
        dismiss()
    }
    
    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            aiError = "La caméra n'est pas disponible sur cet appareil"
            return
        }
        showCamera = true
    }
    
    private func openGallery() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            aiError = "La galerie photo n'est pas disponible"
            return
        }
        showImagePicker = true
    }
    
    private func removeImage(at index: Int) {
        selectedImages.remove(at: index)
    }
    
    private func generateWithAI() {
        guard !selectedImages.isEmpty else { 
            aiError = "Aucune image sélectionnée"
            return 
        }
        guard !aiInstructions.isEmpty else { 
            aiError = "Veuillez ajouter des instructions"
            return 
        }
        
        // Check API keys
        let groqKey = settingsManager.settings.groqApiKey
        let mathPixAppId = settingsManager.settings.mathPixAppId
        let mathPixAppKey = settingsManager.settings.mathPixAppKey
        
        guard !groqKey.isEmpty, !mathPixAppId.isEmpty, !mathPixAppKey.isEmpty else {
            aiError = "Veuillez configurer vos clés API dans les réglages"
            return
        }
        
        print("Starting AI generation with \(selectedImages.count) images...")
        print("Instructions: \(aiInstructions)")
        
        Task {
            await MainActor.run {
                isProcessingAI = true
                aiError = nil
            }
            
            do {
                // Step 1: Recognize math from all images with MathPix
                var allLatexContent: [String] = []
                for (index, image) in selectedImages.enumerated() {
                    print("Processing image \(index + 1)/\(selectedImages.count)...")
                    let latexContent = try await MathPixService.shared.recognizeMath(
                        from: image,
                        appId: mathPixAppId,
                        appKey: mathPixAppKey
                    )
                    allLatexContent.append(latexContent)
                    print("Image \(index + 1) MathPix result: \(latexContent)")
                }
                
                // Combiner tout le contenu LaTeX
                let combinedLatex = allLatexContent.enumerated().map { index, content in
                    "Image \(index + 1):\n\(content)"
                }.joined(separator: "\n\n")
                
                print("Step 2: Calling Groq with combined content...")
                // Step 2: Generate flashcards with Groq
                let cards = try await GroqService.shared.generateFlashcards(
                    latexContent: combinedLatex,
                    userInstructions: aiInstructions,
                    apiKey: groqKey
                )
                print("Generated \(cards.count) cards")
                
                await MainActor.run {
                    aiGeneratedCards = cards
                    isProcessingAI = false
                    print("AI generation completed successfully")
                }
            } catch {
                print("AI generation error: \(error)")
                await MainActor.run {
                    aiError = error.localizedDescription
                    isProcessingAI = false
                }
            }
        }
    }

    private func parseRawImport() {
        importError = nil
        importedCards = []
        let trimmed = rawImportText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let data = trimmed.data(using: .utf8) else {
            importError = "Encodage invalide."
            return
        }
        do {
            struct ImportedCard: Decodable {
                let front: String
                let back: String
                let isLatex: Bool?
            }
            let decoder = JSONDecoder()
            let items = try decoder.decode([ImportedCard].self, from: data)
            let cards = items.map { item in
                Flashcard(front: item.front, back: item.back, isLatex: item.isLatex ?? true)
            }
            importedCards = cards
        } catch {
            importError = "JSON invalide: \(error.localizedDescription)"
        }
    }
}
