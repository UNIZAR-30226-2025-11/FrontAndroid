import 'package:flutter/material.dart';
import 'package:flutter_example/lobby.dart';
import 'package:flutter_example/shop.dart';
import 'package:flutter_example/statistics.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'SessionManager.dart';
import 'UserInfo.dart';
import 'customize.dart';
import 'editProfile.dart';
import 'friends.dart';
import 'homePage.dart';
import 'login.dart';

class JoinGameScreen extends StatefulWidget {
  final IO.Socket socket;

  JoinGameScreen({required this.socket});

  @override
  _JoinGameState createState() => _JoinGameState();
}

class _JoinGameState extends State<JoinGameScreen> {
  final TextEditingController roomCodeController = TextEditingController();
  String? errorMessage;

  late Future<String?> _usernameFuture;
  String username = ""; // Valor predeterminado
  int coins=-1;
  final UserInfo userInfo = UserInfo();
  bool isLoading = true;


  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await userInfo.initialize();
    setState(() {
      username = userInfo.username;
      coins = userInfo.coins;
      isLoading = false;
    });
  }


  void joinGame() {
    String lobbyId = roomCodeController.text.trim();
    if (lobbyId.isEmpty) {
      setState(() => errorMessage = "Please enter a room code");
      return;
    }

    // Enviar solicitud de unión al servidor a través del socket
    widget.socket.emit(
        'join-lobby', {"error": false, "errorMsg": "", "lobbyId": lobbyId});

    // Escuchar la respuesta del servidor
    widget.socket.once('join-lobby', (data) {
      if (data["error"] == false) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => WaitingScreen(
                    socket: widget.socket,
                    lobbyId: lobbyId,
                  )),
        );
      } else {
        setState(() => errorMessage = data["errorMsg"]);
      }
    });
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

  Future<void> _initializeCoins() async {
    try {
      final String? token = await SessionManager.getSessionData();
      final res = await http.get(
          Uri.parse('http://10.0.2.2:8000/user'),
          headers: {
            'Cookie': 'access_token=$token',
          }
      );

      print('Current username: $username');
      final data = jsonDecode(res.body);

      if (res.statusCode != 200) {
        var errorMessage = data.containsKey('message')
            ? data['message']
            : "Something went wrong. Try later";

        print(errorMessage);
        return;
      } else {

        // Use setState to update the UI
        setState(() {
          coins = int.parse(data['coins'].toString());
        });
        print("Found user, coins: $coins");
      }
    } catch (e) {
      print("Error initializing coins: $e");
      if (mounted) {  // Check if widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Coins error: $e"))
        );
      }
    }
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // User Info Section
                  Row(
                    children: [
                      // Avatar
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
                  // Home Button Section
                  InkWell(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MainScreen()
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200], // Light background for the button
                        borderRadius: BorderRadius.circular(20), // Rounded corners
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.home, color: Colors.black87),
                          SizedBox(width: 6),
                          Text(
                            "Home",
                            style: TextStyle(color: Colors.black87, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
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
                        builder: (context) => StatisticsScreen(
                          username: userInfo.username,
                        )),
                  );
                  setState(() {
                    _initialize();
                  });
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
                  setState(() {
                    _initialize();
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.style),
                title: Text("Customize"),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CustomizeScreen(
                          username: userInfo.username,
                        )),
                  );
                  setState(() {
                    print('custome set state');
                    _initialize();
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.shopping_cart),
                title: Text("Shop"),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ShopScreen(
                          username: userInfo.username,
                        )),
                  );
                  setState(() {
                    _initialize();
                  });
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
                    setState(() {
                      _initialize();
                    });
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

  // Método para mostrar la barra de confirmación de cierre de sesión
  void _showLogOutBar() {
    // Primero, cierra el drawer
    Navigator.pop(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
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
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  SessionManager.removeSessionData();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MainScreen()),
                  );
                },
                child: Text("YES", style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
                child: Text("NO", style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF3D0E40),
          duration: Duration(days: 365),
        ),
      );
    });
  }



  @override
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFFFFFFFF),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFF9D0514),
      body: Container(
        decoration: userInfo.backgroundUrl.isNotEmpty
            ? BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'assets/images/background/${userInfo.backgroundUrl}.png'),
            fit: BoxFit.cover,
            opacity: 0.5,
          ),
        )
            : null,
        child: Stack(
          children: [
            ...List.generate(
              15,
                  (index) => Positioned(
                left: (index * 67) % MediaQuery.of(context).size.width,
                top: (index * 83) % MediaQuery.of(context).size.height,
                child: Opacity(
                  opacity: 0.3,
                  child: index % 3 == 0
                      ? Icon(Icons.circle, size: 20, color: Colors.purple[200])
                      : index % 3 == 1
                      ? Icon(Icons.album, size: 25, color: Colors.purple[300]) // Bomb-like icon
                      : Icon(Icons.pets, size: 20, color: Colors.purple[100]), // Cat-like icon
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: userInfo.buildProfileBar(context, _openProfileDrawer),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: TextField(
                      controller: roomCodeController,
                      decoration: InputDecoration(
                        hintText: "Enter room code",
                        hintStyle: TextStyle(fontSize: 18),
                        border: OutlineInputBorder(),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      onSubmitted: (value) => joinGame(),
                    ),
                  ),
                  if (errorMessage != null) ...[
                    SizedBox(height: 10),
                    Text(
                      errorMessage!,
                      style: TextStyle(color: Colors.yellow, fontSize: 16),
                    ),
                  ],
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: joinGame,
                    child: Text("Join Game"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
