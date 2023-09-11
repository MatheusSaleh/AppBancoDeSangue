import 'package:flutter/material.dart';

class Questao extends StatelessWidget {
  final String textoDaQuestao;

  const Questao(this.textoDaQuestao, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(10),

      child: Text(
        textoDaQuestao,       
        style: const TextStyle(fontSize: 28),
        textAlign: TextAlign.center,
      ),
    );
  }
}
