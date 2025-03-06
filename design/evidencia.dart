import 'package:flutter/material.dart';

class EvidenciaScreen extends StatefulWidget {
  @override
  _EvidenciaScreenState createState() => _EvidenciaScreenState();
}

class _EvidenciaScreenState extends State<EvidenciaScreen> {
  TextEditingController _comentarioController = TextEditingController();
  bool _isLoading = false;

  void _submitComentario() async {
    setState(() {
      _isLoading = true;
    });

    // Simula un proceso de carga (como un envío de comentario)
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    // Mostrar mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Comentario enviado")),
    );

    // Volver a la pantalla anterior
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Agregar Comentario o Evidencia"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _comentarioController,
              decoration: InputDecoration(labelText: "Comentario"),
              maxLines: 5,
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                // Aquí va la lógica para tomar la foto
              },
              child: Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey[300],
                child: Center(
                  child: Text(
                    "Seleccionar foto",
                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitComentario,
              child: _isLoading
                  ? CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : Text("Aceptar"),
            ),
          ],
        ),
      ),
    );
  }
}
