import 'package:flutter/material.dart';

class Resposta extends StatelessWidget {
  final void Function() selectHandler;
  final String textoDaResposta;

  const Resposta(this.selectHandler, this.textoDaResposta, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: selectHandler,
        style: ButtonStyle(
          textStyle: MaterialStateProperty.all(const TextStyle(color: Colors.white)),
          backgroundColor:
              MaterialStateProperty.all(const Color.fromARGB(255, 204, 68, 33)),
        ),
    
        child: Text(
          textoDaResposta,
          style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
        ),
      ),
    );
  }
}
