import 'package:flutter/material.dart';

class Result extends StatelessWidget {
  final int resultadoScore;
  final void Function() resetHandler;

  const Result(this.resultadoScore, this.resetHandler, {Key? key})
      : super(key: key);

  String get resultPhrase {
    String resultText;
    if (resultadoScore >= 41) {
      resultText = 'Você é um verdadeiro heroi da doação de sangue!';
    } else if (resultadoScore >= 31) {
      resultText = 'Parabéns, você é um doador exemplar';
    } else if (resultadoScore >= 21) {
      resultText = 'Seu esforço é apreciado, mas ainda há mais a aprender sobre a doação de sangue.';
    } else if (resultadoScore >= 1) {
      resultText = 'É louvável que você tenha interesse, mas é importante estudar mais sobre a doação de sangue.';
    } else {
      resultText = 'Parece que você precisa aprender mais sobre a importância da doação de sangue.';
    }
    return resultText;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            resultPhrase,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Text(
            'Score ' '$resultadoScore',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          TextButton(
              onPressed: resetHandler,
              child: Container(
                color: Color.fromARGB(255, 255, 0, 0),
                padding: const EdgeInsets.all(14),
                child: const Text(
                  'Reiniciar Quiz',
                  style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                ),
              ))
        ],
      ),
    );
  }
}
