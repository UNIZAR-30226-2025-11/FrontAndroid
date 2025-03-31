import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_example/SessionManager.dart';
import 'package:flutter_example/editProfile.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_example/lobbyLeader.dart';
import 'game.dart';
import 'statistics.dart';
import 'login.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'shop.dart';
import 'joinGame.dart';

class MainScreen extends StatefulWidget {
  MainScreen();

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late IO.Socket socket;
  late Future<String?> _usernameFuture;
  String username = ""; // Valor predeterminado
  int coins=-1;

  @override
  void initState() {
    super.initState();
    _usernameFuture = _initializeUsername();
    _initializeSocket();
    _initializeCoins();
  }

  Future<String?> _initializeUsername() async {
    try {
      final String? user = await SessionManager.getUsername();
      setState(() {
        username = user ?? ""; // Actualiza el username cuando esté disponible

      });
      return user;
    } catch (e) {
      print("Error initializing username: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Username error: $e"))
      );
      return "";
    }
  }

  Future<void> _initializeCoins()async{
    try{
      final String? token = await SessionManager.getSessionData();
      final res = await
      http.get(Uri.parse('http://10.0.2.2:8000/users/:$username'),
          headers: {
            'Cookie': 'access_token=$token',
          }

      );
      print('$username');
      final headers = res.headers;
      final data = jsonDecode(res.body);

      if (res.statusCode != 200) {
        var errorMessage = data.containsKey('message')
            ? data['message']
            : "Something went wrong. Try later";

        print(errorMessage);
        return;

      }else {
        coins = data['coins'];
       }
    }catch (e) {
      print("Error initializing coins: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Coins error: $e"))
      );
    }
  }

  Future<void> _initializeSocket() async {
    try {
      // Await the token since it's a Future
      final String? token = await SessionManager.getSessionData();

      if (token == null || token.isEmpty) {
        print("Warning: Token is null or empty");
        // Handle missing token - perhaps redirect to login
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen())
        );
        return;
      }

      print("Connecting with token: ${token.substring(0, math.min(10, token.length))}...");

      socket = IO.io(
          'http://10.0.2.2:8000',
          IO.OptionBuilder()
              .setTransports(['websocket'])
              .setExtraHeaders({
            'Cookie': 'access_token=$token'
          })
              .enableForceNew()
              .disableAutoConnect()
              .build());

      // Set up error handling for connection
      socket.onConnectError((error) {
        print("Socket connection error: $error");
        // Handle connection error
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Connection error: Unable to authenticate"))
        );
      });

      socket.connect();

      // Set up socket listeners
      _setupSocketListeners();
    } catch (e) {
      print("Error initializing socket: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Authentication error: $e"))
      );
    }
  }

  void _setupSocketListeners() {
    // Listen for create-lobby response
    socket.on("create-lobby", (dynamic response) {
      if (response != null && response['error'] == false) {
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
        String errorMsg = response != null
            ? response['errorMsg']
            : "Error creating the lobby.";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    });
  }

  @override
  void dispose() {
    socket.disconnect();
    socket.dispose();
    super.dispose();
  }

  // Método para crear una sala de lobby
  void _createLobby(int maxPlayers) {
    final lobbyRequest = {
      'error': false,
      'errorMsg': '',
      'maxPlayers': maxPlayers,
    };
    socket.emit("create-lobby", [lobbyRequest]);
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
                      onPressed: () {
                        Navigator.pop(context, 2);
                        _createLobby(2);
                      },
                      child: Text("2"),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, 3);
                        _createLobby(3);
                      },
                      child: Text("3"),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, 4);
                        _createLobby(4);
                      },
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
    Navigator.pop(
        context); // Cierra el drawer de perfil antes de mostrar el Snackbar

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
                  MaterialPageRoute(
                      builder: (context) => LoginScreen()), // Redirige al login
                );
              },
              child: Text("YES", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                scaffoldMessenger
                    .hideCurrentSnackBar(); // Descartar el Snackbar
              },
              child: Text("NO", style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
        duration: Duration(
            days: 365), // Lo mantiene abierto hasta que el usuario interactúe
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
                    MaterialPageRoute(
                        builder: (context) => StatisticsScreen(
                          username: username,
                        )),
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
                    MaterialPageRoute(
                        builder: (context) => EditProfileScreen(
                          username: username,
                        )),
                  );
                },
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text("Logout"),
                onTap:(){ _showLogOutBar;
                  SessionManager.removeSessionData();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => LoginScreen()),
                  );
                  }

              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _usernameFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text("Error: ${snapshot.error}"),
            ),
          );
        } else {
          // Si el username está vacío y no hay error, probablemente falló la inicialización
          if (username.isEmpty && !snapshot.hasError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            });
          }

          return Scaffold(
            backgroundColor: Color(0xFF9D0514),
            body: Stack(
              children: [
                Positioned(
                  top: 48,
                  right: 30,
                  child: Row(
                    children: [
                      SizedBox(width: 8),
                      Icon(Icons.monetization_on, color: Colors.yellow, size: 30),
                      SizedBox(width: 8),
                      Text('$coins',
                          style: TextStyle(color: Colors.white, fontSize: 18)),
                    ],
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 30,
                  child: Row(
                    children: [
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.person,
                            size: 30, color: Colors.white), // Botón de perfil
                        onPressed: _openProfileDrawer,
                      ),
                      SizedBox(width: 8),
                      Text(username,
                          style: TextStyle(color: Colors.white, fontSize: 18)),
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
                            MaterialPageRoute(
                                builder: (context) => JoinGameScreen(
                                  socket: socket,
                                )),
                          );
                        },
                        child: Text("Join Lobby"),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ShopScreen(
                                  username: username,
                                )),
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
      },
    );
  }
}