import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_example/shop.dart' as shop;
import 'package:http/http.dart' as http;
import 'package:flutter_example/lobbyLeader.dart';
import 'package:flutter_example/statistics.dart';
import 'SessionManager.dart';
import 'UserInfo.dart';
import 'editProfile.dart';
import 'friends.dart';
import 'game.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'joinGame.dart';
import 'login.dart';
import 'customize.dart';

class MainScreen extends StatefulWidget {
  MainScreen();

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late IO.Socket socket;
  late Future<void> _initFuture;
  final UserInfo userInfo = UserInfo();

  @override
  void initState() {
    super.initState();
    _initFuture = _initialize();
  }

  Future<void> _initialize() async {
    await userInfo.initialize();
    await _initializeSocket();
  }

  Future<void> _initializeSocket() async {
    try {
      // Await the token since it's a Future
      final String? token = await SessionManager.getSessionData();

      if (token == null || token.isEmpty) {
        print("Warning: Token is null or empty");
        // Handle missing token - perhaps redirect to login
        if (mounted) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen())
          );
        }
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
          //.enableForceNew()
              .disableAutoConnect()
              .build());

      // Set up error handling for connection
      socket.onConnectError((error) {
        print("Socket connection error: $error");
        // Handle connection error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Connection error: Unable to authenticate"))
          );
        }
      });

      socket.connect();

      // Set up socket listeners
      _setupSocketListeners();
    } catch (e) {
      print("Error initializing socket: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Authentication error: $e"))
        );
      }
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
              username: userInfo.username,
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
    // First, get a reference to the scaffold context before closing the drawer
    final mainContext = context;

    // Close the drawer
    Navigator.pop(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(mainContext).showSnackBar(
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
                  ScaffoldMessenger.of(mainContext).hideCurrentSnackBar();
                  SessionManager.removeSessionData();
                  Navigator.pushReplacement(
                    mainContext,
                    MaterialPageRoute(
                        builder: (context) => LoginScreen()),
                  );
                },
                child: Text("YES", style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(mainContext).hideCurrentSnackBar();
                },
                child: Text("NO", style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black12,
          duration: Duration(days: 365),
        ),
      );
    });
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: userInfo.avatarUrl.isNotEmpty
                          ? DecorationImage(
                        image: AssetImage('assets/images/avatar/${userInfo.avatarUrl}.png'),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: userInfo.avatarUrl.isEmpty
                        ? Icon(Icons.person, size: 40)
                        : null,
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userInfo.username,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Icon(Icons.monetization_on, color: Colors.yellow, size: 16),
                          SizedBox(width: 4),
                          Text("${userInfo.coins}"),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Divider(height: 30),
              ListTile(
                leading: Icon(Icons.bar_chart),
                title: Text("Statistics"),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>StatisticsScreen(
                          username: userInfo.username,
                        )),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text("Edit profile"),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => EditProfileScreen(
                          username: userInfo.username,
                        )),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.style),
                title: Text("Customize"),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CustomizeScreen(
                          username: userInfo.username,
                        )),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.shopping_cart),
                title: Text("Shop"),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => shop.ShopScreen(
                          username: userInfo.username,
                        )),
                  );
                },
              ),
              ListTile(
                  leading: Icon(Icons.people),
                  title: Text("Friends"),
                  onTap:(){
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => FriendsScreen()),
                    );
                  }
              ),
              ListTile(
                  leading: Icon(Icons.logout),
                  title: Text("Logout"),
                  onTap: () {
                    _showLogOutBar();
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
    return FutureBuilder<void>(
      future: _initFuture,
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
          if (userInfo.username.isEmpty && !snapshot.hasError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            });
          }

          return Scaffold(
            backgroundColor: Color(0xFF9D0514),
            body: Container(
              decoration: userInfo.backgroundUrl.isNotEmpty
                  ? BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background/${userInfo.backgroundUrl}.png'),
                  fit: BoxFit.cover,
                  opacity: 0.5,
                ),
              )
                  : null,
              child: Stack(
                children: [
                  Positioned(
                    top: 48,
                    right: 30,
                    child: Row(
                      children: [
                        SizedBox(width: 8),
                        Icon(Icons.monetization_on, color: Colors.yellow, size: 30),
                        SizedBox(width: 8),
                        Text('${userInfo.coins}',
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
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                            image: userInfo.avatarUrl.isNotEmpty
                                ? DecorationImage(
                              image: AssetImage('assets/images/avatar/${userInfo.avatarUrl}.png'),
                              fit: BoxFit.cover,
                            )
                                : null,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: _openProfileDrawer,
                              child: userInfo.avatarUrl.isEmpty
                                  ? Icon(Icons.person, color: Colors.white)
                                  : null,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(userInfo.username,
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}