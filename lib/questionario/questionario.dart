import 'package:appbancodesangue/questionario/quiz.dart';
import 'package:appbancodesangue/questionario/resultado.dart';
import 'package:flutter/material.dart';

class QuestionarioScreen extends StatefulWidget {
  const QuestionarioScreen({super.key});

  @override
  State<QuestionarioScreen> createState() => _QuestionarioScreenState();
}

class _QuestionarioScreenState extends State<QuestionarioScreen> {
  final _questoes = const [
  {
    'textoDaQuestao': 'Q1. Quem pode doar sangue?',
    'respostas': [
      {'text': 'Pessoas com mais de 18 anos', 'score': -2},
      {'text': 'Apenas homens podem doar', 'score': -2},
      {'text': 'Pessoas saudáveis em geral', 'score': 10},
      {'text': 'Pessoas vegetarianas', 'score': -2},
    ],
  },
  {
    'textoDaQuestao': 'Q2. Qual é o intervalo mínimo entre as doações de sangue?',
    'respostas': [
      {'text': '2 semanas', 'score': -2},
      {'text': '2 meses', 'score': -2},
      {'text': '60 dias para Homens e 90 dias para Mulheres', 'score': 10},
      {'text': '6 meses', 'score': -2},
    ],
  },
  {
    'textoDaQuestao': 'Q3. Quais são os benefícios de doar sangue?',
    'respostas': [
      {
        'text': 'Estimula o apetite',
        'score': -2,
      },
      {
        'text': 'Reduz o risco de anemia',
        'score': 10,
      },
      {
        'text': 'Aumenta a sensibilidade à insulina',
        'score': -2,
      },
      {
        'text': 'Causa alergias',
        'score': -2,
      },
    ],
  },
  {
    'textoDaQuestao': 'Q4. Como é feito o processo de doação de sangue?',
    'respostas': [
      {
        'text': 'É realizada uma cirurgia',
        'score': -2,
      },
      {
        'text': 'É coletado sangue através de uma agulha',
        'score': 10,
      },
      {
        'text': 'É aplicada uma injeção',
        'score': -2,
      },
      {
        'text': 'É feita uma coleta de urina',
        'score': -2,
      },
    ],
  },
  {
    'textoDaQuestao': 'Q5. O que acontece após a doação de sangue?',
    'respostas': [
      {
        'text': 'O sangue é descartado',
        'score': -2,
      },
      {
        'text': 'O sangue é usado imediatamente em transfusões',
        'score': -2,
      },
      {
        'text': 'O sangue passa por testes e é armazenado para uso futuro',
        'score': 10,
      },
      {
        'text': 'O sangue é convertido em plasma',
        'score': -2,
      },
    ],
  },
];


  var _questaoIndex = 0;
  var _totalScore = 0;

  void _resetQuiz() {
    setState(() {
      _questaoIndex = 0;
      _totalScore = 0;
    });
  }

  void _responderQuestao(int score) {
    _totalScore += score;

    setState(() {
      _questaoIndex = _questaoIndex + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Questionario'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: _questaoIndex < _questoes.length
            ? Quiz(
                responderQuestao: _responderQuestao,
                questaoIndex: _questaoIndex,
                questoes: _questoes,
                )
            : Result(_totalScore, _resetQuiz),
      ),
    );
  }
}
