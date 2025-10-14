//
//  GlowButton.swift
//  MathsX
//
//  Created by Stanislas Paquin on 12/10/2025.
//

import SwiftUI

struct GlowButtonStyle: ButtonStyle {
    var color: Color = .white
    var cornerRadius: CGFloat = 14
    var font: Font = .headline
    var verticalPadding: CGFloat = 12
    var horizontalPadding: CGFloat = 18

    func makeBody(configuration: Configuration) -> some View {
        let background = color.opacity(configuration.isPressed ? 0.12 : 0.10)
        let stroke = color.opacity(0.18)
        let shadowOpacity = configuration.isPressed ? 0.20 : 0.35

        return configuration.label
            .font(font)
            .foregroundStyle(Color.white)
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(stroke, lineWidth: 1)
            )
            .shadow(color: color.opacity(shadowOpacity), radius: configuration.isPressed ? 6 : 14)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

