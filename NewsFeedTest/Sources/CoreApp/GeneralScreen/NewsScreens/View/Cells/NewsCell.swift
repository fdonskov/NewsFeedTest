//
//  NewsCell.swift
//  NewsFeedTest
//
//  Created by Fedor Donskov on 16.12.2025.
//

import UIKit

// MARK: - NewsCell
final class NewsCell: UICollectionViewCell {

    static let identifier = "NewsCell"

    // MARK: - UI Elements
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .white
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .white
        label.numberOfLines = 4
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var newsImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        imageView.backgroundColor = .clear
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var categoryContainerView: UIView = {
        let view = UIView()
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.lightGray.cgColor
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var categoryLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var copyLinkButton: UIButton = {
        let button = UIButton()
        let image = UIImage(systemName: "ellipsis")
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var imageLoadTask: Task<Void, Never>?

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHierarchy()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageLoadTask?.cancel()
        imageLoadTask = nil
        newsImageView.image = nil
        titleLabel.text = nil
        descriptionLabel.text = nil
        dateLabel.text = nil
        categoryLabel.text = nil
    }

    // MARK: - Methods
    private func setupHierarchy() {
        contentView.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(dateLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(newsImageView)
        containerView.addSubview(categoryContainerView)
        categoryContainerView.addSubview(categoryLabel)
        containerView.addSubview(copyLinkButton)
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: copyLinkButton.leadingAnchor, constant: -40),
            
            copyLinkButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            copyLinkButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            copyLinkButton.widthAnchor.constraint(equalToConstant: 40),
            copyLinkButton.heightAnchor.constraint(equalToConstant: 20),
            
            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            dateLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            
            descriptionLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 15),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),

            newsImageView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 10),
            newsImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            newsImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            newsImageView.heightAnchor.constraint(equalToConstant: 260),
            
            categoryContainerView.topAnchor.constraint(equalTo: newsImageView.bottomAnchor, constant: 16),
            categoryContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),

            categoryLabel.topAnchor.constraint(equalTo: categoryContainerView.topAnchor, constant: 5),
            categoryLabel.bottomAnchor.constraint(equalTo: categoryContainerView.bottomAnchor, constant: -5),
            categoryLabel.leadingAnchor.constraint(equalTo: categoryContainerView.leadingAnchor, constant: 10),
            categoryLabel.trailingAnchor.constraint(equalTo: categoryContainerView.trailingAnchor, constant: -10)
        ])
    }

    // MARK: - Configure
    func configure(with news: NewsModelDataObject) {
        titleLabel.text = news.title
        descriptionLabel.text = news.description
        dateLabel.text = formatDate(news.publishedDate)
        categoryLabel.text = news.categoryType

        imageLoadTask?.cancel()
        imageLoadTask = Task { @MainActor in
            if let image = await ImageCache.shared.loadImage(from: news.titleImageUrl) {
                newsImageView.image = image
            } else {
                newsImageView.image = UIImage(systemName: "photo")
            }
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInYesterday(date) {
            return "вчера"
        }

        let dateYear = calendar.component(.year, from: date)
        let currentYear = calendar.component(.year, from: now)

        let output = DateFormatter()
        output.locale = Locale(identifier: "ru_RU")

        if dateYear == currentYear {
            output.dateFormat = "d MMMM"
            return output.string(from: date)
        } else {
            output.dateFormat = "d MMMM yyyy 'г.'"
            return output.string(from: date)
        }
    }
}
