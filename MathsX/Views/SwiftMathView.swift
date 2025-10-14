//
//  SwiftMathView.swift
//  MathsX
//
//  Created by Stanislas Paquin on 13/10/2025.
//

import SwiftUI
import SwiftMath

// Note: Ce wrapper ajuste dynamiquement la taille de police pour que le contenu tienne
// dans l'espace disponible en largeur et en hauteur, avec une taille minimale.

// Conteneur UIView (autorisé) qui héberge MTMathUILabel et notifie les changements de taille
final class SizeAwareMathContainerView: UIView {
    let label = MTMathUILabel()
    var onBoundsChange: ((CGSize) -> Void)?
    private var lastReportedSize: CGSize = .zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .clear
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size != lastReportedSize {
            lastReportedSize = bounds.size
            onBoundsChange?(bounds.size)
        }
    }
}

// Vue SwiftUI wrapper pour MTMathUILabel avec auto-resize
struct SwiftMathView: UIViewRepresentable {
    let latex: String
    let fontSize: CGFloat
    let textColor: Color
    let textAlignment: MTTextAlignment
    
    init(
        latex: String,
        fontSize: CGFloat = 32,
        textColor: Color = .white,
        textAlignment: MTTextAlignment = .center
    ) {
        self.latex = latex
        self.fontSize = fontSize
        self.textColor = textColor
        self.textAlignment = textAlignment
    }
    
    func makeUIView(context: Context) -> SizeAwareMathContainerView {
        let container = SizeAwareMathContainerView()
        let label = container.label
        label.backgroundColor = .clear
        label.labelMode = .text
        label.textAlignment = textAlignment
        label.contentInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        
        // Assigner le LaTeX dès la création
        label.latex = latex
        
        // Configuration de la police
        if let font = MTFontManager().font(withName: MathFont.latinModernFont.rawValue, size: fontSize) {
            label.font = font
        }
        
        // Pas de retour à la ligne automatique pour MTMathUILabel
        
        context.coordinator.container = container
        context.coordinator.maxFontSize = fontSize
        context.coordinator.minFontSize = max(fontSize * 0.4, 12)
        container.onBoundsChange = { _ in
            context.coordinator.scheduleAdjustFontSizeToFit()
        }
        
        return container
    }
    
    func updateUIView(_ uiView: SizeAwareMathContainerView, context: Context) {
        let label = uiView.label
        
        // Mettre à jour les paramètres
        label.textColor = UIColor(textColor)
        label.textAlignment = textAlignment
        
        context.coordinator.maxFontSize = fontSize
        context.coordinator.minFontSize = max(fontSize * 0.4, 12)
        
        // Toujours mettre à jour le LaTeX pour s'assurer qu'il est affiché
        label.latex = latex
        
        // Mettre à jour la police avec la bonne taille
        if let font = MTFontManager().font(withName: MathFont.latinModernFont.rawValue, size: fontSize) {
            label.font = font
        }
        
        // Pas de retour à la ligne automatique pour MTMathUILabel
        
        // Recalibrer la taille de police après toute mise à jour
        context.coordinator.scheduleAdjustFontSizeToFit()
        label.setNeedsLayout()
        label.setNeedsDisplay()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        weak var container: SizeAwareMathContainerView?
        var maxFontSize: CGFloat = 32
        var minFontSize: CGFloat = 16
        private var pendingWorkItem: DispatchWorkItem?
        
        func scheduleAdjustFontSizeToFit() {
            pendingWorkItem?.cancel()
            let work = DispatchWorkItem { [weak self] in
                self?.adjustFontSizeToFit()
            }
            pendingWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: work)
        }
        
        func adjustFontSizeToFit() {
            guard let container = container else { return }
            let label = container.label
            guard container.bounds.width > 0, container.bounds.height > 0 else { return }
            guard !label.latex.isEmpty else { return }
            
            let availableWidth = container.bounds.width - label.contentInsets.left - label.contentInsets.right
            let availableHeight = container.bounds.height - label.contentInsets.top - label.contentInsets.bottom
            
            guard availableWidth > 20, availableHeight > 20 else { return }
            
            // Pas de retour à la ligne automatique pour MTMathUILabel
            
            var bestFontSize = minFontSize
            var foundFittingSize = false
            
            // Essayer d'abord la taille maximale avec retour à la ligne
            if let testFont = MTFontManager().font(withName: MathFont.latinModernFont.rawValue, size: maxFontSize) {
                label.font = testFont
                let size = label.sizeThatFits(CGSize(width: availableWidth, height: .greatestFiniteMagnitude))
                
                // Si ça rentre en largeur et hauteur, utiliser la taille max
                if size.height <= availableHeight && size.width <= availableWidth {
                    foundFittingSize = true
                    bestFontSize = maxFontSize
                    return
                }
            }
            
            // Sinon, utiliser une recherche binaire pour s'adapter à la hauteur disponible
            var low = minFontSize
            var high = maxFontSize
            
            while high - low > 0.5 {
                let fontSize = (low + high) / 2
                
                if let testFont = MTFontManager().font(withName: MathFont.latinModernFont.rawValue, size: fontSize) {
                    label.font = testFont
                    
                    // Calculer la taille requise
                    let size = label.sizeThatFits(CGSize(width: availableWidth, height: .greatestFiniteMagnitude))
                    
                    // Si ça rentre en largeur et hauteur, essayer plus grand
                    if size.height <= availableHeight && size.width <= availableWidth {
                        bestFontSize = fontSize
                        foundFittingSize = true
                        low = fontSize
                    } else {
                        // Trop grand, essayer plus petit
                        high = fontSize
                    }
                }
            }
            
            // Appliquer la meilleure taille trouvée
            let finalSize = foundFittingSize ? bestFontSize : minFontSize
            if let finalFont = MTFontManager().font(withName: MathFont.latinModernFont.rawValue, size: finalSize) {
                label.font = finalFont
                label.setNeedsLayout()
                label.layoutIfNeeded()
            }
        }
    }
}

// Vue avec cache et support debounce pour les previews
struct CachedSwiftMathView: View {
    let latex: String
    let fontSize: CGFloat
    let textColor: Color
    let textAlignment: MTTextAlignment
    let debounce: Bool
    
    @State private var debouncedLatex: String = ""
    @State private var debounceTask: Task<Void, Never>?
    
    init(
        latex: String,
        fontSize: CGFloat = 32,
        textColor: Color = .white,
        textAlignment: MTTextAlignment = .center,
        debounce: Bool = false
    ) {
        self.latex = latex
        self.fontSize = fontSize
        self.textColor = textColor
        self.textAlignment = textAlignment
        self.debounce = debounce
        _debouncedLatex = State(initialValue: latex)
    }
    
    var body: some View {
        SwiftMathView(
            latex: debounce ? debouncedLatex : latex,
            fontSize: fontSize,
            textColor: textColor,
            textAlignment: textAlignment
        )
        .onChange(of: latex) { _, newValue in
            if debounce {
                // Annuler la tâche précédente
                debounceTask?.cancel()
                
                // Créer une nouvelle tâche avec délai
                debounceTask = Task {
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconde
                    if !Task.isCancelled {
                        debouncedLatex = newValue
                    }
                }
            }
        }
    }
}

// Vue simple sans auto-ajustement (pour usage dans ScrollView)
struct SimpleSwiftMathView: UIViewRepresentable {
    let latex: String
    let fontSize: CGFloat
    let textColor: Color
    let textAlignment: MTTextAlignment
    let enableLineBreaks: Bool
    let maxLayoutWidth: CGFloat?

    init(
        latex: String,
        fontSize: CGFloat = 32,
        textColor: Color = .white,
        textAlignment: MTTextAlignment = .center,
        enableLineBreaks: Bool = true,
        maxLayoutWidth: CGFloat? = nil
    ) {
        self.latex = latex
        self.fontSize = fontSize
        self.textColor = textColor
        self.textAlignment = textAlignment
        self.enableLineBreaks = enableLineBreaks
        self.maxLayoutWidth = maxLayoutWidth
    }
    
    func makeUIView(context: Context) -> MTMathUILabel {
        let label = MTMathUILabel()
        label.backgroundColor = .clear
        label.labelMode = .text
        label.textAlignment = textAlignment
        label.latex = latex
        label.textColor = UIColor(textColor)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .vertical)

        // Configuration pour permettre les retours à la ligne automatiques
        if enableLineBreaks {
            // Pour les anciennes versions de SwiftMath, utiliser le mode display
            // qui permet un meilleur rendu des expressions longues
            label.labelMode = .display
        }

        if let font = MTFontManager().font(withName: MathFont.latinModernFont.rawValue, size: fontSize) {
            label.font = font
        }

        return label
    }
    
    func updateUIView(_ uiView: MTMathUILabel, context: Context) {
        uiView.latex = latex
        uiView.textColor = UIColor(textColor)
        uiView.textAlignment = textAlignment

        // Configuration pour permettre les retours à la ligne automatiques
        if enableLineBreaks {
            // Pour les anciennes versions de SwiftMath, utiliser le mode display
            // qui permet un meilleur rendu des expressions longues
            uiView.labelMode = .display
        } else {
            uiView.labelMode = .text
        }

        if let font = MTFontManager().font(withName: MathFont.latinModernFont.rawValue, size: fontSize) {
            uiView.font = font
        }

        uiView.invalidateIntrinsicContentSize()
        uiView.setNeedsDisplay()
    }

    // iOS 16+: permettre à SwiftUI de demander la taille idéale du label
    static func sizeThatFits(_ proposal: ProposedViewSize, uiView: MTMathUILabel, context: Context) -> CGSize {
        let targetWidth = proposal.width ?? CGFloat.greatestFiniteMagnitude
        let targetHeight = proposal.height ?? CGFloat.greatestFiniteMagnitude

        // Pour permettre le line wrapping, donner une largeur contrainte si elle est définie
        let constrainedWidth = min(targetWidth, 400) // Limiter à 400px max pour forcer le wrapping
        let size = uiView.sizeThatFits(CGSize(width: constrainedWidth, height: targetHeight))

        // Éviter les tailles nulles pour que le ScrollView affiche bien le contenu
        return CGSize(width: max(size.width, 1), height: max(size.height, 1))
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ScrollView {
            VStack(spacing: 30) {
                Text("Tests du line wrapping automatique SwiftMath")
                    .font(.headline)
                    .foregroundColor(.white)

                // Test 1: Formule courte
                VStack(spacing: 8) {
                    Text("Formule courte:").foregroundColor(.white)
                    SimpleSwiftMathView(
                        latex: "x^2 + 2x + 1 = 0",
                        fontSize: 24,
                        textColor: .white,
                        enableLineBreaks: true
                    )
                    .frame(width: 300, height: 60)
                }

                // Test 2: Équation moyenne
                VStack(spacing: 8) {
                    Text("Équation moyenne:").foregroundColor(.white)
                    SimpleSwiftMathView(
                        latex: "x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}",
                        fontSize: 20,
                        textColor: .cyan,
                        enableLineBreaks: true
                    )
                    .frame(width: 300, height: 100)
                }

                // Test 3: Expression très longue (devrait wrap)
                VStack(spacing: 8) {
                    Text("Expression très longue:").foregroundColor(.white)
                    SimpleSwiftMathView(
                        latex: "\\frac{d}{dx} \\left( x^3 + 3x^2 \\cdot 2 + 6x \\cdot 1 + 6 \\right) = 3x^2 + 6x + 6",
                        fontSize: 18,
                        textColor: .green,
                        enableLineBreaks: true
                    )
                    .frame(width: 300, height: 120)
                }

                // Test 4: Texte avec espaces (devrait wrap naturellement)
                VStack(spacing: 8) {
                    Text("Avec espaces:").foregroundColor(.white)
                    SimpleSwiftMathView(
                        latex: "a b c d e f g h i j k l m n o p q r s t u v w x y z",
                        fontSize: 20,
                        textColor: .yellow,
                        enableLineBreaks: true
                    )
                    .frame(width: 300, height: 150)
                }

                // Test 5: Même chose sans line breaks
                VStack(spacing: 8) {
                    Text("Sans line wrapping:").foregroundColor(.white)
                    SimpleSwiftMathView(
                        latex: "a b c d e f g h i j k l m n o p q r s t u v w x y z",
                        fontSize: 20,
                        textColor: .red,
                        enableLineBreaks: false
                    )
                    .frame(width: 300, height: 80)
                }

                // Test 6: LaTeX complexe qui devrait wrap
                VStack(spacing: 8) {
                    Text("LaTeX complexe:").foregroundColor(.white)
                    SimpleSwiftMathView(
                        latex: "\\int_{a}^{b} f(x) \\, dx = F(b) - F(a) \\quad \\text{où } F \\text{ est la primitive de } f",
                        fontSize: 16,
                        textColor: .purple,
                        enableLineBreaks: true
                    )
                    .frame(width: 300, height: 120)
                }
            }
            .padding()
        }
    }
}





