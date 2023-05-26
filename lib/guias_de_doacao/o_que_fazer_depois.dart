import 'package:flutter/material.dart';

class DepoisScreen extends StatelessWidget{
   DepoisScreen({super.key});

  final List<Map<String, dynamic>> procedimentos = [
    {
      'icon': Icons.bed,
      'text': 'Descanso: É importante descansar por alguns minutos após a doação de sangue. Isso permite que seu corpo se recupere do processo e evita possíveis tonturas ou fraquezas.',
    },
    {
      'icon': Icons.food_bank,
      'text': 'Lanche: A maioria dos bancos de sangue oferece um lanche ou bebida após a doação de sangue. É importante consumir algo para repor a energia e ajudar na recuperação. Geralmente, é recomendado beber líquidos e comer alimentos leves e saudáveis, como suco, água, frutas ou lanches nutritivos.',
    },
    {
      'icon': Icons.local_drink,
      'text': 'Hidratação: Beba bastante líquido nas horas seguintes à doação de sangue. Isso ajuda a repor os fluidos corporais perdidos durante o processo.'
    }
  ];

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('O que fazer depois?'),
        backgroundColor: Colors.green,
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