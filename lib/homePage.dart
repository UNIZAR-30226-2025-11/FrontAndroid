import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_example/lobby.dart';
import 'package:flutter_example/shop.dart' as shop;
import 'package:flutter_example/userInfo.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_example/lobbyLeader.dart';
import 'package:flutter_example/statistics.dart';
import 'SessionManager.dart';
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
  //late Future<void> _initFuture;
  final UserInfo userInfo = UserInfo();
  bool _loading = true;
  Map<String, dynamic>? initialGameState;
  late bool newGame;
  late void Function(dynamic) _onGameState;


  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Set this flag first to avoid multiple initializations
    if (_loading == false) return;

    newGame = false;
    await userInfo.initialize();

    // Check mounted before continuing with socket initialization
    if (!mounted) return;

    await _initializeSocket();

    // Check mounted again before updating state
    if (!mounted) return;
    setState(() {
      _loading = false;
    });

    // Final mounted check before setting up listeners
    if (!mounted) return;
    setupFriendJoinLobbyRequestListener(
      socket: socket,
      context: context,
      username: userInfo.username,
      onAccept: (String lobbyId) {
        // Always check mounted in callbacks
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => WaitingScreen(
              socket: socket,
              lobbyId: lobbyId,
            ),
          ),
        );
        // Removed the second _initialize call which could cause issues
      },
    );
  }

  Future<void> _waitForSocketConnection({Duration timeout = const Duration(seconds: 5)}) async {
    final completer = Completer<void>();

    // If already connected, do nothing
    if (socket.connected) {
      print("⚠️ Socket already connected");
      return;
    }

    // If in process of connecting, avoid duplication
    if (socket.disconnected == false) {
      print("🔄 Socket already trying to connect, waiting...");
    } else {
      // Disconnect if in an inconsistent state
      try {
        socket.dispose(); // or socket.disconnect(), according to your implementation
      } catch (_) {
        print("⚠️ Error closing previous socket");
      }

      // Reconfigure socket before connecting
      socket.connect();
    }

    socket.onConnect((_) {
      if (!completer.isCompleted) {
        print("✅ Socket connected (await)");
        completer.complete();
      }
    });

    socket.onConnectError((error) {
      if (!completer.isCompleted) {
        completer.completeError("❌ Socket connection error: $error");
      }
    });

    return completer.future.timeout(timeout, onTimeout: () {
      throw TimeoutException("⏳ Timeout waiting for socket connection");
    });
  }

  Future<void> _initializeSocket() async {
    try {
      // Check mounted before proceeding
      if (!mounted) return;

      // Await the token since it's a Future
      final String? token = await SessionManager.getSessionData();

      // Check mounted again after the async operation
      if (!mounted) return;

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
              .disableAutoConnect()
              .build()
      );

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

      await _waitForSocketConnection();
      print(socket.connected);

      // Check mounted before setting up listeners
      if (!mounted) return;

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
    // Check mounted before setting up any listeners
    if (!mounted) return;

    // Listen for create-lobby response
    socket.on("create-lobby", (dynamic response) {
      // Check mounted in the callback
      if (!mounted) return;

      if (response != null && response['error'] == false) {
        String lobbyId = response['lobbyId'];
        Navigator.pushReplacement(
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

    if (!newGame) {
      print("📡 Waiting for 'game-state'");

      _onGameState = (data) {
        print("✅ Received 'game-state': $data");

        // Check mounted in the callback
        if (!mounted) return;

        setState(() {
          initialGameState = data;
        });

        socket.off('game-state', _onGameState);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(
              socket: socket,
              lobbyId: data['lobbyId'],
              initialGameState: initialGameState ?? {},
              username: userInfo.username,
            ),
          ),
        );
      };

      socket.on('game-state', _onGameState);
    }
  }


  @override
  void dispose() {
    print('dispose homePage');
    if (newGame==true){
      //socket.disconnect();
      //socket.dispose();
    }
    socket.off('create-lobby');
    socket.off('game-state', _onGameState);
    super.dispose();
  }

  // Método para crear una sala de lobby
  void _createLobby(int maxPlayers) {
    final  lobbyRequest = {
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
                        builder: (context) => MainScreen()),
                  );
                  setState(() {
                     //_initialize();
                  });
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
          backgroundColor: Color(0xFF3D0E40),
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
                            builder: (context) =>MainScreen()
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
                        builder: (context) =>StatisticsScreen(
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
                        builder: (context) => shop.ShopScreen(
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
            Positioned(
              top: 40,
              left: 30,
              right: 30,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[300],
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
                                  ? Icon(Icons.person, color: Colors.black)
                                  : null,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          userInfo.username,
                          style: TextStyle(color: Colors.black, fontSize: 16),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.monetization_on, color: Colors.amber[700], size: 24),
                        SizedBox(width: 6),
                        Text(
                          '${userInfo.coins}',
                          style: TextStyle(color: Colors.black, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome back!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Ready for a new adventure?',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () async {
                      newGame = true;
                      print("newGAME");
                      //socket.off('game-state');
                      //socket.disconnect();
                      //socket.dispose();
                      socket.off('game-state', _onGameState);
                      // Se ejecuta cuando se crea una nueva sala
                      int? players = await _showPlayerSelectionDialog(context);
                    },
                    child: Text("New Lobby"),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      newGame = true;
                      print("newGAME");
                      //socket.off('game-state');
                      //socket.disconnect();
                      //socket.dispose();

                      socket.off('game-state', _onGameState);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JoinGameScreen(
                            socket: socket,
                          ),
                        ),
                      );
                      setState(() {
                        _initialize();
                      });
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
}
