import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  _AddCardScreenState createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cardNameController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  String _selectedCardType = 'Crédito';

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) return;

    final cardData = {
      'cardholderName': _cardNameController.text,
      'cardNumber': _cardNumberController.text.replaceAll(' ', ''),
      'expirationDate': _expDateController.text,
      'cvv': _cvvController.text,
      'cardType': _selectedCardType,
    };

    try {
      final response = await http.post(
        Uri.parse('https://apifixya.onrender.com/creditcards'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(cardData),
      );

      if (response.statusCode == 201) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error saving card: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Tarjeta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _cardNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de Tarjeta',
                  hintText: 'Ingrese un nombre',
                ),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _cardNumberController,
                decoration: const InputDecoration(
                  labelText: 'Número de Tarjeta',
                  hintText: '**** **** **** ****',
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value!.length < 16 ? 'Número inválido' : null,
              ),
              DropdownButtonFormField<String>(
                value: _selectedCardType,
                items: const [
                  DropdownMenuItem(value: 'Crédito', child: Text('Crédito')),
                ],
                onChanged: (value) => setState(() => _selectedCardType = value!),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expDateController,
                      decoration: const InputDecoration(
                        labelText: 'MM/YY',
                        hintText: 'MM/YY',
                      ),
                      validator: (value) => value!.length != 5 ? 'Formato inválido' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        hintText: '***',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.length != 3 ? 'CVV inválido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('GUARDAR TARJETA', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}