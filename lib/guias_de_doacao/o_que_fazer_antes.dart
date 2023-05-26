import 'package:flutter/material.dart';

class AntesScreen extends StatelessWidget{
  const AntesScreen({super.key});

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('O que fazer antes?'),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text(
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
          style: TextStyle(fontSize: 16),
        ),
      )
    );
  }
}