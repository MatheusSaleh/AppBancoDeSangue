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
    },
    {
      'icon': Icons.schedule,
      'text': 'Evite atividades extenuantes: Evite exercícios vigorosos ou atividades '
          'que exijam muito esforço físico nas primeiras 24 horas após a doação. Seu corpo'
          'precisa de tempo para se recuperar completamente.'
    },
    {
      'icon': Icons.no_drinks,
      'text': 'Evite álcool e fumar: Evite o consumo de álcool e o tabagismo por pelo menos'
          '24 horas após a doação de sangue. Essas substâncias podem afetar negativamente sua '
          'recuperação e desidratá-lo ainda mais.'
    },
    {
      'icon': Icons.sd_card_alert,
      'text': 'Cuidados com o local da punção: Mantenha o curativo no local da '
          'punção por pelo menos algumas horas. Evite levantar objetos pesados ou fazer '
          'movimentos bruscos com o braço doado, a fim de evitar qualquer sangramento ou desconforto adicional.'
    },
    {
      'icon': Icons.checklist_rtl_outlined,
      'text': 'Siga as instruções do profissional de saúde: '
          'É fundamental seguir as orientações específicas fornecidas pela '
          'equipe médica ou pelo centro de doação de sangue. Eles podem fornecer '
          'informações adicionais e responder a quiasquer perguntas que voce possa ter.'
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