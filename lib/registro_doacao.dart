import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FormularioDoacao extends StatefulWidget{
  const FormularioDoacao({super.key});

  @override
  _FormularioDoacaoState createState() => _FormularioDoacaoState();
}

class _FormularioDoacaoState extends State<FormularioDoacao>{

  

  DateTime _selectedDate = DateTime.now();
  
  final TextEditingController _nomeController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if(picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formulário de Doação de Sangue'),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          child: Column(
            children: [
              Text("Digite o seu nome completo abaixo, e caso sua doação esteja sendo realizada "
                  "em uma data diferente da atual, modifique clicando no botão 'Selecionar Data'. Para confirmar o registro de "
                  "sua doação clique no botão 'Registrar Doação'."),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Digite o seu Nome'),
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
              const SizedBox(height: 16.0,),
              ElevatedButton(
                  onPressed: (){

                    String nomeUsuario = _nomeController.text;

                    String data = _selectedDate.toString();
                    
                    final firestore = FirebaseFirestore.instance;
                    
                    final doacoesRef = firestore.collection('doacoes');

                    final novaDoacao = {
                      'nome': nomeUsuario,
                      'data_doacao': data
                    };

                    doacoesRef.add(novaDoacao);
                  },
                  child: const Text('Registrar Doação')
              )
            ],
          ),
        ),
      ),
    );
  }
}
