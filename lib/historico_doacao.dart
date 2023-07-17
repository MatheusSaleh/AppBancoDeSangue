// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class HistoricoDoacoes extends StatefulWidget {
  @override
  _HistoricoDoacoesState createState() => _HistoricoDoacoesState();
}

class _HistoricoDoacoesState extends State<HistoricoDoacoes> {
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
        title: const Text('Minhas Doações'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('doacoes')
            .where('uid_usuario', isEqualTo: _user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Erro ao carregar doações'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Voce não possui doações registradas.'),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doacao = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return ListTile(
                title: const Text('Doação'),
                subtitle: Text(doacao['data_doacao'] ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}
