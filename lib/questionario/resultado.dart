import 'package:flutter/material.dart';

class Result extends StatelessWidget {
  final int resultadoScore;
  final void Function() resetHandler;

  const Result(this.resultadoScore, this.resetHandler, {Key? key})
      : super(key: key);

  String get resultPhrase {
    String resultText;
    if (resultadoScore >= 41) {
      resultText = 'Você é incrível!';
    } else if (resultadoScore >= 31) {
      resultText = 'Muito Bom';
    } else if (resultadoScore >= 21) {
      resultText = 'Você precisa estudar mais';
    } else if (resultadoScore >= 1) {
      resultText = 'Você precisa estudar muito mais';
    } else {
      resultText = 'Você foi muito mal';
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
            'Score' '$resultadoScore',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          TextButton(
            onPressed: resetHandler, 
            child: Container(
              color: Colors.green,
              padding: const EdgeInsets.all(14),
              child: const Text(
                'Reiniciar Quiz',
                style: TextStyle(color: Colors.blue),
              ),
            ))
        ],
      ),
    );
  }
}
