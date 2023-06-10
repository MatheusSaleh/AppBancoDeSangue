import 'package:flutter/material.dart';


class FormularioDoacao extends StatefulWidget{
  @override
  _FormularioDoacaoState createState() => _FormularioDoacaoState();
}

class _FormularioDoacaoState extends State<FormularioDoacao>{

  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if(picked != null && picked != _selectedDate)
      setState(() {
        _selectedDate = picked;
      });
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text('Formulário de Doação de Sangue'),
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Form(
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Nome'),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'E-mail'),
                keyboardType: TextInputType.emailAddress,
              ),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Data da Doação',
                      style: TextStyle(fontSize: 16.0),
                    ),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ],
                ),
              ),
              ElevatedButton(onPressed: (){}, child: Text('Enviar'))
            ],
          ),
        ),
      ),

    );
  }
}