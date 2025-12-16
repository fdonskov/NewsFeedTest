//
//  NewsService.swift
//  NewsFeedTest
//
//  Created by Fedor Donskov on 16.12.2025.
//

import Foundation

// MARK: - NewsServiceProtocol
protocol NewsServiceProtocol: Sendable {
    func fetchNews(page: Int, limit: Int) async throws -> NewsModel
}

// MARK: - NewsService
final class NewsService: NewsServiceProtocol, @unchecked Sendable {

    private let decoder = JSONDecoder()

    func fetchNews(page: Int, limit: Int) async throws -> NewsModel {
        let urlString = "https://webapi.autodoc.ru/api/news/\(page)/\(limit)"
        let url = URL(string: urlString)!

        let (data, _) = try await URLSession.shared.data(from: url)
        return try decoder.decode(NewsModel.self, from: data)
    }
}
