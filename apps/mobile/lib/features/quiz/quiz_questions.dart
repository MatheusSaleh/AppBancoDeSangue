import '../../domain/models/quiz.dart';

/// Questions from the 2023 quiz. Reviewed in 2026:
/// * Q2: the distractor "2 meses" was ambiguous (≈ 60 days) and was replaced.
/// * Q3: the original "correct" answer ("Reduz o risco de anemia") is
///   medically inaccurate — donating removes iron. The question was
///   rewritten to keep the theme (why donating matters) with a correct answer.
const quizQuestions = <QuizQuestion>[
  QuizQuestion(
    text: 'Quem pode doar sangue?',
    options: [
      'Apenas pessoas com mais de 18 anos',
      'Apenas homens',
      'Pessoas saudáveis em geral, entre 16 e 69 anos e com pelo menos 50 kg',
      'Apenas pessoas vegetarianas',
    ],
    correctIndex: 2,
    explanation:
        'Pessoas saudáveis entre 16 e 69 anos e com no mínimo 50 kg podem '
        'doar. Menores de 18 anos precisam de autorização do responsável.',
  ),
  QuizQuestion(
    text: 'Qual é o intervalo mínimo entre as doações de sangue?',
    options: [
      '2 semanas',
      '15 dias para todos',
      '60 dias para homens e 90 dias para mulheres',
      '6 meses',
    ],
    correctIndex: 2,
    explanation:
        'Homens podem doar a cada 60 dias (até 4 vezes ao ano) e mulheres a '
        'cada 90 dias (até 3 vezes ao ano).',
  ),
  QuizQuestion(
    text: 'Por que a doação de sangue é tão importante?',
    options: [
      'Porque estimula o apetite do doador',
      'Porque o sangue não pode ser fabricado e é indispensável em '
          'cirurgias, tratamentos e emergências',
      'Porque reduz o risco de anemia do doador',
      'Porque é obrigatória por lei',
    ],
    correctIndex: 1,
    explanation:
        'Não existe substituto artificial para o sangue. A doação é '
        'voluntária e cada bolsa é separada em componentes (hemácias, '
        'plaquetas, plasma), podendo ajudar várias pessoas. Doar não reduz o '
        'risco de anemia: pelo contrário, o organismo precisa repor o ferro.',
  ),
  QuizQuestion(
    text: 'Como é feito o processo de doação de sangue?',
    options: [
      'É realizada uma cirurgia',
      'O sangue é coletado por uma agulha, com material estéril e descartável',
      'É aplicada uma injeção',
      'É feita uma coleta de urina',
    ],
    correctIndex: 1,
    explanation:
        'Após cadastro e triagem clínica, o sangue é coletado por uma veia do '
        'braço com material estéril e descartável. A coleta leva poucos '
        'minutos.',
  ),
  QuizQuestion(
    text: 'O que acontece com o sangue após a doação?',
    options: [
      'É descartado',
      'É usado imediatamente em transfusões, sem testes',
      'Passa por testes, é separado em componentes e armazenado',
      'É convertido apenas em plasma',
    ],
    correctIndex: 2,
    explanation:
        'O sangue doado passa por exames laboratoriais e é fracionado em '
        'componentes, que são armazenados até serem usados por pacientes.',
  ),
];
