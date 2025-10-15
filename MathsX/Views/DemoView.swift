//
//  DemoView.swift
//  MathsX
//
//  Created by Assistant on 15/10/2025.
//

import SwiftUI

struct DemoView: View {
    @State private var latex: String = "x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}"
    @State private var fontSize: Double = 32
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Démo")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                        .neonGlow()
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Controls
                VStack(alignment: .leading, spacing: 10) {
                    Text("LaTeX")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    TextField("Entrer du LaTeX", text: $latex)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.15), lineWidth: 1))
                    
                    HStack {
                        Text("Taille: \(Int(fontSize))")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                        Slider(value: $fontSize, in: 16...64)
                            .tint(Theme.neon)
                    }
                }
                .padding(.horizontal, 20)
                
                // Preview
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                    
                    SwiftMathView(latex: latex, fontSize: CGFloat(fontSize))
                        .padding()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 260)
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
    }
}

#Preview {
    DemoView()
}
