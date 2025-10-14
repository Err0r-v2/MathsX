//
//  EditDeckView.swift
//  MathsX
//
//  Created by Stanislas Paquin on 12/10/2025.
//

import SwiftUI
import UIKit

struct EditDeckView: View {
    let deckId: UUID
    @ObservedObject var viewModel: DeckViewModel
    @ObservedObject var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingCreateCard = false
    @State private var cardToDelete: Flashcard? = nil
    @State private var showingDeleteAlert = false
    @State private var cardToEdit: Flashcard? = nil
    
    // IA States
    @State private var isAIExpanded: Bool = false
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var selectedImages: [UIImage] = []
    @State private var aiInstructions = ""
    @State private var isProcessingAI = false
    @State private var aiError: String? = nil
    
    private var deck: Deck? {
        viewModel.decks.first(where: { $0.id == deckId })
    }
    
    var body: some View {
        Group {
            if let currentDeck = deck {
                editDeckContent(for: currentDeck)
            } else {
                Text("Deck non trouvé")
                    .foregroundStyle(.white)
            }
        }
    }
    
    private func editDeckContent(for currentDeck: Deck) -> some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(GlowButtonStyle(verticalPadding: 8, horizontalPadding: 12))
                    
                    Spacer()
                    
                    Text("Modifier le Deck")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    // Placeholder for symmetry
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Add card button
                        Button(action: { showingCreateCard = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Theme.neon)
                                
                                Text("Ajouter une Carte")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                
                                Spacer()
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.white.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(Theme.neon.opacity(0.3), lineWidth: 1.5)
                            )
                        }
                        
                        // AI Generation Section
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                HStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                        .foregroundStyle(Theme.neon)
                                    Text("Générer avec IA")
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
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                            
                            if isAIExpanded {
                                VStack(spacing: 16) {
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
                                                    Button(action: { showImagePicker = true }) {
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
                                            Button(action: { showCamera = true }) {
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
                                            
                                            Button(action: { showImagePicker = true }) {
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
                                                Text("Générer et ajouter au deck")
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
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.white.opacity(0.03))
                                )
                            }
                        }
                        
                        // Cards list
                        if !currentDeck.cards.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("\(currentDeck.cards.count) cartes")
                                    .font(.headline)
                                    .foregroundStyle(.white.opacity(0.7))
                                
                                ForEach(currentDeck.cards) { card in
                                    EditableCardRow(card: card, onEdit: {
                                        cardToEdit = card
                                    }, onDelete: {
                                        cardToDelete = card
                                        showingDeleteAlert = true
                                    })
                                }
                            }
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "tray")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.white.opacity(0.3))
                                
                                Text("Aucune carte")
                                    .font(.headline)
                                    .foregroundStyle(.white.opacity(0.5))
                                
                                Text("Ajoutez des cartes pour commencer")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingCreateCard) {
            CreateCardView(deckId: currentDeck.id, viewModel: viewModel)
        }
        .sheet(item: $cardToEdit) { card in
            EditCardView(deckId: currentDeck.id, card: card, viewModel: viewModel)
        }
        .sheet(isPresented: $showImagePicker) {
            MultipleImagePicker(images: $selectedImages)
        }
        .sheet(isPresented: $showCamera) {
            SingleImagePickerForCamera(onImageSelected: { image in
                selectedImages.append(image)
            })
        }
        .alert("Supprimer la carte ?", isPresented: $showingDeleteAlert) {
            Button("Annuler", role: .cancel) { }
            Button("Supprimer", role: .destructive) {
                if let card = cardToDelete {
                    viewModel.deleteCard(card, from: currentDeck)
                }
            }
        } message: {
            Text("Cette action est irréversible.")
        }
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
                    // Ajouter les cartes au deck
                    for card in cards {
                        viewModel.addCard(to: deckId, card: card)
                    }
                    
                    // Réinitialiser l'état
                    selectedImages = []
                    aiInstructions = ""
                    isProcessingAI = false
                    isAIExpanded = false
                    
                    print("AI generation completed successfully - added \(cards.count) cards to deck")
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

struct EditableCardRow: View {
    let card: Flashcard
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var dragOffsetX: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 12) {
            // Card content (tappable)
            VStack(alignment: .leading, spacing: 8) {
                if card.isLatex {
                    CachedSwiftMathView(latex: card.front, fontSize: 14, textColor: .white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 50)
                        .clipped()
                } else {
                    Text(card.front)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                if card.isLatex {
                    CachedSwiftMathView(latex: card.back, fontSize: 12, textColor: .white.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 40)
                        .clipped()
                } else {
                    Text(card.back)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture { onEdit() }
        }
        .padding(14)
        .frame(minHeight: 100)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            ZStack(alignment: .trailing) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                // Icône poubelle qui apparaît visuellement lors du swipe gauche
                Image(systemName: "trash.fill")
                    .font(.headline)
                    .foregroundStyle(.red)
                    .opacity(max(0, min(1, (-dragOffsetX) / 80)))
                    .padding(.trailing, 16)
            }
        )
        .overlay(alignment: .leading) {
            // Overlay transparent cliquable (pleine largeur)
            Rectangle()
                .fill(Color.white.opacity(0.001))
                .contentShape(Rectangle())
                .onTapGesture { onEdit() }
        }
        .offset(x: dragOffsetX)
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Ne considérer que le swipe gauche
                    dragOffsetX = min(0, value.translation.width)
                }
                .onEnded { value in
                    let shouldDelete = value.translation.width < -80
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffsetX = 0
                    }
                    if shouldDelete {
                        onDelete()
                    }
                }
        )
    }
}

