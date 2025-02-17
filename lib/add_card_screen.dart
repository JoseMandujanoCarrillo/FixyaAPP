import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// Se utiliza el paquete mask_text_input_formatter para formatear la fecha.
// Agrega en tu pubspec.yaml: mask_text_input_formatter: ^2.0.0
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

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
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _billingAddressController = TextEditingController();
  final TextEditingController _creditLimitController = TextEditingController();

  String _selectedCardType = 'Crédito';
  String _currency = 'USD'; // Puedes cambiar esto según sea necesario
  bool _isSaving = false; // Controla el estado del botón

  // Formatter para la fecha de expiración: inserta automáticamente el "/"
  final _expDateFormatter = MaskTextInputFormatter(
    mask: '##/##',
    filter: { "#": RegExp(r'\d') },
  );

  // Validación del número de tarjeta: permite solo 16 dígitos
  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Campo requerido';
    }
    final cardNumber = value.replaceAll(' ', '');
    if (cardNumber.length != 16 || !RegExp(r'^\d{16}$').hasMatch(cardNumber)) {
      return 'Número de tarjeta inválido';
    }
    return null;
  }

  // Validación de la fecha de expiración en formato MM/YY
  String? _validateExpirationDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Campo requerido';
    }
    if (value.length != 5 || !RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
      return 'Formato de fecha inválido';
    }
    final parts = value.split('/');
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);
    if (month == null || year == null) return 'Fecha inválida';
    if (month < 1 || month > 12) return 'Mes inválido';
    final currentYear = DateTime.now().year % 100;
    final currentMonth = DateTime.now().month;
    if (year < currentYear || (year == currentYear && month < currentMonth)) {
      return 'La tarjeta ya está expirada';
    }
    return null;
  }

  // Validación del CVV: debe ser de 3 dígitos
  String? _validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'Campo requerido';
    }
    if (value.length != 3 || !RegExp(r'^\d{3}$').hasMatch(value)) {
      return 'CVV inválido';
    }
    return null;
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true; // Deshabilitar el botón mientras se guarda
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final cardData = {
      'card_number': _cardNumberController.text.replaceAll(' ', ''),
      'expiration_date': _expDateController.text,
      'cvv': _cvvController.text,
      'cardholder_name': _cardNameController.text,
      'nickname': _nicknameController.text,
      'billing_address': {
        'address': _billingAddressController.text,
      },
      'credit_limit': double.tryParse(_creditLimitController.text) ?? 0.0,
      'currency': _currency,
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
      } else {
        print('Error al guardar tarjeta: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving card: $e');
    } finally {
      setState(() {
        _isSaving = false; // Volver a habilitar el botón
      });
    }
  }

  @override
  void dispose() {
    _cardNameController.dispose();
    _cardNumberController.dispose();
    _expDateController.dispose();
    _cvvController.dispose();
    _nicknameController.dispose();
    _billingAddressController.dispose();
    _creditLimitController.dispose();
    super.dispose();
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
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _cardNumberController,
                decoration: const InputDecoration(
                  labelText: 'Número de Tarjeta',
                  hintText: '**** **** **** ****',
                ),
                keyboardType: TextInputType.number,
                // Permite solo dígitos y máximo 16 números
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                ],
                validator: _validateCardNumber,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: 'Apodo de la tarjeta',
                  hintText: 'Ej. Tarjeta principal',
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _billingAddressController,
                decoration: const InputDecoration(
                  labelText: 'Dirección de facturación',
                  hintText: 'Dirección de facturación',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _creditLimitController,
                decoration: const InputDecoration(
                  labelText: 'Límite de crédito',
                  hintText: 'Ingrese límite de crédito',
                ),
                keyboardType: TextInputType.number,
                // Permite solo dígitos y el punto decimal
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedCardType,
                items: const [
                  DropdownMenuItem(value: 'Crédito', child: Text('Crédito')),
                ],
                onChanged: (value) => setState(() => _selectedCardType = value!),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expDateController,
                      decoration: const InputDecoration(
                        labelText: 'MM/YY',
                        hintText: 'MM/YY',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        _expDateFormatter,
                      ],
                      validator: _validateExpirationDate,
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
                      // Permite solo 3 dígitos
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      validator: _validateCVV,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 148, 214, 255),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text('GUARDAR TARJETA',
                        style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
