import 'package:material_ui/material_ui.dart';

/// Educational content written for the 2023 research project, reviewed in
/// 2026: typos fixed, duplicated sentences removed and the eligibility
/// criteria aligned with the Ministério da Saúde page cited in [guideSource].
class GuideTip {
  const GuideTip(this.icon, this.title, this.text);

  final IconData icon;
  final String title;
  final String text;
}

class GuideStage {
  const GuideStage({
    required this.slug,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tips,
  });

  final String slug;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<GuideTip> tips;
}

const guideSource =
    'Critérios de idade, peso, intervalo, sono, alimentação, documento e '
    'tabagismo: Ministério da Saúde — gov.br/saude, "Doação de Sangue" e FAQ. '
    'As demais dicas são orientações gerais do projeto original.';

const guideStages = <GuideStage>[
  GuideStage(
    slug: 'antes',
    title: 'Antes da doação',
    subtitle: 'Requisitos e preparo',
    icon: Icons.event_available_outlined,
    tips: [
      GuideTip(
        Icons.checklist_rtl_outlined,
        'Verifique os requisitos básicos',
        'Ter entre 16 e 69 anos (menores de 18 anos precisam de autorização '
            'formal do responsável legal; pessoas entre 60 e 69 anos só podem '
            'doar se já tiverem doado antes dos 60), pesar no mínimo 50 kg e '
            'estar em boas condições de saúde.',
      ),
      GuideTip(
        Icons.restaurant_outlined,
        'Esteja alimentado',
        'Não doe em jejum. Faça uma refeição leve e evite alimentos '
            'gordurosos nas 3 horas que antecedem a doação. Alimentos ricos '
            'em ferro, como carnes magras, feijão e folhas verde-escuras, '
            'junto de fontes de vitamina C, ajudam a manter bons níveis de '
            'ferro.',
      ),
      GuideTip(
        Icons.water_drop_outlined,
        'Hidrate-se',
        'Beba bastante líquido nas 24 horas anteriores à doação e evite '
            'bebidas alcoólicas nesse período.',
      ),
      GuideTip(
        Icons.bedtime_outlined,
        'Descanse bem',
        'Tenha dormido pelo menos 6 horas nas últimas 24 horas.',
      ),
      GuideTip(
        Icons.directions_run_outlined,
        'Evite esforço intenso',
        'Evite exercícios vigorosos antes da doação. Isso ajuda a prevenir '
            'tonturas ou fraqueza durante o processo.',
      ),
      GuideTip(
        Icons.badge_outlined,
        'Leve um documento',
        'Apresente um documento oficial de identidade com foto no '
            'hemocentro.',
      ),
    ],
  ),
  GuideStage(
    slug: 'durante',
    title: 'Durante a doação',
    subtitle: 'O que esperar da coleta',
    icon: Icons.volunteer_activism_outlined,
    tips: [
      GuideTip(
        Icons.self_improvement_outlined,
        'Mantenha a calma',
        'A ansiedade e o estresse podem aumentar a sensação de desconforto '
            'durante a coleta. Tente relaxar antes e durante o procedimento.',
      ),
      GuideTip(
        Icons.record_voice_over_outlined,
        'Siga as instruções da equipe',
        'Um profissional de saúde realizará a coleta. Ele pode pedir que '
            'você mantenha o braço estendido, evite movimentos bruscos ou '
            'mantenha pressão em um local específico após a coleta.',
      ),
      GuideTip(
        Icons.forum_outlined,
        'Comunique-se',
        'Se tiver dúvidas ou sentir qualquer desconforto, avise o '
            'profissional responsável pela coleta.',
      ),
    ],
  ),
  GuideStage(
    slug: 'depois',
    title: 'Depois da doação',
    subtitle: 'Recuperação e próximos passos',
    icon: Icons.favorite_outline,
    tips: [
      GuideTip(
        Icons.airline_seat_recline_normal_outlined,
        'Descanse',
        'Descanse alguns minutos após a doação. Isso permite que o corpo se '
            'recupere e evita tonturas ou fraqueza.',
      ),
      GuideTip(
        Icons.bakery_dining_outlined,
        'Faça o lanche oferecido',
        'A maioria dos hemocentros oferece um lanche após a doação. '
            'Consuma-o para repor a energia.',
      ),
      GuideTip(
        Icons.local_drink_outlined,
        'Continue se hidratando',
        'Beba bastante líquido nas horas seguintes para repor o volume '
            'doado.',
      ),
      GuideTip(
        Icons.fitness_center_outlined,
        'Evite esforço físico',
        'Evite exercícios vigorosos e carregar peso com o braço da punção '
            'nas primeiras 24 horas.',
      ),
      GuideTip(
        Icons.smoke_free_outlined,
        'Evite cigarro e álcool',
        'Não fume por pelo menos 2 horas antes e depois da doação e evite '
            'bebidas alcoólicas nas horas seguintes; eles prejudicam a '
            'recuperação.',
      ),
      GuideTip(
        Icons.healing_outlined,
        'Cuide do local da punção',
        'Mantenha o curativo por algumas horas e evite movimentos bruscos '
            'com o braço para prevenir sangramento.',
      ),
      GuideTip(
        Icons.calendar_month_outlined,
        'Planeje a próxima doação',
        'Respeite o intervalo entre doações: 60 dias para homens (até 4 por '
            'ano) e 90 dias para mulheres (até 3 por ano). O app calcula a '
            'próxima data a partir do seu histórico.',
      ),
    ],
  ),
];
