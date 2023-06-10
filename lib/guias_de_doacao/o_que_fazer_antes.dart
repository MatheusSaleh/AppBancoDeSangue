import 'package:flutter/material.dart';

class AntesScreen extends StatelessWidget{
  AntesScreen({super.key});

  final List<Map<String, dynamic>> procedimentos = [
    {
      'icon': Icons.checklist_rtl_outlined,
      'text': 'Verifique os requisitos básicos: Verifique se você atende aos requisitos básicos para doar sangue,'
          ' como idade mínima (geralmente 18 anos, mas pode variar dependendo do país), peso adequado (geralmente acima'
          ' de 50 kg) e boa saúde geral'
    },
    {
      'icon': Icons.food_bank_outlined,
      'text': 'Faça uma refeição saudável: Certifique-se de ter uma refeição nutritiva antes da doação de sangue. Comer alimentos'
          ' ricos em ferro, como carnes magras, feijões, espinafre e alimentos ricos em vitamina C, como frutas cítricas, pode ajudar a aumentar'
          ' seus níveis de ferro.'
    },
    {
      'icon': Icons.water_drop_outlined,
      'text': 'Beba bastante líquido nas 24 horas anteriores à doação de sangue para garantir que você esteja bem hidratado. Evite bebidas alcoólicas nas últimas 24 horas antes da doação.'
    },
    {
      'icon': Icons.bed,
      'text': 'Desanse bem: Tenha uma boa noite de sono antes da doação de sangue para garantir que você esteja descansado.'
    },
    {
      'icon': Icons.person_off,
      'text': 'Evite atividade física intensa: Evite exercícios vigorosos ou atividades extenuantes antes da doação de sangue. Isto pode ajudar a evitar tonturas ou fraqueza durante o processo.'
    },
  ];

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('O que fazer antes?'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: ListView.builder(
          itemCount: procedimentos.length,
          itemBuilder: (BuildContext context, int index){
            final procedimento = procedimentos[index];
            return ListTile(
              leading: Icon(procedimento['icon']),
              title: Text(procedimento['text']),
            );
          },
        )
      ),
    );
  }
}