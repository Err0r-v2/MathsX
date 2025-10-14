//
//  QuizView.swift
//  MathsX
//
//  Created by Stanislas Paquin on 12/10/2025.
//

import SwiftUI

struct QuizView: View {
    let deck: Deck
    @ObservedObject var viewModel: DeckViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var questions: [QuizQuestion] = []
    @State private var currentIndex = 0
    @State private var selectedOption: Int? = nil
    @State private var correctAnswers = 0
    @State private var showingResults = false
    
    var currentQuestion: QuizQuestion? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            
            if showingResults {
                resultsView
            } else {
                quizView
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupQuiz()
        }
    }
    
    private var quizView: some View {
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
                        
                Text("Question \(currentIndex + 1)/\(questions.count)")
                                .font(.headline)
                                .foregroundStyle(.white)
                        
                        Spacer()
                        
                                Text("\(correctAnswers)")
                                    .font(.headline.bold())
                                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                                Circle()
                            .fill(Color.white.opacity(0.1))
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
            // Progress
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 6)
                            
                    RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.neon)
                        .frame(
                            width: geometry.size.width * CGFloat(currentIndex + 1) / CGFloat(questions.count),
                            height: 6
                        )
                                .neonGlow(Theme.neon, radius: 8)
                        }
                    }
                    .frame(height: 6)
                    .padding(.horizontal, 20)
            .padding(.top, 12)
                    
                    Spacer()
                    
            // Question and options
            if let question = currentQuestion {
                VStack(spacing: 24) {
                    // Question card
                            GlassCard {
                        VStack(spacing: 12) {
                                    Text("Quelle est la réponse ?")
                                        .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                            
                            if question.isLatex {
                                // Debounce à l'affichage pour éviter un flash non parsé
                                CachedSwiftMathView(latex: question.question, fontSize: 22, textColor: .white, debounce: true)
                                    .frame(maxWidth: .infinity)
                                    .frame(minHeight: 80, maxHeight: 140)
                                    .padding(.vertical, 16)
                            } else {
                                Text(question.question)
                                    .font(.title2.bold())
                                            .foregroundStyle(.white)
                                            .multilineTextAlignment(.center)
                                    .padding(.vertical, 20)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal, 20)
                            
                            // Options
                    VStack(spacing: 12) {
                        ForEach(0..<question.options.count, id: \.self) { index in
                            optionButton(
                                text: question.options[index],
                                index: index,
                                isCorrect: index == question.correctIndex,
                                isLatex: question.isLatex
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            Spacer()
        }
    }
    
    private func optionButton(text: String, index: Int, isCorrect: Bool, isLatex: Bool) -> some View {
        let isSelected = selectedOption == index
        let showResult = selectedOption != nil
        let isWrong = isSelected && !isCorrect && showResult
        let showCorrect = isCorrect && showResult
        
        let bgColor: Color = showCorrect ? Color.green.opacity(0.15) : isWrong ? Color.red.opacity(0.15) : Color.white.opacity(0.06)
        let borderColor: Color = showCorrect ? Color.green.opacity(0.4) : isWrong ? Color.red.opacity(0.4) : Color.white.opacity(0.15)
        
        return HStack(spacing: 12) {
            // Content
            if isLatex {
                CachedSwiftMathView(latex: text, fontSize: 14, textColor: .white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: 50)
                    .padding(.vertical, 4)
            } else {
                Text(text)
                    .font(.body)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 4)
            }
            
            // Icon
            if showCorrect {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
            } else if isWrong {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.red)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 70)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(bgColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .overlay(alignment: .center) {
            // Overlay transparent pour capter le tap, sans bloquer les bords arrondis
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.001))
                .contentShape(Rectangle())
                .onTapGesture {
                    if selectedOption == nil {
                        handleAnswer(index: index)
                    }
                }
        }
        .allowsHitTesting(selectedOption == nil)
    }
    
    private var resultsView: some View {
        VStack(spacing: 32) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 80))
                .foregroundStyle(Theme.neon)
                .neonGlow(Theme.neon, radius: 20)
            
            Text("Quiz Terminé!")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
            
            VStack(spacing: 16) {
                Text("\(correctAnswers) / \(questions.count)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.neon)
                    .neonGlow(Theme.neon)
                
                Text("réponses correctes")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.7))
                
                let percentage = Double(correctAnswers) / Double(questions.count) * 100
                Text(String(format: "%.0f%%", percentage))
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                    )
            }
            
            VStack(spacing: 14) {
                Button(action: { 
                    resetQuiz()
                }) {
                    Text("Recommencer")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlowButtonStyle(color: Theme.neon, verticalPadding: 14, horizontalPadding: 24))
                
                Button(action: { dismiss() }) {
                    Text("Retour")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlowButtonStyle(verticalPadding: 14, horizontalPadding: 24))
            }
            .padding(.horizontal, 32)
        }
    }
    
    private func setupQuiz() {
        let shuffledCards = deck.cards.shuffled()
        
        questions = shuffledCards.map { card in
            // Get wrong answers
            let wrongAnswers = deck.cards
                .filter { $0.id != card.id }
                .map { $0.back }
                .filter { $0 != card.back }
                .shuffled()
                .prefix(3)
            
            // Create options array with correct answer
            var options = [card.back] + Array(wrongAnswers)
            options.shuffle()
            
            let correctIndex = options.firstIndex(of: card.back) ?? 0
            
            return QuizQuestion(
                question: card.front,
                options: options,
                correctIndex: correctIndex,
                isLatex: card.isLatex
            )
        }
    }
    
    private func resetQuiz() {
        currentIndex = 0
        selectedOption = nil
        correctAnswers = 0
        showingResults = false
        setupQuiz()
    }
    
    private func handleAnswer(index: Int) {
        guard selectedOption == nil else { return }
        
        selectedOption = index
        
        if let question = currentQuestion, index == question.correctIndex {
            correctAnswers += 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            nextQuestion()
        }
    }
    
    private func nextQuestion() {
        if currentIndex < questions.count - 1 {
            currentIndex += 1
            selectedOption = nil
        } else {
            showingResults = true
        }
    }
}

struct QuizQuestion {
    let question: String
    let options: [String]
    let correctIndex: Int
    let isLatex: Bool
}
