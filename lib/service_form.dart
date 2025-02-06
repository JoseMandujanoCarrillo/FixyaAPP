import 'package:flutter/material.dart';
import 'location_selection_screen.dart';

class ServiceFormScreen extends StatefulWidget {
  final Map<String, dynamic> service;

  const ServiceFormScreen({super.key, required this.service});

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade100,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildServiceCard(),
            const SizedBox(height: 15),
            _buildForm(),
            const SizedBox(height: 20),
            _buildNextButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.service['name'] ?? 'Servicio limpieza',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 5),
            Text(
              widget.service['address'] ?? 'C. 111 315, Santa Rosa, 97279 Mérida, Yuc.',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '\$${widget.service['price'] ?? 'XXXXX'}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const Text(' aprox', style: TextStyle(fontSize: 14, color: Colors.green)),
                const Spacer(),
                const CircleAvatar(
                  backgroundColor: Colors.blue,
                  radius: 25,
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Datos del servicio',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildTextField('Selecciona un tipo de servicio'),
            _buildDateField(),
            _buildTimeField(),
            _buildAddressField(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: _dateController,
        readOnly: true,
        decoration: InputDecoration(
          hintText: 'DD/MM/AA',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey.shade200,
          suffixIcon: const Icon(Icons.calendar_today, color: Colors.blue),
        ),
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2022),
            lastDate: DateTime(2030),
          );

          if (pickedDate != null) {
            setState(() {
              _dateController.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
            });
          }
        },
      ),
    );
  }

  Widget _buildTimeField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: _timeController,
        readOnly: true,
        decoration: InputDecoration(
          hintText: 'HH/MM/SS',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey.shade200,
          suffixIcon: const Icon(Icons.access_time, color: Colors.blue),
        ),
        onTap: () async {
          TimeOfDay? pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );

          if (pickedTime != null) {
            setState(() {
              _timeController.text = "${pickedTime.hour}:${pickedTime.minute}:00";
            });
          }
        },
      ),
    );
  }

Widget _buildAddressField() {
  return Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: TextField(
      controller: _addressController,
      readOnly: true,
      decoration: InputDecoration(
        hintText: 'Ubicación (toca para seleccionar)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey.shade200,
        suffixIcon: const Icon(Icons.map, color: Colors.blue),
      ),
      onTap: () async {
        final selectedAddress = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LocationSelectionScreen(),
          ),
        );

        if (selectedAddress != null && selectedAddress is String) {
          setState(() {
            _addressController.text = selectedAddress;
          });
        }
      },
    ),
  );
}


  Widget _buildTextField(String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey.shade200,
        ),
      ),
    );
  }

  Widget _buildNextButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade900,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () {},
          child: const Text('Siguiente', style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ),
    );
  }
}
