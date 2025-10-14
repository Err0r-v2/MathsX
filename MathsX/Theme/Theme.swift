//
//  Theme.swift
//  MathsX
//
//  Created by Stanislas Paquin on 12/10/2025.
//

import SwiftUI

enum Theme {
    static let neon = Color(hue: 0.68, saturation: 0.08, brightness: 0.95)
    static let cyan = Color(hue: 0.55, saturation: 0.08, brightness: 0.95)
    static let purple = Color(hue: 0.75, saturation: 0.08, brightness: 0.95)

    static let backgroundGradient = LinearGradient(
        colors: [
            Color(white: 0.04),
            Color(white: 0.12)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension View {
    func neonGlow(_ color: Color = .white, radius: CGFloat = 12) -> some View {
        shadow(color: color.opacity(0.25), radius: radius, x: 0, y: 0)
    }
}

