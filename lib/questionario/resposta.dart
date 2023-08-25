import 'package:flutter/material.dart';

class Resposta extends StatelessWidget {
  final void Function() selectHandler;
  final String textoDaResposta;

  const Resposta(this.selectHandler, this.textoDaResposta, {Key? key})
      : super(key: key);
  
  @override
  Widget build(BuildContext context){
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: selectHandler,
        style: ButtonStyle(
          textStyle: MaterialStateProperty.all(const TextStyle(color: Colors.white)),
          backgroundColor: MaterialStateProperty.all(Colors.green)
        ),
        child: Text(textoDaResposta),
      ),
    );
  }
}
