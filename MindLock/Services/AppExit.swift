import UIKit

/// Service permettant de suspendre l'application et revenir à l'écran d'accueil système d'iOS
@MainActor
public enum AppExit {
    public static func suspend() {
        let selector = NSSelectorFromString("suspend")
        if UIApplication.shared.responds(to: selector) {
            UIApplication.shared.perform(selector)
        } else {
            UIControl().sendAction(selector, to: UIApplication.shared, for: nil)
        }
    }
}
