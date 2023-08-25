import 'package:flutter/material.dart';

class Quiz extends StatelessWidget {
  final List<Map<String, Object>> questoes;
  final int questaoIndex;
  final Function responderQuestao;

  const Quiz(
      {Key? key,
      required this.questoes,
      required this.responderQuestao,
      required this.questaoIndex})
      : super(key: key);

      @override
      Widget build(BuildContext context){
        return const Column(
          
        );
      }
}
