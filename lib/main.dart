import 'package:flutter/material.dart';
import 'package:flutter_example/homePage.dart';
import 'login.dart';
import 'signup.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(MyApp());

}

class MyApp extends StatelessWidget {

  final IO.Socket socket = IO.io('http://10.0.2.2:8000');


  MyApp() {
    socket.connect();
    final lobbyRequest = {
      'error': false,
      'errorMsg': '',
      'maxPlayers': 3,
    };
    socket.on('connect', (_) =>
      socket.emit("create-lobby", [lobbyRequest]));
    //socket.on('connect', (_) => print('Conectado al servidor Socket.IO'));

    print('Antes de emit');
    print('Enviando evento create-lobby...');
    socket.emit("create-lobby", [lobbyRequest]);

    // Esperar la respuesta (ACK) del servidor
    socket.once("create-lobby", (response) {
      print("ACK recibido del servidor: $response");
    });
    socket.on('disconnect', (_) => print('Desconectado del servidor'));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(socket: socket),
    );
  }
}

class HomeScreen extends StatelessWidget {

  final IO.Socket socket;

  HomeScreen({required this.socket}); // Recibimos el socket



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Welcome')),
      backgroundColor: Color(0xFF9D0514),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpScreen(socket: socket)),
                );
              },
              child: Text('Sign Up'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen(socket: socket)),
                );
              },
              child: Text('Log In'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MainScreen(socket: socket))
                  );
                },
                child: Text('TESTS')
            ),

            ElevatedButton(
              onPressed: () {
                if (socket.connected) {
                  final lobbyRequest = {
                    'error': false,
                    'errorMsg': '',
                    'maxPlayers': 3,
                  };
                  print('Antes de emit');
                  socket.emit("create-lobby", [lobbyRequest]);
                  print('dsp');
                  // Esperar la respuesta (ACK) del servidor
                  socket.once("create-lobby", (response) {
                    print("ACK recibido del servidor: $response");
                  });
                } else {
                  print('El socket no está conectado, intentando reconectar...');
                  socket.connect();
                  socket.on('connect', (_) {
                    print('Conectado al servidor, enviando evento...');
                    final lobbyRequest = {
                      'error': false,
                      'errorMsg': '',
                      'maxPlayers': 3,
                    };
                    socket.emit("create-lobby", [lobbyRequest]);
                  });
                }
              },
              child: Text('Enviar Evento'),
            ),


          ],
        ),
      ),
    );
  }
}


