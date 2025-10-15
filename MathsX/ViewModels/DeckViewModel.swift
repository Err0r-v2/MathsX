//
//  DeckViewModel.swift
//  MathsX
//
//  Created by Stanislas Paquin on 12/10/2025.
//

import Foundation
import SwiftUI
import Combine

class DeckViewModel: ObservableObject {
    @Published var decks: [Deck] = []
    @Published var folders: [Folder] = []
    
    private let decksPath = FileManager.documentsDirectory.appendingPathComponent("decks.json")
    private let foldersPath = FileManager.documentsDirectory.appendingPathComponent("folders.json")
    
    init() {
        loadDecks()
        loadFolders()
        if decks.isEmpty {
            createSampleDecks()
        }
    }
    
    // MARK: - Deck Methods
    func addDeck(_ deck: Deck) {
        decks.append(deck)
        saveDecks()
    }
    
    func updateDeck(_ deck: Deck) {
        if let index = decks.firstIndex(where: { $0.id == deck.id }) {
            decks[index] = deck
            saveDecks()
        }
    }
    
    func deleteDeck(_ deck: Deck) {
        decks.removeAll { $0.id == deck.id }
        saveDecks()
    }
    
    func moveDeck(_ deck: Deck, to folderId: UUID?) {
        if let index = decks.firstIndex(where: { $0.id == deck.id }) {
            decks[index].folderId = folderId
            saveDecks()
        }
    }
    
    func decks(in folderId: UUID?) -> [Deck] {
        return decks.filter { $0.folderId == folderId }
    }
    
    // MARK: - Folder Methods
    func addFolder(_ folder: Folder) {
        folders.append(folder)
        saveFolders()
    }
    
    func updateFolder(_ folder: Folder) {
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            folders[index] = folder
            saveFolders()
        }
    }
    
    func deleteFolder(_ folder: Folder) {
        // Déplacer tous les decks du dossier vers la racine
        for index in decks.indices {
            if decks[index].folderId == folder.id {
                decks[index].folderId = nil
            }
        }
        // Déplacer tous les sous-dossiers vers la racine
        for index in folders.indices {
            if folders[index].parentId == folder.id {
                folders[index].parentId = nil
            }
        }
        folders.removeAll { $0.id == folder.id }
        saveFolders()
        saveDecks()
    }
    
    func folders(in parentId: UUID?) -> [Folder] {
        return folders.filter { $0.parentId == parentId }
    }
    
    func addCard(to deckId: UUID, card: Flashcard) {
        if let index = decks.firstIndex(where: { $0.id == deckId }) {
            decks[index].cards.append(card)
            saveDecks()
        }
    }
    
    func addCards(to deckId: UUID, cards: [Flashcard]) {
        guard !cards.isEmpty else { return }
        if let index = decks.firstIndex(where: { $0.id == deckId }) {
            decks[index].cards.append(contentsOf: cards)
            saveDecks()
        }
    }
    
    func updateCard(in deckId: UUID, card: Flashcard) {
        if let deckIndex = decks.firstIndex(where: { $0.id == deckId }),
           let cardIndex = decks[deckIndex].cards.firstIndex(where: { $0.id == card.id }) {
            decks[deckIndex].cards[cardIndex] = card
            saveDecks()
        }
    }
    
    func deleteCard(from deckId: UUID, cardId: UUID) {
        if let index = decks.firstIndex(where: { $0.id == deckId }) {
            decks[index].cards.removeAll { $0.id == cardId }
            saveDecks()
        }
    }
    
    func deleteCard(_ card: Flashcard, from deck: Deck) {
        deleteCard(from: deck.id, cardId: card.id)
    }
    
    // MARK: - Persistence
    private func saveDecks() {
        do {
            let data = try JSONEncoder().encode(decks)
            try data.write(to: decksPath)
        } catch {
            print("Unable to save decks: \(error.localizedDescription)")
        }
    }
    
    private func loadDecks() {
        do {
            let data = try Data(contentsOf: decksPath)
            decks = try JSONDecoder().decode([Deck].self, from: data)
        } catch {
            print("Unable to load decks: \(error.localizedDescription)")
        }
    }
    
    private func saveFolders() {
        do {
            let data = try JSONEncoder().encode(folders)
            try data.write(to: foldersPath)
        } catch {
            print("Unable to save folders: \(error.localizedDescription)")
        }
    }
    
    private func loadFolders() {
        do {
            let data = try Data(contentsOf: foldersPath)
            folders = try JSONDecoder().decode([Folder].self, from: data)
        } catch {
            print("Unable to load folders: \(error.localizedDescription)")
        }
    }
    
    private func createSampleDecks() {
        let calculus = Deck(
            name: "Calcul Différentiel",
            description: "Dérivées et intégrales",
            color: "purple",
            cards: [
                Flashcard(front: "\\frac{d}{dx}(x^n)", back: "nx^{n-1}"),
                Flashcard(front: "\\int x^n dx", back: "\\frac{x^{n+1}}{n+1} + C"),
                Flashcard(front: "\\frac{d}{dx}(e^x)", back: "e^x"),
                Flashcard(front: "\\frac{d}{dx}(\\ln x)", back: "\\frac{1}{x}")
            ]
        )
        
        let algebra = Deck(
            name: "Algèbre",
            description: "Identités remarquables",
            color: "blue",
            cards: [
                Flashcard(front: "(a+b)^2", back: "a^2 + 2ab + b^2"),
                Flashcard(front: "(a-b)^2", back: "a^2 - 2ab + b^2"),
                Flashcard(front: "a^2 - b^2", back: "(a+b)(a-b)"),
                Flashcard(front: "(a+b)^3", back: "a^3 + 3a^2b + 3ab^2 + b^3")
            ]
        )
        
        let trigonometry = Deck(
            name: "Trigonométrie",
            description: "Formules trigonométriques",
            color: "green",
            cards: [
                Flashcard(front: "\\sin^2(x) + \\cos^2(x)", back: "1"),
                Flashcard(front: "\\sin(2x)", back: "2\\sin(x)\\cos(x)"),
                Flashcard(front: "\\cos(2x)", back: "\\cos^2(x) - \\sin^2(x)"),
                Flashcard(front: "\\tan(x)", back: "\\frac{\\sin(x)}{\\cos(x)}")
            ]
        )
        
        decks = [calculus, algebra, trigonometry]
        saveDecks()
    }
}

extension FileManager {
    static var documentsDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}

