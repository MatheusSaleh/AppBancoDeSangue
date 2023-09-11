import 'package:appbancodesangue/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FormularioDoacao extends StatefulWidget {
  const FormularioDoacao({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _FormularioDoacaoState createState() => _FormularioDoacaoState();
}

class _FormularioDoacaoState extends State<FormularioDoacao> {
  DateTime _selectedDate = DateTime.now();

  final TextEditingController _nomeController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formulário de Doação de Sangue'),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          child: Column(
            children: [
              const Text(
                  "Digite o seu nome completo abaixo, e caso sua doação esteja sendo realizada "
                  "em uma data diferente da atual, modifique clicando no botão 'Selecionar Data'. Para confirmar o registro de "
                  "sua doação clique no botão 'Registrar Doação'."),
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Digite o seu Nome'),
                controller: _nomeController,
              ),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Data da Doação',
                      style: TextStyle(fontSize: 16.0),
                    ),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(fontSize: 16.0),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _selectDate(context),
                child: const Text('Selecionar Data'),
              ),
              const SizedBox(
                height: 16.0,
              ),
              ElevatedButton(
                  onPressed: () async {
                    String nomeUsuario = _nomeController.text;

                    String data = _selectedDate.toString();

                    final FirebaseAuth auth = FirebaseAuth.instance;
                    final User? user = auth.currentUser;

                    if (user != null) {
                      String uid = user.uid;

                      final firestore = FirebaseFirestore.instance;
                      final doacoesRef = firestore.collection('doacoes');

                      final novaDoacao = {
                        'nome': nomeUsuario,
                        'data_doacao': data,
                        'uid_usuario': uid,
                      };
                      await doacoesRef.add(novaDoacao);
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => HomeScreen(),
                      ));
                    }
                  },
                  child: const Text('Registrar Doação'))
            ],
          ),
        ),
      ),
    );
  }
}
