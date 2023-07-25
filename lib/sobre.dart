import 'package:flutter/material.dart';

class SobreScreen extends StatelessWidget{
  const SobreScreen({super.key});

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobre'),
        backgroundColor: Colors.red,
      ),
      body: const Center(
        child: Text(
          'Aplicativo desenvolvido por Matheus Saleh\n'
              'Gabriel Eduardo\n'
              'Centro de Pesquisas em Informatica da FEMA',
              textAlign: TextAlign.center,
        ),
      ),
    );
  }
}