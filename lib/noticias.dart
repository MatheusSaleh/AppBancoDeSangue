import 'package:flutter/material.dart';

class NoticiasScreen extends StatelessWidget {
  const NoticiasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(
      title: const Text('Noticias'),
      backgroundColor: Colors.red,
    ),
    body: const Center(
      child: Text(
        'Aqui ficará as ultimas notícias públicadas sobre o banco de sangue'
      ),
    ),
    );
  }
}
