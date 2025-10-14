//
//  Flashcard.swift
//  MathsX
//
//  Created by Stanislas Paquin on 12/10/2025.
//

import Foundation

struct Flashcard: Identifiable, Codable {
    let id: UUID
    var front: String
    var back: String
    var isLatex: Bool
    var lastReviewed: Date?
    var correctCount: Int
    var incorrectCount: Int
    
    init(id: UUID = UUID(), front: String, back: String, isLatex: Bool = true) {
        self.id = id
        self.front = front
        self.back = back
        self.isLatex = isLatex
        self.lastReviewed = nil
        self.correctCount = 0
        self.incorrectCount = 0
    }
}

struct Deck: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var color: String
    var cards: [Flashcard]
    var createdDate: Date
    var folderId: UUID? // ID du dossier parent (nil si à la racine)
    
    init(id: UUID = UUID(), name: String, description: String = "", color: String = "blue", cards: [Flashcard] = [], folderId: UUID? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.color = color
        self.cards = cards
        self.createdDate = Date()
        self.folderId = folderId
    }
}

struct Folder: Identifiable, Codable {
    let id: UUID
    var name: String
    var icon: String
    var color: String
    var createdDate: Date
    var parentId: UUID? // Pour supporter les dossiers imbriqués
    
    init(id: UUID = UUID(), name: String, icon: String = "folder.fill", color: String = "cyan", parentId: UUID? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.createdDate = Date()
        self.parentId = parentId
    }
}

