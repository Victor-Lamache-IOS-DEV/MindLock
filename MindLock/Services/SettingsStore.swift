import Foundation
import Combine

/// Service responsable de la persistance et de la diffusion des paramètres de l'application
@MainActor
public final class SettingsStore: ObservableObject {
    public static let shared = SettingsStore()

    private let userDefaultsKey = "com.victorlamache.mindlock.settings"

    @Published public var settings: AppSettings {
        didSet {
            save()
        }
    }

    public init() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = AppSettings()
        }
    }

    public func save() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    public func resetLayout() {
        settings.layout = Layout()
    }

    public func updateLayout(from jsonString: String) -> Bool {
        guard let newLayout = Layout.from(jsonString: jsonString) else { return false }
        settings.layout = newLayout
        return true
    }
}
