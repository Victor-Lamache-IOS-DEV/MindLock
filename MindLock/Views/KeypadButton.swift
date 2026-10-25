import SwiftUI

/// Bouton circulaire du clavier de code iOS 18 avec gestion du touch-down et appui long secret
public struct KeypadButton: View {
    let digit: Int
    let letters: String
    let layout: Layout
    let defaultOpacity: Double
    var isProgrammaticallyHighlighted: Bool = false
    var isSecretKeyCandidate: Bool = false

    var onTouchDown: () -> Void
    var onSecretHoldTriggered: () -> Void

    @State private var isTouchPressed: Bool = false
    @State private var holdTimerTask: Task<Void, Never>?
    @State private var didTriggerHold: Bool = false

    public init(
        digit: Int,
        letters: String,
        layout: Layout,
        defaultOpacity: Double,
        isProgrammaticallyHighlighted: Bool = false,
        isSecretKeyCandidate: Bool = false,
        onTouchDown: @escaping () -> Void,
        onSecretHoldTriggered: @escaping () -> Void
    ) {
        self.digit = digit
        self.letters = letters
        self.layout = layout
        self.defaultOpacity = defaultOpacity
        self.isProgrammaticallyHighlighted = isProgrammaticallyHighlighted
        self.isSecretKeyCandidate = isSecretKeyCandidate
        self.onTouchDown = onTouchDown
        self.onSecretHoldTriggered = onSecretHoldTriggered
    }

    private var currentOpacity: Double {
        if isTouchPressed || isProgrammaticallyHighlighted {
            return 0.55
        } else {
            return defaultOpacity
        }
    }

    public var body: some View {
        ZStack {
            // Fond translucide circulaire
            Circle()
                .fill(Color.white.opacity(currentOpacity))
                .frame(width: layout.keypadDiameter, height: layout.keypadDiameter)
                .animation(isTouchPressed ? .none : .easeOut(duration: 0.4), value: isTouchPressed)
                .animation(.easeInOut(duration: 0.12), value: isProgrammaticallyHighlighted)

            // Contenu texte (Chiffre + Lettres)
            VStack(spacing: 0) {
                Text("\(digit)")
                    .font(.system(size: layout.keypadDigitFontSize, weight: .regular))
                    .foregroundColor(.white)
                    .offset(y: letters.isEmpty ? 0 : layout.keypadDigitOffsetY)

                if !letters.isEmpty {
                    Text(letters)
                        .font(.system(size: layout.keypadLettersFontSize, weight: .semibold))
                        .kerning(layout.keypadLettersTracking)
                        .foregroundColor(.white)
                }
            }
        }
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isTouchPressed {
                        handleTouchDown()
                    }
                }
                .onEnded { _ in
                    handleTouchUp()
                }
        )
    }

    private func handleTouchDown() {
        isTouchPressed = true
        didTriggerHold = false

        if isSecretKeyCandidate {
            // Appui secret potentiel : on ne valide pas immédiatement au touch-down
            holdTimerTask?.cancel()
            holdTimerTask = Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1.0 s
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    didTriggerHold = true
                    onSecretHoldTriggered()
                }
            }
        } else {
            // Touche classique : enregistrement au touch-down immédiat
            onTouchDown()
        }
    }

    private func handleTouchUp() {
        isTouchPressed = false
        holdTimerTask?.cancel()
        holdTimerTask = nil

        if isSecretKeyCandidate {
            if !didTriggerHold {
                // Relâché avant 1.0 s : validation normale du chiffre
                onTouchDown()
            }
            didTriggerHold = false
        }
    }
}
