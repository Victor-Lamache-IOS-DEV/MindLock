import SwiftUI
import Combine

/// Fausse barre d'état iOS 18 dessinée en blanc pur
public struct FakeStatusBar: View {
    let layout: Layout
    let carrierName: String
    let cellularBars: Int
    let showWifi: Bool
    let showControlCenterIndicator: Bool

    @State private var batteryLevel: Float = 1.0
    @State private var isCharging: Bool = false
    @State private var timerSubscription: AnyCancellable?

    public init(
        layout: Layout,
        carrierName: String,
        cellularBars: Int,
        showWifi: Bool,
        showControlCenterIndicator: Bool
    ) {
        self.layout = layout
        self.carrierName = carrierName
        self.cellularBars = cellularBars
        self.showWifi = showWifi
        self.showControlCenterIndicator = showControlCenterIndicator
    }

    public var body: some View {
        ZStack(alignment: .top) {
            // Ligne principale de la barre d'état (Opérateur à gauche, Icônes à droite)
            HStack(alignment: .center) {
                Text(carrierName)
                    .font(.system(size: layout.carrierFontSize, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.leading, layout.carrierLeftX)

                Spacer()

                HStack(alignment: .center, spacing: layout.rightIconSpacing) {
                    // Signal cellulaire dessiné
                    cellularSignalView

                    // Icône Wi-Fi
                    if showWifi {
                        Image(systemName: "wifi")
                            .font(.system(size: layout.wifiFontSize, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    // Batterie dessinée
                    batteryView
                }
                .padding(.trailing, max(0, layout.screenWidth - layout.batteryRightX))
            }
            .frame(width: layout.screenWidth)
            .position(x: layout.screenWidth / 2.0, y: layout.carrierCenterY)

            // Indicateur du Centre de contrôle (sur LOCK uniquement)
            if showControlCenterIndicator {
                let width = layout.controlCenterEndX - layout.controlCenterStartX
                Capsule()
                    .fill(Color.white.opacity(layout.controlCenterOpacity))
                    .frame(width: width, height: layout.controlCenterThickness)
                    .position(
                        x: layout.controlCenterStartX + (width / 2.0),
                        y: layout.controlCenterY
                    )
            }
        }
        .frame(width: layout.screenWidth, height: layout.screenHeight, alignment: .top)
        .allowsHitTesting(false)
        .onAppear {
            updateBatteryStatus()
            UIDevice.current.isBatteryMonitoringEnabled = true
            timerSubscription = Timer.publish(every: 30, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    updateBatteryStatus()
                }
        }
        .onDisappear {
            timerSubscription?.cancel()
        }
    }

    // MARK: - Signal Cellulaire (4 barres dessinées)
    private var cellularSignalView: some View {
        HStack(alignment: .bottom, spacing: layout.signalBarSpacing) {
            ForEach(0..<4, id: \.self) { index in
                let height = (index < layout.signalBarHeights.count) ? layout.signalBarHeights[index] : 8.0
                let isFilled = index < cellularBars

                RoundedRectangle(cornerRadius: layout.signalCornerRadius)
                    .fill(Color.white.opacity(isFilled ? 1.0 : 0.30))
                    .frame(width: layout.signalBarWidth, height: height)
            }
        }
        .frame(height: 12, alignment: .bottom)
    }

    // MARK: - Batterie
    private var batteryView: some View {
        HStack(spacing: layout.batteryCapOffset) {
            // Corps de la batterie
            ZStack(alignment: .leading) {
                // Contour
                RoundedRectangle(cornerRadius: layout.batteryCornerRadius)
                    .stroke(Color.white.opacity(0.35), lineWidth: layout.batteryStrokeWidth)
                    .frame(width: layout.batteryBodyWidth, height: layout.batteryBodyHeight)

                // Remplissage intérieur
                let maxInnerWidth = max(0, layout.batteryBodyWidth - (layout.batteryInnerPadding * 2))
                let innerHeight = max(0, layout.batteryBodyHeight - (layout.batteryInnerPadding * 2))
                let fillWidth = maxInnerWidth * CGFloat(max(0.05, min(1.0, batteryLevel)))

                RoundedRectangle(cornerRadius: max(1, layout.batteryCornerRadius - 1))
                    .fill(batteryFillColor)
                    .frame(width: fillWidth, height: innerHeight)
                    .padding(.leading, layout.batteryInnerPadding)

                // Éclair de charge
                if isCharging {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: layout.batteryBoltSize, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: layout.batteryBodyWidth, height: layout.batteryBodyHeight)
                }
            }

            // Embout de la batterie (à droite)
            RoundedRectangle(cornerRadius: 1.0)
                .fill(Color.white.opacity(0.40))
                .frame(width: layout.batteryCapWidth, height: layout.batteryCapHeight)
        }
    }

    private var batteryFillColor: Color {
        if isCharging {
            return Color(red: 0.19, green: 0.82, blue: 0.35) // Vert #30D158
        } else if batteryLevel < 0.20 {
            return Color(red: 1.0, green: 0.23, blue: 0.19) // Rouge #FF3B30
        } else {
            return Color.white
        }
    }

    private func updateBatteryStatus() {
        let level = UIDevice.current.batteryLevel
        batteryLevel = (level < 0) ? 0.75 : level
        let state = UIDevice.current.batteryState
        isCharging = (state == .charging || state == .full)
    }
}
