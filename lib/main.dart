import 'package:appbancodesangue/guia_doacao_sangue.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Banco de Sangue',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 221, 46, 33)),
        useMaterial3: true,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final List<String> _options = [
    'Notícias',
    'Registrar Doação de Sangue',
    'Guia de Doação',
    'Histórico',
    'Sobre',
    'Parte Administrativa',
  ];

  final List<IconData> icons = [
    Icons.article,
    Icons.favorite,
    Icons.fact_check_outlined,
    Icons.history,
    Icons.info,
    Icons.admin_panel_settings
  ];

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Doação de Sangue'),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: _options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          return GestureDetector(
            onTap: () {
              if(index == 2){
                Navigator.push(context, MaterialPageRoute(builder: (context) => GuiaDoacaoScreen()),
                );
              } else{
                print(option);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icons[index]),
                  const SizedBox(height: 8),
                  Text(option)
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
