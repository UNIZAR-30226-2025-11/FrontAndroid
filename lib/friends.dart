import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'SessionManager.dart';

// URI base para todas las peticiones a la API
const String baseUrl = 'http://10.0.2.2:8000';
// Color primario de la aplicación (rojo)
const Color primaryColor = Color(0xFF9D0514);

class FriendsScreen extends StatefulWidget {
  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  List<Friend> friends = [];
  int pendingRequests = 0;
  bool isLoading = true;
  String username = "";
  int coins = 0;

  @override
  void initState() {
    super.initState();
    _initializeUsername().then((_) {
      fetchFriends();
      _initializeCoins();
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
          Uri.parse('$baseUrl/users'),
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
        // Find the user with matching username
        final user = (data as List).firstWhere(
              (user) => user['username'] == username,
          orElse: () => null,
        );

        if (user != null) {
          // Use setState to update the UI
          setState(() {
            coins = int.parse(user['coins'].toString());
          });
          print("Found user, coins: $coins");
        } else {
          print("User not found in the response data");
        }
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

  void _openProfileDrawer() {
    Scaffold.of(context).openDrawer();
  }

  Future<void> fetchFriends() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('$baseUrl/friends'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          friends = (data['users'] as List)
              .map((user) => Friend(
            username: user['username'],
            avatar: user['avatar'],
          ))
              .toList();
          pendingRequests = data['num-requests'];
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load friends')),
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteFriend(String username) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/friends'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username}),
      );

      if (response.statusCode == 200) {
        setState(() {
          friends.removeWhere((friend) => friend.username == username);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Friend removed successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove friend')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Stack(
          children: [
            // User profile y coins arriba
            Positioned(
              top: 20,
              left: 30,
              child: Row(
                children: [
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
            Positioned(
              top: 20,
              right: 30,
              child: Row(
                children: [
                  Icon(Icons.monetization_on, color: Colors.yellow, size: 30),
                  SizedBox(width: 8),
                  Text('$coins',
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            ),

            // Iconos de acción (más grandes y centrados)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono de añadir amigo
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        IconButton(
                          icon: Icon(Icons.person_add, color: Colors.white, size: 40),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SearchUsersScreen()),
                            ).then((_) => fetchFriends());
                          },
                          iconSize: 40,
                          tooltip: 'Add Friend',
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Add Friend',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        )
                      ],
                    ),
                  ),

                  // Icono de notificaciones
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.notifications, color: Colors.white, size: 40),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => FriendRequestsScreen()),
                                ).then((_) => fetchFriends());
                              },
                              iconSize: 40,
                              tooltip: 'Friend Requests',
                            ),
                            if (pendingRequests > 0)
                              Positioned(
                                right: 5,
                                top: 5,
                                child: Container(
                                  padding: EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '$pendingRequests',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Requests',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main content (lista de amigos)
            Padding(
              padding: EdgeInsets.only(top: 160), // Aumentado para dar espacio a los iconos
              child: isLoading
                  ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : friends.isEmpty
                  ? Center(child: Text('No friends added yet', style: TextStyle(color: Colors.white)))
                  : Container(
                decoration: BoxDecoration(
                  color: primaryColor,
                ),
                child: ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 2, horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.3),
                          child: Text(
                            friend.avatar.isNotEmpty ? friend.avatar[0] : '?',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          friend.username,
                          style: TextStyle(color: Colors.white),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.white),
                          onPressed: () => _showDeleteConfirmation(friend),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Friend friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: primaryColor,
        title: Text('Remove Friend', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to remove ${friend.username} from your friends?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Remove', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pop(context);
              deleteFriend(friend.username);
            },
          ),
        ],
      ),
    );
  }
}

class SearchUsersScreen extends StatefulWidget {
  @override
  _SearchUsersScreenState createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Friend> users = [];
  bool isSearching = false;

  Future<void> searchUsers(String query) async {
    setState(() {
      isSearching = true;
    });

    try {
      final response = await http.get(Uri.parse('$baseUrl/users/search?query=$query'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          users = (data['users'] as List)
              .map((user) => Friend(
            username: user['username'],
            avatar: user['avatar'],
          ))
              .toList();
          isSearching = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to search users')),
        );
        setState(() {
          isSearching = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() {
        isSearching = false;
      });
    }
  }

  Future<void> sendFriendRequest(String username) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/friends'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Friend request sent')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send friend request')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with title only (sin flecha atrás)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'Add Friend',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Search box
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search users',
                  labelStyle: TextStyle(color: Colors.white70),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search, color: Colors.white),
                    onPressed: () => searchUsers(_searchController.text),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                onSubmitted: (value) => searchUsers(value),
              ),
            ),

            // Results
            isSearching
                ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                : Expanded(
              child: users.isEmpty
                  ? Center(child: Text('No users found', style: TextStyle(color: Colors.white)))
                  : ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 2, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.3),
                        child: Text(
                          user.avatar.isNotEmpty ? user.avatar[0] : '?',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        user.username,
                        style: TextStyle(color: Colors.white),
                      ),
                      trailing: TextButton(
                        child: Text(
                          'Add',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                        onPressed: () => sendFriendRequest(user.username),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FriendRequestsScreen extends StatefulWidget {
  @override
  _FriendRequestsScreenState createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  List<Friend> requestUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('$baseUrl/friends/requests'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          requestUsers = (data['users'] as List)
              .map((user) => Friend(
            username: user['username'],
            avatar: user['avatar'],
          ))
              .toList();
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load friend requests')),
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> respondToRequest(String username, bool accept) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/friends/requests'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'accept': accept}),
      );

      if (response.statusCode == 200) {
        setState(() {
          requestUsers.removeWhere((user) => user.username == username);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept ? 'Friend request accepted' : 'Friend request rejected'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to respond to friend request')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with title only (sin flecha atrás)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'Friend Requests',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Requests list
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : requestUsers.isEmpty
                  ? Center(child: Text('No pending friend requests', style: TextStyle(color: Colors.white)))
                  : ListView.builder(
                itemCount: requestUsers.length,
                itemBuilder: (context, index) {
                  final user = requestUsers[index];
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 2, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.3),
                        child: Text(
                          user.avatar.isNotEmpty ? user.avatar[0] : '?',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        user.username,
                        style: TextStyle(color: Colors.white),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            child: Text('Accept'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: primaryColor,
                            ),
                            onPressed: () => respondToRequest(user.username, true),
                          ),
                          SizedBox(width: 8),
                          TextButton(
                            child: Text('Reject', style: TextStyle(color: Colors.white70)),
                            onPressed: () => respondToRequest(user.username, false),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Friend {
  final String username;
  final String avatar;

  Friend({required this.username, required this.avatar});
}