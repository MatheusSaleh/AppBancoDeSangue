import 'package:appbancodesangue/questionario/questao.dart';
import 'package:appbancodesangue/questionario/resposta.dart';
import 'package:flutter/material.dart';

class Quiz extends StatelessWidget {
  final List<Map<String, Object>> questoes;
  final int questaoIndex;
  final Function responderQuestao;

  const Quiz({
    Key? key,
    required this.questoes,
    required this.responderQuestao,
    required this.questaoIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Questao(
          questoes[questaoIndex]['textoDaQuestao'].toString(),
        ),
        ...(questoes[questaoIndex]['respostas'] as List<Map<String, Object>>)
            .map((answer) {
          return Resposta(
            () => responderQuestao(answer['score'] as int),
            answer['text'].toString(),
          );
        }).toList(),
      ],
    );
  }
}
