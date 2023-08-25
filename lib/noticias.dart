import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NoticiasScreen extends StatefulWidget {
  const NoticiasScreen({super.key});
  @override
  NoticiasScreenState createState() => NoticiasScreenState();
}

class NoticiasScreenState extends State<NoticiasScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
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
          final List<int> colorCodes = <int>[600, 500, 100];
          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (BuildContext context, int index) {
              var doc = snapshot.data!.docs[index];
              return Container(
                height: 100, // Ajuste a altura conforme necessário
                color: Colors.amber[
                    colorCodes[index]], // Certifique-se de definir colorCodes
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Título: ${doc['titulo']}'),
                    Text('Conteúdo: ${doc['noticia']}'),
                    Text('Resumo: ${doc['resumo']}'),
                  ],
                ),
              );
            },
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(),
          );

      
        },
      ),
    );
  }
}
