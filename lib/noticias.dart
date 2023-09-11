import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NoticiasScreen extends StatefulWidget {
  const NoticiasScreen({super.key});
  @override
  NoticiasScreenState createState() => NoticiasScreenState();
}

class NoticiasScreenState extends State<NoticiasScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Noticias'),
        backgroundColor: Colors.red,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('noticias').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Erro ao carregar Noticias'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (BuildContext context, int index) {
              var doc = snapshot.data!.docs[index];
              return Card(
                elevation: 4, // Adicione sombreamento ao card
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${doc['titulo']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 30, // Tamanho de fonte maior
                        ),
                      ),
                      Text('${doc['noticia']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18
                        ),
                      ),
                      Text('${doc['resumo']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 18
                      ),
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(height: 16),
          );
        },
      ),
    );
  }
}
