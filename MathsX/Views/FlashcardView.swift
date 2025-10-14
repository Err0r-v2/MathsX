//
//  FlashcardView.swift
//  MathsX
//
//  Created by Stanislas Paquin on 12/10/2025.
//

import SwiftUI

struct FlashcardView: View {
    let deck: Deck
    @ObservedObject var viewModel: DeckViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var dragOffset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var cardScale: CGFloat = 1.0
    
    // Système de révision
    @State private var cardsToReview: [Flashcard] = []
    @State private var knownCards: Set<UUID> = []
    @State private var unknownCards: Set<UUID> = []
    @State private var showingResults = false
    @State private var reviewRound = 1
    
    // Paramètres
    @State private var isDefinitionFirst = true // true = définition/terme, false = terme/définition
    @State private var isKnowledgeMode = true // true = mode trier par connaissance, false = mode normal
    @State private var showingSettings = false
    
    var currentCard: Flashcard? {
        guard currentIndex < cardsToReview.count else { return nil }
        return cardsToReview[currentIndex]
    }
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            
            if showingResults {
                resultsView
            } else {
                reviewView
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupReview()
        }
    }
    
    private var reviewView: some View {
            VStack {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(GlowButtonStyle(verticalPadding: 8, horizontalPadding: 12))
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text("\(currentIndex + 1) / \(cardsToReview.count)")
                        .font(.headline)
                        .foregroundStyle(.white)
                        
                        if reviewRound > 1 {
                            Text("Tour \(reviewRound)")
                                .font(.caption2)
                                .foregroundStyle(Theme.neon)
                        }
                    }
                    
                    Spacer()
                    
                    Menu {
                        // Changer le sens
                        Button("Changer le sens", systemImage: "arrow.left.arrow.right") {
                            isDefinitionFirst.toggle()
                            shuffleCards()
                        }
                        Divider()
                        // Mélanger
                        Button("Mélanger les cartes", systemImage: "shuffle") {
                            shuffleCards()
                        }
                        Divider()
                        // Mode connaissance
                        Toggle(isOn: $isKnowledgeMode) {
                            Label("Trier par connaissance", systemImage: "brain.head.profile")
                        }
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(GlowButtonStyle(verticalPadding: 8, horizontalPadding: 12))
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Theme.neon)
                            .frame(width: geometry.size.width * CGFloat(currentIndex + 1) / CGFloat(max(cardsToReview.count, 1)), height: 6)
                            .neonGlow(Theme.neon, radius: 8)
                    }
                }
                .frame(height: 6)
                .padding(.horizontal, 20)
                .animation(.easeInOut(duration: 0.3), value: currentIndex)
                
                Spacer()
                
                // Flashcard
                if let card = currentCard {
                    cardView(for: card)
                        .scaleEffect(cardScale)
                        .frame(width: UIScreen.main.bounds.width - 64, height: 500)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
            }
        }
    
    private func cardView(for card: Flashcard) -> some View {
        GeometryReader { geometry in
            ZStack {
                // Card back
                CardSide(
                    content: isDefinitionFirst ? card.back : card.front, 
                    isLatex: card.isLatex,
                    borderColor: dragOffset.width > 0 ? Color.green : Color.red,
                    borderOpacity: min(abs(dragOffset.width) / 100.0, 1.0),
                    showSwipeText: isKnowledgeMode && abs(dragOffset.width) > 20,
                    swipeText: isKnowledgeMode ? (dragOffset.width > 0 ? "Connu" : "Pas connu") : "",
                    swipeTextOpacity: isKnowledgeMode ? min(abs(dragOffset.width) / 80.0, 1.0) : 0.0
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .rotation3DEffect(
                    .degrees(180),
                    axis: (x: 0, y: 1, z: 0)
                )
                .opacity(isFlipped ? 1 : 0)
                
                // Card front
                CardSide(
                    content: isDefinitionFirst ? card.front : card.back, 
                    isLatex: card.isLatex,
                    borderColor: dragOffset.width > 0 ? Color.green : Color.red,
                    borderOpacity: min(abs(dragOffset.width) / 100.0, 1.0),
                    showSwipeText: isKnowledgeMode && abs(dragOffset.width) > 20,
                    swipeText: isKnowledgeMode ? (dragOffset.width > 0 ? "Connu" : "Pas connu") : "",
                    swipeTextOpacity: isKnowledgeMode ? min(abs(dragOffset.width) / 80.0, 1.0) : 0.0
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .opacity(isFlipped ? 0 : 1)
            }
            .rotation3DEffect(
                .degrees(isFlipped ? 180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )
            .rotation3DEffect(
                .degrees(rotation),
                axis: (x: 0, y: 0, z: 1)
            )
            .offset(dragOffset)
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                        rotation = Double(value.translation.width / 20)
                    }
                    .onEnded { value in
                        handleDragEnd(value: value)
                    }
            )
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        handleTap()
                    }
            )
        }
        .id(card.id)
    }
    
    private var resultsView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: unknownCards.isEmpty ? "trophy.fill" : "flag.checkered")
                .font(.system(size: 80))
                .foregroundStyle(Theme.neon)
                .neonGlow(Theme.neon, radius: 20)
            
            VStack(spacing: 12) {
                Text(unknownCards.isEmpty ? "Félicitations !" : "Révision terminée !")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                
                if unknownCards.isEmpty {
                    Text("Toutes les cartes sont connues")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.7))
                } else {
                    Text("\(unknownCards.count) carte\(unknownCards.count > 1 ? "s" : "") à réviser")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            
            VStack(spacing: 16) {
                HStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("\(knownCards.count)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.green)
                        Text("Connues")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                    )
                    
                    VStack(spacing: 8) {
                        Text("\(unknownCards.count)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.red)
                        Text("À réviser")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                    )
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            VStack(spacing: 14) {
                if !unknownCards.isEmpty {
                    Button(action: {
                        continueReview()
                    }) {
                        Text("Réviser les cartes non connues")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlowButtonStyle(color: Theme.neon, verticalPadding: 14, horizontalPadding: 24))
                }
                
                Button(action: {
                    dismiss()
                }) {
                    Text(unknownCards.isEmpty ? "Terminer" : "Retour")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlowButtonStyle(verticalPadding: 14, horizontalPadding: 24))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
    
    private func setupReview() {
        cardsToReview = deck.cards.shuffled()
        
        // Animation rapide pour la première carte
        cardScale = 0.0
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8).delay(0.05)) {
            cardScale = 1.0
        }
    }
    
    private func handleTap() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isFlipped.toggle()
        }
    }
    
    private func handleDragEnd(value: DragGesture.Value) {
        if abs(value.translation.width) > 100 {
            // Swipe détecté - animation plus rapide
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                dragOffset = CGSize(
                    width: value.translation.width > 0 ? 500 : -500,
                    height: value.translation.height
                )
                rotation = Double(dragOffset.width / 20)
            }
            
            // Masquer et changer rapidement
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                cardScale = 0.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                if isKnowledgeMode {
                    // Mode trier par connaissance
                    let isKnown = value.translation.width > 0
                    handleSwipe(isKnown: isKnown)
                } else {
                    // Mode normal : passer à la carte suivante
                    nextCard()
                }
            }
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                dragOffset = .zero
                rotation = 0
            }
        }
    }
    
    private func handleSwipe(isKnown: Bool) {
        guard let card = currentCard else { return }
        
        if isKnown {
            knownCards.insert(card.id)
            unknownCards.remove(card.id)
        } else {
            unknownCards.insert(card.id)
            knownCards.remove(card.id)
        }
        
        if currentIndex < cardsToReview.count - 1 {
            currentIndex += 1
            resetCardState()
        } else {
            // Fin du tour de révision
            withAnimation(.easeInOut(duration: 0.3)) {
                showingResults = true
            }
        }
    }
    
    private func resetCardState() {
        isFlipped = false
        dragOffset = .zero
        rotation = 0
        
        // Animation de zoom rapide pour la nouvelle carte
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            cardScale = 1.0
        }
    }
    
    private func continueReview() {
        reviewRound += 1
        
        // Filtrer pour ne garder que les cartes non connues
        cardsToReview = deck.cards.filter { unknownCards.contains($0.id) }.shuffled()
        
        currentIndex = 0
        showingResults = false
        resetCardState()
    }
    
    private func nextCard() {
        // Passer à la carte suivante
        if currentIndex < cardsToReview.count - 1 {
            currentIndex += 1
        } else {
            currentIndex = 0
        }
        // Animation rapide de la nouvelle carte
        isFlipped = false
        dragOffset = .zero
        rotation = 0
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            cardScale = 1.0
        }
    }
    
    private func shuffleCards() {
        cardsToReview = deck.cards.shuffled()
        currentIndex = 0
        isFlipped = false
        dragOffset = .zero
        rotation = 0
        
        // Animation rapide pour la nouvelle carte
        cardScale = 0.0
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            cardScale = 1.0
        }
    }
    
    private var settingsMenu: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Handle
                    Capsule()
                        .fill(.white.opacity(0.3))
                        .frame(width: 40, height: 4)
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                    // Ordre des cartes
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ordre des cartes")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                isDefinitionFirst = true
                                shuffleCards()
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "textformat.abc")
                                        .font(.title2)
                                    Text("Définition → Terme")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isDefinitionFirst ? Theme.neon.opacity(0.3) : Color.white.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(isDefinitionFirst ? Theme.neon : Color.white.opacity(0.2), lineWidth: 2)
                                )
                            }
                            .foregroundStyle(isDefinitionFirst ? Theme.neon : .white)
                            
                            Button(action: {
                                isDefinitionFirst = false
                                shuffleCards()
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "textformat.123")
                                        .font(.title2)
                                    Text("Terme → Définition")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(!isDefinitionFirst ? Theme.neon.opacity(0.3) : Color.white.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(!isDefinitionFirst ? Theme.neon : Color.white.opacity(0.2), lineWidth: 2)
                                )
                            }
                            .foregroundStyle(!isDefinitionFirst ? Theme.neon : .white)
                        }
                    }
                    
                    Divider()
                        .background(.white.opacity(0.2))
                    
                    // Mélanger les cartes
                    Button(action: {
                        shuffleCards()
                        showingSettings = false
                    }) {
                        HStack {
                            Image(systemName: "shuffle")
                                .font(.title3)
                            Text("Mélanger les cartes")
                                .font(.headline)
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .foregroundStyle(.white)
                    
                    Divider()
                        .background(.white.opacity(0.2))
                    
                    // Mode trier par connaissance
                    Toggle(isOn: $isKnowledgeMode) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Mode trier par connaissance")
                                    .font(.headline)
                                Text("Swipe pour marquer connu/pas connu")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                    }
                    .tint(Theme.neon)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(isKnowledgeMode ? Theme.neon : Color.white.opacity(0.2), lineWidth: isKnowledgeMode ? 2 : 1)
                    )
                    .foregroundStyle(.white)
                    .onChange(of: isKnowledgeMode) { _, _ in
                        setupReview()
                    }
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Paramètres")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        showingSettings = false
                    }
                    .foregroundStyle(Theme.neon)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

struct CardSide: View {
    let content: String
    let isLatex: Bool
    let borderColor: Color
    let borderOpacity: Double
    let showSwipeText: Bool
    let swipeText: String
    let swipeTextOpacity: Double
    
    init(content: String, isLatex: Bool, borderColor: Color = Color.white, borderOpacity: Double = 0.18, showSwipeText: Bool = false, swipeText: String = "", swipeTextOpacity: Double = 0.0) {
        self.content = content
        self.isLatex = isLatex
        self.borderColor = borderColor
        self.borderOpacity = borderOpacity
        self.showSwipeText = showSwipeText
        self.swipeText = swipeText
        self.swipeTextOpacity = swipeTextOpacity
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(
                            borderColor.opacity(borderOpacity),
                            lineWidth: 4
                        )
                )
            
            // Contenu normal de la carte (toujours présent, fade out)
            GeometryReader { geo in
                if isLatex {
                    // Utiliser la vue avec auto-shrink + scroll fallback pour éviter toute coupe
                    ScrollView([.horizontal, .vertical], showsIndicators: false) {
                        SwiftMathView(latex: content, fontSize: 42, textColor: .white)
                            .frame(width: geo.size.width - 48, height: geo.size.height - 48)
                            .padding(8)
                    }
                    .frame(width: geo.size.width - 32, height: geo.size.height - 32)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .opacity(1.0 - swipeTextOpacity)
                } else {
                    // Texte simple avec scaleToFit via minimumScaleFactor
                    ScrollView {
                        Text(content)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .minimumScaleFactor(0.5)
                            .padding(12)
                    }
                    .frame(width: geo.size.width - 32, height: geo.size.height - 32)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .opacity(1.0 - swipeTextOpacity)
                }
            }
            
            // Texte de swipe qui apparaît en fade in (plus petit)
            VStack(spacing: 8) {
                Image(systemName: swipeText == "Connu" ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(swipeText == "Connu" ? .green : .red)
                
                Text(swipeText)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(swipeText == "Connu" ? .green : .red)
            }
            .opacity(swipeTextOpacity)
        }
    }
}

#Preview {
    FlashcardView(
        deck: Deck(name: "Test", cards: [
            Flashcard(front: "x^2", back: "x \\times x")
        ]),
        viewModel: DeckViewModel()
    )
}
