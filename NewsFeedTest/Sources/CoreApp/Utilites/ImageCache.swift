//
//  ImageCache.swift
//  NewsFeedTest
//
//  Created by Fedor Donskov on 16.12.2025.
//

import UIKit

actor ImageCache {
    static let shared = ImageCache()

    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private lazy var cacheDirectory: URL? = {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("ImageCache")
    }()

    private var loadingTasks: [String: Task<UIImage?, Error>] = [:]

    private init() {
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 1024 * 1024 * 100 // 100 MB
        Task {
            createCacheDirectoryIfNeeded()
        }
    }

    func loadImage(from urlString: String?) async -> UIImage? {
        guard let urlString = urlString, !urlString.isEmpty else { return nil }

        if let cachedImage = memoryCache.object(forKey: urlString as NSString) {
            return cachedImage
        }

        if let diskImage = loadImageFromDisk(urlString: urlString) {
            memoryCache.setObject(diskImage, forKey: urlString as NSString)
            return diskImage
        }

        if let existingTask = loadingTasks[urlString] {
            return try? await existingTask.value
        }

        let task = Task<UIImage?, Error> {
            try await downloadImage(from: urlString)
        }

        loadingTasks[urlString] = task

        defer {
            loadingTasks.removeValue(forKey: urlString)
        }

        guard let image = try? await task.value else {
            return nil
        }

        memoryCache.setObject(image, forKey: urlString as NSString)
        saveImageToDisk(image: image, urlString: urlString)

        return image
    }

    private func downloadImage(from urlString: String) async throws -> UIImage? {
        guard let url = URL(string: urlString) else {
            return nil
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        return UIImage(data: data)
    }

    private nonisolated func createCacheDirectoryIfNeeded() {
        guard let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("ImageCache") else { return }

        if !FileManager.default.fileExists(atPath: cacheDirectory.path) {
            try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }

    private func loadImageFromDisk(urlString: String) -> UIImage? {
        guard let cacheDirectory = cacheDirectory else { return nil }

        let fileName = urlString.toBase64()
        let fileURL = cacheDirectory.appendingPathComponent(fileName)

        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }

        return image
    }

    private func saveImageToDisk(image: UIImage, urlString: String) {
        guard let cacheDirectory = cacheDirectory,
              let data = image.jpegData(compressionQuality: 0.8) else {
            return
        }

        let fileName = urlString.toBase64()
        let fileURL = cacheDirectory.appendingPathComponent(fileName)

        try? data.write(to: fileURL)
    }

    func clearCache() {
        memoryCache.removeAllObjects()

        guard let cacheDirectory = cacheDirectory else { return }
        try? fileManager.removeItem(at: cacheDirectory)
        Task {
            createCacheDirectoryIfNeeded()
        }
    }
}
