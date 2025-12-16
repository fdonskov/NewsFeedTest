//
//  NewsModel.swift
//  NewsFeedTest
//
//  Created by Fedor Donskov on 16.12.2025.
//

import Foundation

// MARK: - NewsModel
struct NewsModel: Codable, Sendable {
    let news: [NewsModelDataObject]
    let totalCount: Int
}

// MARK: - NewsModelDataObject
struct NewsModelDataObject: Codable, Sendable, Hashable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let publishedDate: String
    let url: String?
    let fullUrl: String?
    let titleImageUrl: String?
    let categoryType: String?
}
