import 'package:appbancodesangue/guias_de_doacao/o_que_fazer_antes.dart';
import 'package:appbancodesangue/guias_de_doacao/o_que_fazer_depois.dart';
import 'package:appbancodesangue/guias_de_doacao/o_que_fazer_durante.dart';
import 'package:flutter/material.dart';

class GuiaDoacaoScreen extends StatelessWidget{
  const GuiaDoacaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guia de Doação'),
        backgroundColor: Colors.grey,
      ),
      body: GridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.all(16),
          childAspectRatio: 1.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        children: [
          _buildMenuItem(context, 'O que fazer antes?', Colors.blue, Icons.question_mark,  AntesScreen()),
          _buildMenuItem(context, 'O que fazer durante?', Colors.orange, Icons.question_mark,  DuranteScreen()),
          _buildMenuItem(context, 'O que fazer depois?', Colors.green, Icons.question_mark, DepoisScreen()),
        ],
      ),
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen){
    Navigator.push(context,
    MaterialPageRoute(builder: (context) => screen),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, Color color, IconData icon, Widget screen){
    return GestureDetector(
      onTap: (){
        _navigateToScreen(context, screen);
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.white),
            const SizedBox(
              height: 8,
            ),
            Text(
                title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold
              ),
            )
          ],
        ),
      ),
    );
  }
}