# Notes Techniques & Guide d'Utilisation : MindLock (Notes+)

## 1. Vue d'ensemble du projet
**MindLock** (affiché sous le nom **Notes+** sur l'écran d'accueil) est une application iOS native en Swift 5.9 / SwiftUI conçue pour reproduire fidèlement l'interface de l'écran verrouillé (LOCK) et de l'écran de code (PASSCODE) d'un iPhone 13 sous iOS 18.

Elle permet à un magicien/mentaliste de réaliser des effets de divination ou de coïncidence de code de déverrouillage, d'auto-saisie mystérieuse (Mind), ou de déverrouillage forcé.

---

## 2. Choix techniques & d'architecture

1. **Aucune dépendance externe (zéro CocoaPods, zéro SPM)** :
   - Uniquement les frameworks système Apple : `SwiftUI`, `UIKit`, `AVFoundation`, `MediaPlayer`, `PhotosUI`.
   - Permet une compilation immédiate, ultra-rapide et fiable sur les runners GitHub Actions macOS.

2. **Architecture déclarative et réactive** :
   - Machine à états centrale dans `RootView` (`lock` ↔ `passcode` → `unlocking` → `home`).
   - Moteur logique de décodage des appuis de volume découplé (`VolumeInputLogicEngine`) permettant des tests unitaires déterministes et instantanés.
   - Isolation des responsabilités :
     - `SettingsStore` : persistance des options et du modèle `Layout` dans `UserDefaults` via `Codable`.
     - `ImageStore` : écriture atomique asynchrone sur disque dans `Documents/` et cache mémoire `UIImage`.
     - `VolumeCodeService` : interception matérielle du volume et gestion de l'état secret.
     - `NotificationFactory` : encodage stéganographique du code secret dans un numéro de commande Amazon factice.
     - `Haptics` : retours tactiles calibrés avec préchauffage (`prepare()`).

3. **Indépendance stricte de la mise en page (`Layout.swift`)** :
   - Aucune valeur numérique de taille ou de position n'est codée en dur dans les vues.
   - Toutes les cotes (origine en haut à gauche, repère 390 × 844 pt) proviennent de la structure `Layout` et peuvent être exportées/importées au format JSON.

---

## 3. Limites connues & contraintes iOS

1. **Détection matérielle des boutons de volume (Sans API officielle)** :
   - iOS ne fournit aucune API publique pour détecter spécifiquement un appui physique sur les boutons de volume sans modifier le volume sonore.
   - *Solution mise en œuvre* : Une session audio `AVAudioSession` configurée en `.ambient` avec `.mixWithOthers`, combinée à une observation KVO sur `outputVolume` et une `MPVolumeView` masquée (alpha 0.01) qui supprime le HUD d'iOS. Après chaque appui détecté, le volume du slider interne est recentré à 0.5 avec un drapeau `isRecentering` pour masquer la variation et permettre des séries infinies d'appuis.
   - *Conséquence* : Lorsque l'appareil est en mode silencieux ou selon les versions d'iOS, la session audio doit être initialisée correctement dès le lancement et au retour au premier plan (`scenePhase == .active`).

2. **Mise en arrière-plan automatique (`AppExit.suspend`)** :
   - L'appel `UIControl().sendAction(NSSelectorFromString("suspend"), to: UIApplication.shared, for: nil)` utilise le sélecteur privé de suspension d'application.
   - *Recommandations* :
     - Activer dans iOS : **Réglages → Accessibilité → Mouvement → Réduire les animations** pour que la fermeture de l'app apparaisse comme un retour instantané au springboard natif.
     - **Incompatibilité avec l'Accès guidé** : L'accès guidé d'iOS bloque formellement la suspension des apps. Si l'accès guidé est activé, l'option « Rester sur la fausse page d'accueil » doit être préférée.

3. **Mode Ne pas déranger « Auto »** :
   - Dans cette v1, le statut « Auto » se comporte comme « Toujours affiché ». L'intégration directe d'`INFocusStatusCenter` nécessite la capacité `Communication Notifications` et un profil provisionné spécifique.

---

## 4. Guide de Calibrage au Pixel Près

Le mode de calibrage permet d'ajuster l'ensemble des éléments de l'app par-dessus une vraie capture d'écran d'iPhone 13 sous iOS 18 :

1. **Préparation des captures de référence** :
   - Prenez une capture d'écran réelle de votre iPhone 13 sur l'écran verrouillé (fond d'écran classique).
   - Prenez une capture d'écran réelle de l'écran de code ("Enter Passcode").
2. **Importation** :
   - Ouvrez les Réglages secrets (appuyez sur `1111` avec appui long d'1 seconde sur le dernier `1`).
   - Dans la section **Calibrage**, importez la capture dans **Calque LOCK** et **Calque PASSCODE**.
3. **Lancement du calibrage** :
   - Touchez **Lancer le calibrage interactif**.
   - Le calque de votre capture apparaît par-dessus l'écran avec une opacité de 50 %.
   - Un panneau flottant permet de sélectionner l'élément à régler (Heure, Date, Cadenas, Barre d'état, Touches du clavier, Points, Notification, etc.).
   - Utilisez les boutons `+` et `-` (par pas de 0.5 pt) pour ajuster les positions X et Y jusqu'à ce que les éléments se superposent sans dédoublement.
   - Utilisez le bouton **Inverser** pour basculer entre LOCK et PASSCODE.
   - Touchez **Terminer** pour enregistrer.
4. **Sauvegarde et partage** :
   - Retournez dans les réglages et touchez **Copier la mise en page (JSON)** pour sauvegarder vos cotes définitives.
