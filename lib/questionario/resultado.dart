import 'package:flutter/material.dart';

class Result extends StatelessWidget {
  final int resultadoScore;
  final Function resetHandler;

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

  
}
