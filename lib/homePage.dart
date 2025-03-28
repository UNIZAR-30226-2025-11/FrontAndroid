import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_example/editProfile.dart';
import 'package:flutter_example/lobbyLeader.dart';
import 'game.dart';
import 'statistics.dart';
import 'login.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'shop.dart';
import 'joinGame.dart';

class MainScreen extends StatefulWidget {
  //final IO.Socket socket;
  final String username;
  final IO.Socket socket = IO.io('http://10.0.2.2:8000',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableForceNew()
          .disableAutoConnect()
          .build()
  );
  MainScreen({required this.username}){
    socket.connect();
  }

  @override
  _MainScreenState createState() => _MainScreenState();

}

class _MainScreenState extends State<MainScreen> {
  late IO.Socket socket;
  late String username;

  @override
  void initState() {
    super.initState();
    username = widget.username;
    //socket.connect();
    //socket = widget.socket; // Asigna el socket correctamente
  }

  // Método para crear una sala de lobby
  void _createLobby(int maxPlayers) {
    final lobbyRequest = {
      'error': false,
      'errorMsg': '',
      'maxPlayers': maxPlayers,
    };
    print('Antes de emit');
    socket.emit("create-lobby", [lobbyRequest]);
    print('después');

// Escuchar la respuesta del servidor
    socket.on("create-lobby", (dynamic response) {
      print('once');
      if (response != null && response['error'] == false) {
        print('IF');
        String lobbyId = response['lobbyId'];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StartGameScreen(
              socket: socket,
              lobbyId: lobbyId,
              username: username,
            ),
          ),
        );

      } else {
        String errorMsg = response != null ? response['errorMsg'] : "Error creating the lobby.";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    });
  }

  // Método para mostrar el dialogo de selección de jugadores
  Future<int?> _showPlayerSelectionDialog(BuildContext context) async {
    return showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select Number of Players"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Choose how many players can join your lobby."),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _createLobby(2),
                      child: Text("2"),

                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _createLobby(3),
                      child: Text("3"),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _createLobby(4),
                      child: Text("4"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }


  // Método para mostrar el Snackbar de confirmación de logout
  void _showLogOutBar() {
    Navigator.pop(context); // Cierra el drawer de perfil antes de mostrar el Snackbar

    var scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text("Are you sure you want to log out?",
                  style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                scaffoldMessenger.hideCurrentSnackBar();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()), // Redirige al login
                );
              },
              child: Text("YES", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                scaffoldMessenger.hideCurrentSnackBar(); // Descartar el Snackbar
              },
              child: Text("NO", style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
        duration: Duration(days: 365), // Lo mantiene abierto hasta que el usuario interactúe
      ),
    );
  }

  // Método para abrir el drawer de perfil
  void _openProfileDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Profile Settings",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.bar_chart),
                title: Text("Statistics"),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => StatisticsScreen(username: username,)),
                  );
                },
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text("Edit profile"),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => EditProfileScreen(username: username,)),
                  );
                },
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text("Logout"),
                onTap: _showLogOutBar,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*appBar: AppBar(
        title: Text("Main Screen"),
        automaticallyImplyLeading: false, // Remueve el botón de regreso
      ),*/
      backgroundColor: Color(0xFF9D0514),
      body: Stack(
        children: [
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              children: [
                Text('username', style: TextStyle(color: Colors.white, fontSize: 18)),
                SizedBox(width: 8),
                Icon(Icons.monetization_on, color: Colors.yellow, size: 30),
                SizedBox(width: 4),
                Text('5 coins', style: TextStyle(color: Colors.white, fontSize: 18)),
                IconButton(
                  icon: Icon(Icons.person, size: 30, color: Colors.white), // Botón de perfil
                  onPressed: _openProfileDrawer,
                ),
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    // Se ejecuta cuando se crea una nueva sala
                    int? players = await _showPlayerSelectionDialog(context);
                  },
                  child: Text("New Lobby"),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => JoinGameScreen(socket: socket, username: username,)),
                    );
                  },
                  child: Text("Join Lobby"),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ShopScreen(username: username,)),
                    );
                  },
                  child: Text("Shop"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
