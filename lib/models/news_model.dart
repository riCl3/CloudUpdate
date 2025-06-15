// lib/models/news_model.dart
class NewsModel {
  final String title;
  final String description;
  final String urlToImage;
  final String url;
  final String? author;
  final String? source;
  final String? publishedAt;
  final String? content;
  bool isBookmarked;

  NewsModel({
    required this.title,
    required this.description,
    required this.urlToImage,
    required this.url,
    this.author,
    this.source,
    this.publishedAt,
    this.content,
    this.isBookmarked = false,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? 'No Description',
      urlToImage: json['urlToImage'] ?? '',
      url: json['url'] ?? '',
      author: json['author'],
      source: json['source']?['name'],
      publishedAt: json['publishedAt'],
      content: json['content'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'urlToImage': urlToImage,
      'url': url,
      'author': author,
      'source': source,
      'publishedAt': publishedAt,
      'content': content,
      'isBookmarked': isBookmarked,
    };
  }

  // Create a copy with updated bookmark status
  NewsModel copyWith({
    String? title,
    String? description,
    String? urlToImage,
    String? url,
    String? author,
    String? source,
    String? publishedAt,
    String? content,
    bool? isBookmarked,
  }) {
    return NewsModel(
      title: title ?? this.title,
      description: description ?? this.description,
      urlToImage: urlToImage ?? this.urlToImage,
      url: url ?? this.url,
      author: author ?? this.author,
      source: source ?? this.source,
      publishedAt: publishedAt ?? this.publishedAt,
      content: content ?? this.content,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  // Get formatted date
  String get formattedDate {
    if (publishedAt == null) return 'Unknown date';
    try {
      final date = DateTime.parse(publishedAt!);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }

  // Get unique identifier for bookmarking
  String get id => url.hashCode.toString();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is NewsModel && runtimeType == other.runtimeType && url == other.url;

  @override
  int get hashCode => url.hashCode;
}