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
    // Contrôles IA
    @State private var cardRigor: Double = 0.6
    @State private var cardQuantity: Double = 10
    
    // IA States
    @State private var isAIExpanded: Bool = false
    @State private var showMultiImagePicker = false
    @State private var showCamera = false
    @State private var capturedImage: UIImage? = nil
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

                            // (Supprimé) Import rapide JSON brut
                            
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
                                    // Image selection (multi)
                                    VStack(spacing: 12) {
                                        if !selectedImages.isEmpty {
                                            // Thumbnails grid
                                            ScrollView(.horizontal, showsIndicators: false) {
                                                HStack(spacing: 10) {
                                                    ForEach(Array(selectedImages.enumerated()), id: \.0) { index, image in
                                                        ZStack(alignment: .topTrailing) {
                                                            Image(uiImage: image)
                                                                .resizable()
                                                                .scaledToFill()
                                                                .frame(width: 100, height: 100)
                                                                .clipped()
                                                                .cornerRadius(10)
                                                            Button(action: { selectedImages.remove(at: index) }) {
                                                                Image(systemName: "xmark.circle.fill")
                                                                    .font(.subheadline)
                                                                    .foregroundStyle(.white)
                                                                    .background(Circle().fill(Color.black.opacity(0.5)))
                                                            }
                                                            .padding(4)
                                                        }
                                                    }
                                                }
                                            }
                                        }

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
                                                    Image(systemName: "photo.on.rectangle.angled")
                                                        .font(.title2)
                                                    Text("Galerie (multi)")
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

                                    // Rigueur des cartes
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("Rigueur des cartes")
                                                .font(.caption)
                                                .foregroundStyle(.white.opacity(0.7))
                                            Spacer()
                                            Text("\(Int(cardRigor * 100))%")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.white.opacity(0.9))
                                        }
                                        Slider(value: $cardRigor, in: 0...1)
                                            .tint(Theme.neon)
                                    }

                                    // Quantité (approx.)
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("Quantité (approx.)")
                                                .font(.caption)
                                                .foregroundStyle(.white.opacity(0.7))
                                            Spacer()
                                            Text("\(Int(cardQuantity))")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.white.opacity(0.9))
                                        }
                                        Slider(value: $cardQuantity, in: 1...30, step: 1)
                                            .tint(Theme.neon)
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
            .sheet(isPresented: $showMultiImagePicker) {
                MultiImagePicker(images: $selectedImages)
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(image: $capturedImage, sourceType: .camera)
            }
            .onChange(of: capturedImage) { newValue in
                if let image = newValue {
                    selectedImages.append(image)
                    capturedImage = nil
                }
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
        // PHPicker ne nécessite pas de vérification de disponibilité comme UIImagePickerController
        showMultiImagePicker = true
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
        
        print("Starting AI generation...")
        print("Images count: \(selectedImages.count)")
        print("Instructions: \(aiInstructions)")
        
        Task {
            await MainActor.run {
                isProcessingAI = true
                aiError = nil
            }
            
            do {
                print("Step 1: Calling MathPix for each image...")
                var latexResults: [String] = []
                for (idx, img) in selectedImages.enumerated() {
                    print("MathPix image #\(idx+1) size: \(img.size)")
                    let latexContent = try await MathPixService.shared.recognizeMath(
                        from: img,
                        appId: mathPixAppId,
                        appKey: mathPixAppKey
                    )
                    latexResults.append(latexContent)
                }
                let combinedLatex = latexResults.joined(separator: "\n\n")
                print("Combined LaTeX length: \(combinedLatex.count)")

                print("Step 2: Calling Groq...")
                // Step 2: Generate flashcards with Groq
                let cards = try await GroqService.shared.generateFlashcards(
                    latexContent: combinedLatex,
                    userInstructions: aiInstructions,
                    rigor: cardRigor,
                    quantityHint: Int(cardQuantity),
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
    
}
