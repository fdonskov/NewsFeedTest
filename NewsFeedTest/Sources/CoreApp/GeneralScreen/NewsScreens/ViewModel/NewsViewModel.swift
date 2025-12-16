//
//  NewsViewModel.swift
//  NewsFeedTest
//
//  Created by Fedor Donskov on 16.12.2025.
//

import UIKit
import Combine

// MARK: - NewsViewModelState
enum NewsViewModelState: Equatable, Sendable {
    case idle
    case loading
    case loaded([NewsModelDataObject])
    case loadingMore([NewsModelDataObject])
    case error(String)

    static func == (lhs: NewsViewModelState, rhs: NewsViewModelState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.loading, .loading):
            return true
        case let (.loaded(lhsNews), .loaded(rhsNews)):
            return lhsNews.map { $0.id } == rhsNews.map { $0.id }
        case let (.loadingMore(lhsNews), .loadingMore(rhsNews)):
            return lhsNews.map { $0.id } == rhsNews.map { $0.id }
        case let (.error(lhsError), .error(rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }

    var newsItems: [NewsModelDataObject] {
        switch self {
        case .loaded(let items), .loadingMore(let items):
            return items
        default:
            return []
        }
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var isLoadingMore: Bool {
        if case .loadingMore = self { return true }
        return false
    }
}

// MARK: - NewsViewModel
final class NewsViewModel {

    // MARK: - Properties
    @MainActor
    private(set) var state: NewsViewModelState = .idle {
        didSet {
            stateSubject.send(state)
        }
    }

    let stateSubject = CurrentValueSubject<NewsViewModelState, Never>(.idle)

    private let newsService: NewsServiceProtocol
    private var currentPage = 1
    private let pageSize = 15
    private var totalCount: Int?
    private var canLoadMore: Bool {
        guard let totalCount = totalCount else { return true }
        return state.newsItems.count < totalCount
    }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(newsService: NewsServiceProtocol = NewsService()) {
        self.newsService = newsService
    }

    // MARK: - Methods
    @MainActor
    func loadNews() {
        guard !state.isLoading else { return }

        state = .loading
        currentPage = 1

        Task {
            do {
                let newsModel = try await newsService.fetchNews(page: currentPage, limit: pageSize)
                totalCount = newsModel.totalCount
                state = .loaded(newsModel.news)
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    @MainActor
    func loadMoreNews() {
        guard !state.isLoadingMore, !state.isLoading, canLoadMore else { return }

        let currentNews = state.newsItems
        state = .loadingMore(currentNews)
        currentPage += 1

        Task {
            do {
                let newsModel = try await newsService.fetchNews(page: currentPage, limit: pageSize)
                totalCount = newsModel.totalCount
                let updatedNews = currentNews + newsModel.news
                state = .loaded(updatedNews)
            } catch {
                currentPage -= 1
                state = .error(error.localizedDescription)
            }
        }
    }

    @MainActor
    func retry() {
        loadNews()
    }
}
