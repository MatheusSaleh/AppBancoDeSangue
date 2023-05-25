import 'package:flutter/material.dart';

class GuiaDoacaoScreen extends StatelessWidget{
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
          _buildMenuItem(context, 'O que fazer antes?', Colors.blue, Icons.question_mark),
          _buildMenuItem(context, 'O que fazer durante?', Colors.orange, Icons.question_mark),
          _buildMenuItem(context, 'O que fazer depois?', Colors.green, Icons.question_mark),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, Color color, IconData icon){
    return GestureDetector(
      onTap: (){

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
              style: TextStyle(
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