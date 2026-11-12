import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../shared/widgets/common.dart';
import 'guide_content.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Guia de doação')),
      body: ResponsiveListView(
        children: [
          Text(
            'Recomendações para cada etapa da doação.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          for (final (index, stage) in guideStages.indexed) ...[
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text('${index + 1}'),
                ),
                title: Text(stage.title, style: theme.textTheme.titleMedium),
                subtitle: Text(
                  '${stage.subtitle} · ${stage.tips.length} recomendações',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/guia/${stage.slug}'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          Text(guideSource, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class GuideStageScreen extends StatelessWidget {
  const GuideStageScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final stage = guideStages.where((s) => s.slug == slug).firstOrNull;
    if (stage == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const MessageView(
          icon: Icons.search_off,
          title: 'Etapa não encontrada',
        ),
      );
    }
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(stage.title)),
      body: ResponsiveListView(
        children: [
          for (final tip in stage.tips) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(tip.icon, color: theme.colorScheme.primary),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tip.title, style: theme.textTheme.titleSmall),
                          const SizedBox(height: 4),
                          Text(tip.text, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(guideSource, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
