import UIKit
import SwiftUI

/// Service de gestion et persistance des images importées dans Documents/
@MainActor
public final class ImageStore: ObservableObject {
    public static let shared = ImageStore()

    public enum Slot: String, CaseIterable {
        case wallpaper = "wallpaper"
        case notifIcon = "notifIcon"
        case home = "home"
        case calibLock = "calibLock"
        case calibPasscode = "calibPasscode"

        var fileExtension: String {
            switch self {
            case .notifIcon: return "png"
            default: return "jpg"
            }
        }

        var fileName: String {
            "\(rawValue).\(fileExtension)"
        }
    }

    @Published public private(set) var images: [Slot: UIImage] = [:]

    private let fileManager = FileManager.default
    private let documentsURL: URL

    public init() {
        documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        loadAllImages()
    }

    private func fileURL(for slot: Slot) -> URL {
        documentsURL.appendingPathComponent(slot.fileName)
    }

    public func image(for slot: Slot) -> UIImage? {
        images[slot]
    }

    public func loadAllImages() {
        for slot in Slot.allCases {
            let url = fileURL(for: slot)
            if fileManager.fileExists(atPath: url.path),
               let data = try? Data(contentsOf: url),
               let uiImage = UIImage(data: data) {
                images[slot] = uiImage
            }
        }
    }

    public func save(image: UIImage, for slot: Slot) {
        let resized = downscaleIfNeeded(image: image, maxDimension: 1170)
        images[slot] = resized

        let targetURL = fileURL(for: slot)
        let isPNG = (slot == .notifIcon)

        DispatchQueue.global(qos: .background).async {
            let data: Data?
            if isPNG {
                data = resized.pngData()
            } else {
                data = resized.jpegData(compressionQuality: 0.9)
            }
            if let data = data {
                try? data.write(to: targetURL, options: .atomic)
            }
        }
    }

    public func remove(slot: Slot) {
        images[slot] = nil
        let targetURL = fileURL(for: slot)
        DispatchQueue.global(qos: .background).async {
            try? FileManager.default.removeItem(at: targetURL)
        }
    }

    private func downscaleIfNeeded(image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }

        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
