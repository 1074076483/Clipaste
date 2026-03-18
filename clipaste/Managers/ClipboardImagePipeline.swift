import AppKit
import Foundation

final class ClipboardImagePipeline: @unchecked Sendable {
    nonisolated static let shared = ClipboardImagePipeline()

    nonisolated(unsafe) private let cache = NSCache<NSString, NSImage>()

    private init() {
        cache.countLimit = 256
    }

    nonisolated func invalidateAll() {
        cache.removeAllObjects()
    }

    nonisolated func thumbnail(for itemID: UUID, maxPixelSize: Int) async -> NSImage? {
        let cacheKey = "thumb-\(itemID.uuidString)-\(maxPixelSize)" as NSString
        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }

        let data: Data
        if let previewData = await StorageManager.shared.loadPreviewImageData(id: itemID) {
            data = previewData
        } else if let fallbackData = await StorageManager.shared.loadImageData(id: itemID) {
            data = fallbackData
        } else {
            return nil
        }

        let image = await Task.detached(priority: .userInitiated) {
            ImageProcessor.downsampleImage(from: data, maxPixelSize: maxPixelSize)
        }.value

        if let image {
            cache.setObject(image, forKey: cacheKey)
        }

        return image
    }

    nonisolated func thumbnail(forFileURL fileURL: URL, maxPixelSize: Int) async -> NSImage? {
        let cacheKey = "file-thumb-\(fileURL.standardizedFileURL.path)-\(maxPixelSize)" as NSString
        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }

        let imageTask = Task.detached(priority: .userInitiated) { () -> NSImage? in
            guard let data = ClipboardFileReference.loadImageData(from: fileURL) else { return nil }
            return ImageProcessor.downsampleImage(from: data, maxPixelSize: maxPixelSize)
        }
        let image = await imageTask.value

        if let image {
            cache.setObject(image, forKey: cacheKey)
        }

        return image
    }
}
