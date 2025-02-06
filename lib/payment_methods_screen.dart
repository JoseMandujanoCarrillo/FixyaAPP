import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_card_screen.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  _PaymentMethodsScreenState createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  List<dynamic> creditCards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCreditCards();
  }

  Future<void> _loadCreditCards() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('https://apifixya.onrender.com/creditcards/user'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          creditCards = json.decode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading cards: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Métodos de Pago'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddCardScreen()),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: creditCards.length,
              itemBuilder: (context, index) {
                final card = creditCards[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.credit_card, size: 40),
                    title: Text(card['cardholderName'] ?? 'Sin nombre'),
                    subtitle: Text(
                        '**** **** **** ${card['cardNumber']?.substring(15) ?? ''}'),
                    trailing: Text('Expira: ${card['expirationDate'] ?? ''}'),
                  ),
                );
              },
            ),
    );
  }
}
