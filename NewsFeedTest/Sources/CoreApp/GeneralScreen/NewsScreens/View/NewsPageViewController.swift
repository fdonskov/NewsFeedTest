//
//  NewsPageViewController.swift
//  NewsFeedTest
//
//  Created by Fedor Donskov on 16.12.2025.
//

import UIKit
import Combine

// MARK: - NewsPageViewController
@MainActor
final class NewsPageViewController: UIViewController {

    enum Section: Int, Sendable {
        case news
    }

    // MARK: - Properties
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Int>!
    private var newsItems: [Int: NewsModelDataObject] = [:]
    private let viewModel: NewsViewModel
    private var cancellables = Set<AnyCancellable>()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private let refreshControl = UIRefreshControl()

    // MARK: - Initialization
    init(viewModel: NewsViewModel? = nil) {
        self.viewModel = viewModel ?? NewsViewModel()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupHierarchy()
        setupCollectionView()
        configureDataSource()
        bindViewModel()

        viewModel.loadNews()
    }

    // MARK: - Methods
    private func setupHierarchy() {
        title = "Новости"
        view.backgroundColor = .clear

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        let navigationBar = navigationController?.navigationBar
        navigationBar?.standardAppearance = appearance
        navigationBar?.scrollEdgeAppearance = appearance
        navigationBar?.compactAppearance = appearance

        navigationBar?.prefersLargeTitles = true
    }

    private func setupCollectionView() {
        let layout = createLayout()
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = .black
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.delegate = self

        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl

        view.addSubview(collectionView)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in

            let groupWidth: NSCollectionLayoutDimension = .fractionalWidth(1.0)

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(460)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: groupWidth,
                heightDimension: .estimated(460)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0)

            return section
        }

        return layout
    }

    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<NewsCell, Int> { [weak self] cell, indexPath, newsId in
            guard let self, let news = newsItems[newsId] else { return }
            cell.configure(with: news)
        }

        dataSource = UICollectionViewDiffableDataSource<Section, Int>(collectionView: collectionView) { collectionView, indexPath, newsId in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: newsId)
        }
    }

    private func bindViewModel() {
        viewModel.stateSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                self.handleStateChange(state)
            }
            .store(in: &cancellables)
    }

    private func handleStateChange(_ state: NewsViewModelState) {
        refreshControl.endRefreshing()

        switch state {
        case .idle:
            activityIndicator.stopAnimating()

        case .loading:
            if dataSource.snapshot().itemIdentifiers.isEmpty {
                activityIndicator.startAnimating()
            }

        case .loaded(let news), .loadingMore(let news):
            activityIndicator.stopAnimating()
            updateSnapshot(with: news)

        case .error(let message):
            activityIndicator.stopAnimating()
            showError(message)
        }
    }

    private func updateSnapshot(with news: [NewsModelDataObject]) {
        newsItems = Dictionary(uniqueKeysWithValues: news.map { ($0.id, $0) })

        var snapshot = NSDiffableDataSourceSnapshot<Section, Int>()
        snapshot.appendSections([.news])
        snapshot.appendItems(news.map { $0.id }, toSection: .news)

        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Повторить", style: .default) { [weak self] _ in
            guard let self else { return }
            self.viewModel.retry()
        })

        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))

        present(alert, animated: true)
    }
}

// MARK: - Actions
extension NewsPageViewController {
    @objc private func handleRefresh() {
        viewModel.loadNews()
    }
}

// MARK: - UICollectionViewDelegate
extension NewsPageViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        guard let newsId = dataSource.itemIdentifier(for: indexPath),
              let news = newsItems[newsId],
              let urlString = news.fullUrl,
              let url = URL(string: urlString) else {
            return
        }
        
        print("DBG fullUrl - \(urlString)")

        let webViewController = WebViewController(url: url, title: news.title)
        present(webViewController, animated: true)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let scrollViewHeight = scrollView.frame.size.height

        if offsetY > contentHeight - scrollViewHeight - 100 {
            viewModel.loadMoreNews()
        }
    }
}
