class NewsArticle {
  const NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    this.body = '',
    this.publishedAt,
  });

  final String id;
  final String title;
  final String summary;
  final String body;
  final DateTime? publishedAt;
}
