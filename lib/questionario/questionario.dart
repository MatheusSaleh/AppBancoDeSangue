import 'package:appbancodesangue/questionario/quiz.dart';
import 'package:flutter/material.dart';

class QuestionarioScreen extends StatefulWidget {
  const QuestionarioScreen({super.key});

  @override
  State<QuestionarioScreen> createState() => _QuestionarioScreenState();
}

class _QuestionarioScreenState extends State<QuestionarioScreen> {
  final _questoes = const [
    {
      'textoDaQuestao': 'Q1. Quem Criou o Flutter? ',
      'respostas': [
        {'text': 'Facebook', 'score': -2},
        {'text': 'Adobe', 'score': -3},
        {'text': 'Google', 'score': 10},
        {'text': 'Microsoft', 'score': -2},
      ],
    },
    {
      'textoDaQuestao': 'Q2. O que é o Flutter?',
      'respostas': [
        {'text': 'Um Kit de desenvolvimento para Android', 'score': -2},
        {'text': 'Um Kit de desenvolvimento para iOS', 'score': -2},
        {'text': 'Um Kit de desenvolvimento Web', 'score': -2},
        {
          'text': 'Um Kit de desenvolvimento iOS, Android, Web e Desktop',
          'score': 10
        }
      ],
    },
    {
      'textoDaQuestao':
          'Q3. Qual é a linguagem de programação usada pelo Flutter?',
      'respostas': [
        {'text': 'Ruby', 'score': -2},
        {'text': 'Dart', 'score': 10},
        {'text': 'C++', 'score': -2},
        {'text': 'Kotlin', 'score': -2},
      ],
    },
    {
      'textoDaQuestao': 'Q4. Quem criou a linguagem de programação Dart?',
      'respostas': [
        {'text': 'Lars Bak e Kasper Lund', 'score': 10},
        {'text': 'Brendam Eich', 'score': -2},
        {'text': 'Bjarne Stroustrup', 'score': -2},
        {'text': 'Jeremy Ashkenas', 'score': -2},
      ],
    },
    {
      'textoDaQuestao':
          'Q5. O Flutter está disponível para Web e Desktop em versão estável ?',
      'respostas': [
        {'text': 'Sim', 'score': -2},
        {'text': 'No', 'score': 10},
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
                questoes: _questoes)
            : Resultado(_totalScore, _resetQuiz),
      ),
    );
  }
}
