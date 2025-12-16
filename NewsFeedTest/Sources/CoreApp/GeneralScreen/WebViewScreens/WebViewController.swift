//
//  WebViewController.swift
//  NewsFeedTest
//
//  Created by Fedor Donskov on 16.12.2025.
//

import UIKit
import WebKit

// MARK: - WebViewController
final class WebViewController: UIViewController {

    // MARK: - Properties
    private let url: URL
    private let pageTitle: String?

    private lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.scrollView.bounces = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    // MARK: - Initialization
    init(url: URL, title: String? = nil) {
        self.url = url
        self.pageTitle = title
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupHierarchy()
        loadPage()
    }

    // MARK: - Methods
    private func setupHierarchy() {
        view.backgroundColor = .systemBackground
        title = pageTitle

        view.addSubview(webView)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func loadPage() {
        let request = URLRequest(url: url)
        activityIndicator.startAnimating()
        webView.load(request)
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Ошибка загрузки",
            message: error.localizedDescription,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Закрыть", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })

        present(alert, animated: true)
    }
}

// MARK: - Actions
extension WebViewController {
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

// MARK: - WKNavigationDelegate
extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activityIndicator.startAnimating()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        showError(error)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        showError(error)
    }
}
