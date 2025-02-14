import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter HTTP Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _message = "Presiona el botón para obtener el mensaje";

  String message = '';

  Future<void> fetchMessage() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:3000/hello'));

    if (response.statusCode == 200) {
      // Si la respuesta es texto, solo asigna el cuerpo de la respuesta a message
      setState(() {
        _message = response.body;  // Aquí usamos el texto plano directamente
      });
      print('Mensaje recibido: ${response.body}');
    } else {
      setState(() {
        _message = 'Error al obtener el mensaje: ${response.statusCode}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Flutter HTTP")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: fetchMessage,
              child: const Text("Obtener Mensaje"),
            ),
          ],
        ),
      ),
    );
  }
}
