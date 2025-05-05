import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_example/config.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_example/game.dart';

import 'SessionManager.dart';
import 'UserInfo.dart';
import 'homePage.dart';
import 'models/models.dart';
import 'package:http/http.dart' as http;

class WaitingScreen extends StatefulWidget {
  final IO.Socket socket;
  final String lobbyId;

  WaitingScreen({required this.socket, required this.lobbyId});

  @override
  _StartGameScreenState2 createState() => _StartGameScreenState2();
}

class _StartGameScreenState2 extends State<WaitingScreen> {
  String? errorMsg;
  List<PlayerLobbyJSON> players = [];
  List<ConnectedFriend> connectedFriends = [];
  Map<String, dynamic>? initialGameState;
  bool isLoadingFriends = true;

  late Future<String?> _usernameFuture;
  String username = "";
  int coins = -1;

  final UserInfo userInfo = UserInfo();

  @override
  void initState() {
    super.initState();
    _initializeUser();

    // Escuchar actualizaciones del lobby
    widget.socket.on('lobby-state', (data) {
      try {
        final lobbyUpdate = BackendLobbyStateUpdateJSON.fromJson(data);
        if (lobbyUpdate.error) {
          print('Lobby update error: ${lobbyUpdate.errorMsg}');
          return;
        }

        if (lobbyUpdate.disband) {
          print('Disband');
          // Aquí podrías añadir lógica para volver a la pantalla principal
          return;
        }

        setState(() {
          players = (lobbyUpdate.players as List)
              .map((player) => PlayerLobbyJSON.fromJson(player))
              .toList();
        });
      } catch (e) {
        print('Error parsing lobby update: $e');
      }
    });


    widget.socket.on('game-state', (data) {
      setState(() {
        initialGameState = data;
      });
    });

    // Escuchar el evento 'start-game' para empezar el juego
    widget.socket.on('start-game', (data) {
      final Map<String, dynamic> responseData = data;

      if (responseData['error'] == false) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => GameScreen(
                socket: widget.socket,
                lobbyId: widget.lobbyId,
                initialGameState: initialGameState ?? {},
                username: username,
              )
          ),
        );
      } else {
        setState(() {
          errorMsg = responseData['errorMsg'];
        });
      }
    });

    // Solicitar amigos conectados al inicio
    _requestConnectedFriends();
  }


  Future<void> _initializeUser() async {
    await userInfo.initialize();  // Initialize UserInfo
    await userInfo.initialize();
    setState(() {
      username = userInfo.username;
      coins = userInfo.coins;
    });
  }

  void _requestConnectedFriends() {
    final request = FrontendRequestConnectedFriendsJSON(
        error: false,
        errorMsg: '',
        lobbyId: widget.lobbyId
    );

    widget.socket.emitWithAck('get-friends-connected', request.toJson(), ack: (data) {
      try {
        final friendsData = BackendSendConnectedFriendsJSON.fromJson(data);
        setState(() {
          connectedFriends = friendsData.connectedFriends;
          isLoadingFriends = false;
        });
      } catch (e) {
        print('Error parsing friend data in ack: $e');
        setState(() {
          isLoadingFriends = false;
        });
      }
    });


  }

  void _inviteFriend(String friendUsername) {
    final request = FrontendSendFriendRequestEnterLobbyJSON(
      error: false,
      errorMsg: '',
      lobbyId: widget.lobbyId,
      friendUsername: friendUsername,
    );

    widget.socket.emitWithAck(
        'send-friend-join-lobby-request',
        request.toJson(),
        ack: (data) {
          try {
            final response = BackendResponseFriendRequestEnterLobbyJSON.fromJson(
                data is String ? jsonDecode(data) : data
            );

            if (response.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error: ${response.errorMsg}")),
              );
              return;
            }

            final String acceptStatus = response.accept ? "accepted" : "declined";

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Player ${response.friendUsername} ${acceptStatus} your invitation!"),
                duration: Duration(milliseconds: 5000),
              ),
            );
          } catch (e) {
            print('Error parsing invite friend response: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("An error occurred while inviting the friend.")),
            );
          }
        }
    );
  }


  @override
  void dispose() {
    widget.socket.off('lobby-state');
    widget.socket.off('start-game');
    widget.socket.off('game-state', (data) {
      setState(() {
        initialGameState = data;
      });
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          // Main content below the user info bar
          Padding(
            padding: const EdgeInsets.only(top: 120.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Lobby ID: ${widget.lobbyId}',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Players section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Players in Lobby:",
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh, color: Colors.white),
                        onPressed: () {
                          // Refresh lobby logic
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  height: 150,
                  child: players.isEmpty
                      ? Center(
                    child: Text("No players yet",
                        style: TextStyle(color: Colors.white70)),
                  )
                      : ListView.builder(
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                          players[index].name,
                          style:
                          TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        leading: Icon(Icons.person, color: Colors.white),
                      );
                    },
                  ),
                ),

                // Friends section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Connected Friends:",
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh, color: Colors.white),
                        onPressed: _requestConnectedFriends,
                        tooltip: "Refresh friends list",
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: isLoadingFriends
                      ? Center(
                      child: CircularProgressIndicator(color: Colors.white))
                      : connectedFriends.isEmpty
                      ? Center(
                      child: Text("No friends online",
                          style: TextStyle(color: Colors.white70)))
                      : ListView.builder(
                    itemCount: connectedFriends.length,
                    itemBuilder: (context, index) {
                      final friend = connectedFriends[index];
                      final bool canInvite = friend.connected &&
                          !friend.isInGame &&
                          !friend.isAlreadyInThisLobby;

                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white24,
                            image: friend.avatar.isNotEmpty
                                ? DecorationImage(
                              image: AssetImage(
                                  'assets/images/avatar/${friend.avatar}.png'),
                              fit: BoxFit.cover,
                            )
                                : null,
                          ),
                          child: friend.avatar.isEmpty
                              ? Icon(Icons.person,
                              color: Colors.white)
                              : null,
                        ),
                        title: Row(
                          children: [
                            Text(
                              friend.username,
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16),
                            ),
                            SizedBox(width: 8),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: friend.connected
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          friend.isInGame
                              ? "In game"
                              : friend.isAlreadyInThisLobby
                              ? "In this lobby"
                              : "Online",
                          style: TextStyle(color: Colors.white70),
                        ),
                        trailing: canInvite
                            ? ElevatedButton(
                          onPressed: () =>
                              _inviteFriend(friend.username),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFF9D0514),
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                          ),
                          child: Text("Invite"),
                        )
                            : null,
                      );
                    },
                  ),
                ),

                if (errorMsg != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      errorMsg!,
                      style: TextStyle(color: Colors.yellow, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => MainScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Color(0xFF9D0514),
                        padding:
                        EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                      child: Text(
                        'Leave Lobby',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // User info bar at the top
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
                            image: AssetImage(
                                'assets/images/avatar/${userInfo.avatarUrl}.png'),
                            fit: BoxFit.cover,
                          )
                              : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            //onTap: _openProfileDrawer,
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
                      Icon(Icons.monetization_on,
                          color: Colors.amber[700], size: 24),
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
        ],
      ),
        )
    );
  }
}