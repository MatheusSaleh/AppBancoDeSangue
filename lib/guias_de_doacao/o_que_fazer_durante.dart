import 'package:flutter/material.dart';

class DuranteScreen extends StatelessWidget{
   DuranteScreen({super.key});

  final List<Map<String, dynamic>> procedimentos = [
    {
      'icon': Icons.check,
      'text': 'A ansiedade e o estresse podem aumentar a sensação de desconforto durante a colheita de sangue. Portanto, tente manter a calma e relaxar antes e durante o procedimento.'
    },
    {
      'icon': Icons.integration_instructions_outlined,
      'text': 'Geralmente, um profissional de sáude ou um técnico especializado realizará a colheita de sangue. Ouça atentamente suas instruções e siga-as. Ouça atentamente saus instruções e siga-as'
          '. Eles podem pedir que você mantenha o braço estendido, evite movimentos bruscos ou mantenha a pressão em um local específico após a coleta.'
    },
    {
      'icon': Icons.task_alt_rounded,
      'text': 'Comunique-se com o profissional: Se você tiver alguma dúvida ou preocupação, não hesite em perguntar ao profissional de saúde responsável pela colheita de sangue.'

    }
  ];

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title:  Text('O que fazer durante?'),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: ListView.builder(itemCount: procedimentos.length,
            itemBuilder: (BuildContext context, int index){
              final procedimento = procedimentos[index];
              return ListTile(
                leading: Icon(procedimento['icon']),
                title: Text(procedimento['text']),
              );
            } ),
      ),
    );
  }
}