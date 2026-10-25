import SwiftUI
import PhotosUI

/// Vue complète des réglages secrets de l'application
public struct SettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var volumeService: VolumeCodeService
    @ObservedObject var imageStore: ImageStore

    var onDismiss: () -> Void
    var onLaunchCalibration: () -> Void

    // PhotosPicker items
    @State private var wallpaperPickerItem: PhotosPickerItem?
    @State private var homePickerItem: PhotosPickerItem?
    @State private var notifIconPickerItem: PhotosPickerItem?
    @State private var calibLockPickerItem: PhotosPickerItem?
    @State private var calibPasscodePickerItem: PhotosPickerItem?

    // États d'alerte et prévisualisation
    @State private var showCopiedAlert: Bool = false
    @State private var showResetAlert: Bool = false
    @State private var showNotifPreview: Bool = false
    @State private var showVolumeTester: Bool = false

    public init(
        settingsStore: SettingsStore,
        volumeService: VolumeCodeService,
        imageStore: ImageStore,
        onDismiss: @escaping () -> Void,
        onLaunchCalibration: @escaping () -> Void
    ) {
        self.settingsStore = settingsStore
        self.volumeService = volumeService
        self.imageStore = imageStore
        self.onDismiss = onDismiss
        self.onLaunchCalibration = onLaunchCalibration
    }

    public var body: some View {
        NavigationStack {
            Form {
                modeSection
                codesSection
                mindModeSection
                volumeSection
                notificationSection
                appearanceSection
                calibrationSection
                endSection
                memoSection
            }
            .environment(\.colorScheme, .dark)
            .navigationTitle("Réglages MindLock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") {
                        onDismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                }
            }
            .alert("Mise en page copiée !", isPresented: $showCopiedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Le JSON de la mise en page a été copié dans le presse-papiers.")
            }
            .alert("Réinitialiser la mise en page ?", isPresented: $showResetAlert) {
                Button("Annuler", role: .cancel) {}
                Button("Réinitialiser", role: .destructive) {
                    settingsStore.resetLayout()
                }
            } message: {
                Text("Toutes les mesures de position et de taille reviendront aux valeurs d'origine.")
            }
            .sheet(isPresented: $showNotifPreview) {
                notificationPreviewSheet
            }
            .sheet(isPresented: $showVolumeTester) {
                volumeTesterSheet
            }
        }
    }

    // MARK: - 1. Mode de tour
    private var modeSection: some View {
        Section(header: Text("Mode de tour")) {
            Picker("Mode", selection: $settingsStore.settings.mode) {
                ForEach(TrickMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)

            Text(settingsStore.settings.mode.summaryDescription)
                .font(.footnote)
                .foregroundColor(.gray)
        }
    }

    // MARK: - 2. Codes
    private var codesSection: some View {
        Section(header: Text("Codes secrets")) {
            HStack {
                Text("Code par défaut")
                Spacer()
                TextField("2580", text: $settingsStore.settings.defaultCode)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
            }

            HStack {
                Text("Code d'accès réglages")
                Spacer()
                TextField("1111", text: $settingsStore.settings.secretSettingsCode)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
            }

            HStack {
                Text("Code armé (volume)")
                Spacer()
                if let armed = volumeService.armedCode {
                    Text(armed)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Button("Effacer") {
                        volumeService.clearArmedCode()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                } else {
                    Text("Aucun")
                        .foregroundColor(.gray)
                }
            }

            Toggle("Le premier essai échoue", isOn: $settingsStore.settings.firstAttemptFails)
        }
    }

    // MARK: - 3. Mode Mind
    private var mindModeSection: some View {
        Section(header: Text("Mode Mind (Saisie automatique)")) {
            Picker("Déclencheur", selection: $settingsStore.settings.mindTrigger) {
                ForEach(MindTrigger.allCases) { trigger in
                    Text(trigger.rawValue).tag(trigger)
                }
            }

            if settingsStore.settings.mindTrigger == .delay {
                Stepper("Délai de démarrage : \(Int(settingsStore.settings.mindDelaySeconds)) s",
                        value: $settingsStore.settings.mindDelaySeconds, in: 1...30)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Vitesse entre chiffres : \(String(format: "%.1f", settingsStore.settings.mindMinDigitDelay)) s – \(String(format: "%.1f", settingsStore.settings.mindMaxDigitDelay)) s")
                    .font(.footnote)
                HStack {
                    Text("Min")
                    Slider(value: $settingsStore.settings.mindMinDigitDelay, in: 0.3...2.0, step: 0.1)
                }
                HStack {
                    Text("Max")
                    Slider(value: $settingsStore.settings.mindMaxDigitDelay, in: 0.5...3.0, step: 0.1)
                }
            }
        }
    }

    // MARK: - 4. Volume
    private var volumeSection: some View {
        Section(header: Text("Saisie secrète au volume")) {
            Stepper("Validation d'un chiffre : \(String(format: "%.1f", settingsStore.settings.digitCommitTimeout)) s",
                    value: $settingsStore.settings.digitCommitTimeout, in: 1.0...3.0, step: 0.5)
            .onChange(of: settingsStore.settings.digitCommitTimeout) { val in
                volumeService.updateTimeouts(
                    digitTimeout: val,
                    codeTimeout: settingsStore.settings.codeCompletionTimeout,
                    hapticPerDigit: settingsStore.settings.hapticPerDigit
                )
            }

            Stepper("Fin du code : \(String(format: "%.1f", settingsStore.settings.codeCompletionTimeout)) s",
                    value: $settingsStore.settings.codeCompletionTimeout, in: 2.5...6.0, step: 0.5)
            .onChange(of: settingsStore.settings.codeCompletionTimeout) { val in
                volumeService.updateTimeouts(
                    digitTimeout: settingsStore.settings.digitCommitTimeout,
                    codeTimeout: val,
                    hapticPerDigit: settingsStore.settings.hapticPerDigit
                )
            }

            Toggle("Haptique par chiffre validé", isOn: $settingsStore.settings.hapticPerDigit)
                .onChange(of: settingsStore.settings.hapticPerDigit) { val in
                    volumeService.updateTimeouts(
                        digitTimeout: settingsStore.settings.digitCommitTimeout,
                        codeTimeout: settingsStore.settings.codeCompletionTimeout,
                        hapticPerDigit: val
                    )
                }

            Button(action: { showVolumeTester = true }) {
                HStack {
                    Image(systemName: "speaker.wave.2.fill")
                    Text("Tester la saisie au volume en direct")
                }
            }
        }
    }

    // MARK: - 5. Notification N26
    private var notificationSection: some View {
        Section(header: Text("Fausse notification")) {
            HStack {
                Text("Nom de l'app")
                Spacer()
                TextField("N26", text: $settingsStore.settings.notifAppName)
                    .multilineTextAlignment(.trailing)
            }

            HStack {
                Text("Titre")
                Spacer()
                TextField("Remboursement reçu", text: $settingsStore.settings.notifTitle)
                    .multilineTextAlignment(.trailing)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Modèle du message")
                    .font(.footnote)
                    .foregroundColor(.gray)
                TextField("Modèle", text: $settingsStore.settings.notifBodyTemplate, axis: .vertical)
                    .lineLimit(2...4)
            }

            HStack {
                Text("Icône personnalisée")
                Spacer()
                if let icon = imageStore.image(for: .notifIcon) {
                    Image(uiImage: icon)
                        .resizable()
                        .frame(width: 30, height: 30)
                        .cornerRadius(6)
                    Button("Supprimer") {
                        imageStore.remove(slot: .notifIcon)
                    }
                    .font(.caption)
                    .tint(.red)
                }
                PhotosPicker("Importer", selection: $notifIconPickerItem, matching: .images)
                    .onChange(of: notifIconPickerItem) { item in
                        loadPickerItem(item, for: .notifIcon)
                    }
            }

            Picker("Masquage automatique", selection: $settingsStore.settings.notifAutoHide) {
                ForEach(NotifAutoHide.allCases) { opt in
                    Text(opt.rawValue).tag(opt)
                }
            }

            Button(action: { showNotifPreview = true }) {
                HStack {
                    Image(systemName: "bell.badge.fill")
                    Text("Aperçu de la notification (Code 2580)")
                }
            }
        }
    }

    // MARK: - 6. Apparence
    private var appearanceSection: some View {
        Section(header: Text("Apparence iOS 18")) {
            HStack {
                Text("Fond d'écran verrouillé")
                Spacer()
                PhotosPicker("Choisir image", selection: $wallpaperPickerItem, matching: .images)
                    .onChange(of: wallpaperPickerItem) { item in
                        loadPickerItem(item, for: .wallpaper)
                    }
            }

            HStack {
                Text("Zoom fond")
                Slider(value: $settingsStore.settings.layout.wallpaperZoom, in: 1.00...1.30, step: 0.01)
                Text(String(format: "%.2f", settingsStore.settings.layout.wallpaperZoom))
                    .frame(width: 40)
            }

            HStack {
                Text("Décalage Y fond")
                Slider(value: $settingsStore.settings.layout.wallpaperOffsetY, in: -60...60, step: 1.0)
                Text("\(Int(settingsStore.settings.layout.wallpaperOffsetY)) pt")
                    .frame(width: 45)
            }

            HStack {
                Text("Capture écran d'accueil")
                Spacer()
                PhotosPicker("Choisir image", selection: $homePickerItem, matching: .images)
                    .onChange(of: homePickerItem) { item in
                        loadPickerItem(item, for: .home)
                    }
            }

            HStack {
                Text("Opérateur")
                Spacer()
                TextField("Tele2", text: $settingsStore.settings.carrierName)
                    .multilineTextAlignment(.trailing)
            }

            Stepper("Barres de réseau : \(settingsStore.settings.cellularBars)",
                    value: $settingsStore.settings.cellularBars, in: 1...4)

            Toggle("Afficher le Wi-Fi", isOn: $settingsStore.settings.showWifi)

            Picker("Do Not Disturb", selection: $settingsStore.settings.dndOption) {
                ForEach(DNDOption.allCases) { opt in
                    Text(opt.rawValue).tag(opt)
                }
            }

            Picker("Format de la date", selection: $settingsStore.settings.dateFormat) {
                ForEach(DateFormatOption.allCases) { opt in
                    Text(opt.rawValue).tag(opt)
                }
            }

            Toggle("Zéro devant l'heure (09:05)", isOn: $settingsStore.settings.leadingZeroInHour)

            Picker("Graisse de l'heure", selection: $settingsStore.settings.timeFontWeight) {
                ForEach(TimeFontWeight.allCases) { weight in
                    Text(weight.rawValue).tag(weight)
                }
            }

            HStack {
                Text("Flou du code")
                Slider(value: $settingsStore.settings.passcodeBlurRadius, in: 10...50)
                Text("\(Int(settingsStore.settings.passcodeBlurRadius))")
                    .frame(width: 30)
            }

            HStack {
                Text("Assombrissement du code")
                Slider(value: $settingsStore.settings.passcodeDarkeningOpacity, in: 0...0.60)
                Text("\(Int(settingsStore.settings.passcodeDarkeningOpacity * 100))%")
                    .frame(width: 40)
            }

            HStack {
                Text("Opacité des touches")
                Slider(value: $settingsStore.settings.keypadButtonOpacity, in: 0.05...0.50)
                Text("\(Int(settingsStore.settings.keypadButtonOpacity * 100))%")
                    .frame(width: 40)
            }
        }
    }

    // MARK: - 7. Calibrage
    private var calibrationSection: some View {
        Section(header: Text("Calibrage (Le calque)")) {
            HStack {
                Text("Calque LOCK")
                Spacer()
                PhotosPicker("Importer", selection: $calibLockPickerItem, matching: .images)
                    .onChange(of: calibLockPickerItem) { item in
                        loadPickerItem(item, for: .calibLock)
                    }
            }

            HStack {
                Text("Calque PASSCODE")
                Spacer()
                PhotosPicker("Importer", selection: $calibPasscodePickerItem, matching: .images)
                    .onChange(of: calibPasscodePickerItem) { item in
                        loadPickerItem(item, for: .calibPasscode)
                    }
            }

            Button(action: {
                onDismiss()
                onLaunchCalibration()
            }) {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                    Text("Lancer le calibrage interactif")
                }
                .foregroundColor(.yellow)
            }

            Button(action: {
                UIPasteboard.general.string = settingsStore.settings.layout.toJSONString()
                showCopiedAlert = true
            }) {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text("Copier la mise en page (JSON)")
                }
            }

            Button(role: .destructive, action: {
                showResetAlert = true
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Réinitialiser la mise en page")
                }
            }
        }
    }

    // MARK: - 8. Fin du tour
    private var endSection: some View {
        Section(header: Text("Fin du tour & Inactivité")) {
            Picker("Action de fin", selection: $settingsStore.settings.endAction) {
                ForEach(EndAction.allCases) { action in
                    Text(action.rawValue).tag(action)
                }
            }

            Stepper("Inactivité écran de code : \(Int(settingsStore.settings.passcodeInactivityTimeout)) s",
                    value: $settingsStore.settings.passcodeInactivityTimeout, in: 0...30, step: 5)
            Text("0 = désactivé. Ramène automatiquement à l'écran verrouillé.")
                .font(.footnote)
                .foregroundColor(.gray)
        }
    }

    // MARK: - 9. Mémo
    private var memoSection: some View {
        Section(header: Text("Mémo avant de jouer")) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Activer le mode « Ne pas déranger »", systemImage: "moon.fill")
                Label("Régler la luminosité au niveau voulu", systemImage: "sun.max.fill")
                Label("Régler l'option de fin adaptée", systemImage: "checkmark.circle.fill")
                Label("Si « Quitter l'app » : activer Réglages → Accessibilité → Mouvement → Réduire les animations", systemImage: "exclamationmark.triangle.fill")
                Label("Ne pas utiliser avec l'Accès guidé (bloque la mise en veille)", systemImage: "xmark.octagon.fill")
            }
            .font(.footnote)
            .foregroundColor(.secondary)
        }
    }

    // MARK: - Sheets
    private var notificationPreviewSheet: some View {
        NavigationStack {
            let sampleNotif = NotificationFactory.createNotification(
                code: "2580",
                appName: settingsStore.settings.notifAppName,
                title: settingsStore.settings.notifTitle,
                bodyTemplate: settingsStore.settings.notifBodyTemplate
            )

            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("Aperçu avec le code 2580 :")
                        .font(.headline)
                        .foregroundColor(.white)

                    FakeNotificationView(
                        layout: settingsStore.settings.layout,
                        notification: sampleNotif,
                        iconImage: imageStore.image(for: .notifIcon)
                    )

                    Text("La fin du numéro de commande dissimule « 0852 ».")
                        .font(.footnote)
                        .foregroundColor(.yellow)
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { showNotifPreview = false }
                }
            }
        }
    }

    private var volumeTesterSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Testeur de saisie au volume")
                    .font(.title2.bold())

                Text("Appuyez sur les boutons de volume de votre iPhone pour vous entraîner.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    Text("Série en cours :")
                        .font(.headline)
                    HStack(spacing: 8) {
                        ForEach(0..<volumeService.engine.currentSeriesPresses, id: \.self) { _ in
                            Circle().fill(Color.yellow).frame(width: 14, height: 14)
                        }
                    }
                    .frame(height: 20)

                    Text("Chiffres validés :")
                        .font(.headline)
                    HStack(spacing: 12) {
                        if volumeService.engine.pendingDigits.isEmpty {
                            Text("Aucun chiffre pour l'instant")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(volumeService.engine.pendingDigits.indices, id: \.self) { i in
                                Text("\(volumeService.engine.pendingDigits[i])")
                                    .font(.title.bold())
                                    .padding(8)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue))
                            }
                        }
                    }

                    Text("Code complet armé :")
                        .font(.headline)
                    if let armed = volumeService.armedCode {
                        Text(armed)
                            .font(.system(size: 36, weight: .heavy, design: .monospaced))
                            .foregroundColor(.green)
                    } else {
                        Text("En attente de 4 ou 6 chiffres...")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(white: 0.12)))
                .padding()

                Button("Réinitialiser l'entraînement") {
                    volumeService.reset()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Terminer") { showVolumeTester = false }
                }
            }
        }
    }

    private func loadPickerItem(_ item: PhotosPickerItem?, for slot: ImageStore.Slot) {
        guard let item = item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    imageStore.save(image: uiImage, for: slot)
                }
            }
        }
    }
}
