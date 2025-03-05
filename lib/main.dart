import 'package:flutter/material.dart';
import 'package:flutter_example/homePage.dart';
import 'login.dart';
import 'signup.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(MyApp());

}

class MyApp extends StatelessWidget {

  final IO.Socket socket = IO.io('http://10.0.2.2:3000', <String, dynamic>{
    'transports': ['websocket'],
    'autoConnect': false,
  });

  MyApp() {
    socket.connect();
    socket.on('connect', (_) => print('Conectado al servidor Socket.IO'));
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

          ],
        ),
      ),
    );
  }
}


