import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../data/repositories/repositories.dart';
import '../../domain/models/news_article.dart';
import '../../shared/widgets/common.dart';
import '../donations/donor_view_model.dart' show LoadState;

class NewsViewModel extends ChangeNotifier {
  NewsViewModel(this._repository) {
    load();
  }

  final NewsRepository _repository;

  LoadState _state = LoadState.loading;
  List<NewsArticle> _articles = const [];
  String? _error;

  LoadState get state => _state;
  List<NewsArticle> get articles => _articles;
  String? get error => _error;
  bool get isDemoContent => _repository.isDemoContent;

  Future<void> load() async {
    _state = LoadState.loading;
    _error = null;
    notifyListeners();
    try {
      _articles = await _repository.fetchAll();
      _state = LoadState.ready;
    } on AppException catch (e) {
      _error = e.message;
      _state = LoadState.error;
    }
    notifyListeners();
  }
}

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NewsViewModel(context.read<NewsRepository>()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Notícias')),
        body: Consumer<NewsViewModel>(
          builder: (context, vm, _) => switch (vm.state) {
            LoadState.idle || LoadState.loading => const LoadingView(),
            LoadState.error => MessageView(
              icon: Icons.cloud_off,
              title: 'Erro ao carregar notícias',
              message: vm.error,
              actionLabel: 'Tentar novamente',
              onAction: vm.load,
            ),
            LoadState.ready when vm.articles.isEmpty => const MessageView(
              icon: Icons.article_outlined,
              title: 'Nenhuma notícia publicada',
            ),
            LoadState.ready => RefreshIndicator(
              onRefresh: vm.load,
              child: ResponsiveListView(
                children: [
                  if (vm.isDemoContent) ...[
                    const DemoNotice(
                      'Conteúdo de exemplo: estes artigos são fictícios e '
                      'servem apenas para demonstrar a tela.',
                    ),
                    const SizedBox(height: 16),
                  ],
                  for (final article in vm.articles) ...[
                    _ArticleCard(article: article),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          },
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article});

  final NewsArticle article;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.publishedAt case final date?)
              Text(formatDate(date), style: theme.textTheme.labelMedium),
            Text(article.title, style: theme.textTheme.titleLarge),
            if (article.summary.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(article.summary, style: theme.textTheme.bodyLarge),
            ],
            if (article.body.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(article.body, style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
