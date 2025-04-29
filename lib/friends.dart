import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'SessionManager.dart';
import 'homePage.dart';
import 'userInfo.dart';
import 'editProfile.dart';
import 'customize.dart';
import 'shop.dart';
import 'login.dart';
import 'statistics.dart';

const String baseUrl = 'http://10.0.2.2:8000';
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
  final UserInfo userInfo = UserInfo();

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
    });
    await fetchFriends();
  }

  // Método para abrir el drawer de perfil
  void _openProfileDrawer() {
    UserInfo.openProfileDrawer(context);
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
                        builder: (context) => LoginScreen()),
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
          backgroundColor: Colors.black12,
          duration: Duration(days: 365),
        ),
      );
    });
  }

  Future<void> fetchFriends() async {
    setState(() {
      isLoading = true;
    });

    try {
      final String? token = await SessionManager.getSessionData();
      if (token == null || token.isEmpty) {
        throw Exception("Authentication token not available");
      }
      final response = await http.get(
          Uri.parse('$baseUrl/friends'),
          headers: {
            'Cookie': 'access_token=$token',
          }
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data);
        setState(() {
          friends = (data['users'] as List)
          //.where((user) => user['status'] == 'friend')
              .map((user) =>
              Friend(
                username: user['username'],
                avatar: user['avatar'],
                status: user['status'],
              ))
              .toList();
          pendingRequests = data['numRequests'];
          isLoading = false;
        });
      } else {
        print(response.statusCode);
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
      final String? token = await SessionManager.getSessionData();
      if (token == null || token.isEmpty) {
        throw Exception("Authentication token not available");
      }
      final response = await http.delete(
        Uri.parse('$baseUrl/friends'),
        headers: {'Content-Type': 'application/json',
          'Cookie': 'access_token=$token',},
        body: jsonEncode({'resp': {
          'username': username
        }
        }),
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
            Padding(
              padding: const EdgeInsets.only(top: 20.0), // Adjust as needed
              child: userInfo.buildProfileBar(context, _openProfileDrawer),
            ),

            Positioned(
              top: 120,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
              padding: EdgeInsets.only(top: 180), // Aumentado para dar espacio a los iconos
              child: isLoading
                  ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : friends.isEmpty
                  ? Center(child: Text('No friends added yet', style: TextStyle(color: Colors.white)))
                  : Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
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
                          backgroundImage: AssetImage('assets/images/avatar/${friend.avatar}.png'),
                          backgroundColor: Colors.white.withOpacity(0.3),
                          // Fallback cuando la imagen no se encuentra
                          onBackgroundImageError: (exception, stackTrace) {
                            print('Error cargando imagen de avatar: $exception');
                          },
                          child: friend.avatar.isEmpty
                              ? Text(
                            friend.username[0],
                            style: TextStyle(color: Colors.white),
                          )
                              : null,
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
  final UserInfo userInfo = UserInfo();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await userInfo.initialize();
    // Load users automatically when screen opens
    searchUsersInit();
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
                        builder: (context) =>StatisticsScreen(
                          username: userInfo.username,
                        )),
                  );
                  setState(() {
                    //_initialize();
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
                    //_initialize();
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
                    //_initialize();
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
                    //_initialize();
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
                      //_initialize();
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

  Future<void> searchUsersInit() async {
    setState(() {});

    try {
      final String? token = await SessionManager.getSessionData();
      final String? currentUsername = await SessionManager.getUsername();

      final response = await http.get(
          Uri.parse('$baseUrl/users'),
          headers: {
            'Cookie': 'access_token=$token',
          }
      );

      if (response.statusCode == 200) {
        print(response.body);
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          users = data
              .where((user) => user['username'] != currentUsername)
              .where((user) => user['status'] == 'none')
              .map((user) =>
              Friend(
                  username: user['username'],
                  avatar: user['avatar'],
                  status: user['status']
              ))
              .toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to search users')),
        );
      }
    } catch (e) {
      print('Error in searchUsersInit: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }


  Future<void> searchUsers(String query) async {
    setState(() {
      isSearching = true;
    });

    try {
      final String? token = await SessionManager.getSessionData();
      final response = await http.get(
          Uri.parse('$baseUrl/users'), // sin query aquí
          headers: {
            'Cookie': 'access_token=$token',
          });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final allUsers = (data['users'] as List)
            .where((user) => user['status'] == 'none')
            .map((user) =>
            Friend(
              username: user['username'],
              avatar: user['avatar'],
              status: user['status'],
            ))
            .toList();

        // ahora filtramos por el query localmente
        final filteredUsers = allUsers
            .where((user) =>
            user.username.toLowerCase().contains(query.toLowerCase()))
            .toList();

        setState(() {
          users = filteredUsers;
          isSearching = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch users')),
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
      final String? token = await SessionManager.getSessionData();
      final response = await http.post(
        Uri.parse('$baseUrl/friends'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'access_token=$token',
        },
        body: jsonEncode({
          'resp': {
            'username': username
          }
        }),
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
        child: SafeArea(
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
                padding: const EdgeInsets.only(top: 0.0), // Adjust as needed
                child: userInfo.buildProfileBar(context, _openProfileDrawer),
              ),
              // Content with title and search
              Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    // Header with title
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
                            onPressed: () =>
                                searchUsers(_searchController.text),
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
                    Expanded(
                      child: isSearching
                          ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white),
                        ),
                      )
                          : users.isEmpty
                          ? Center(
                        child: Text(
                          'No users found',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                          : ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return Container(
                            margin: EdgeInsets.symmetric(
                                vertical: 2, horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: AssetImage(
                                    'assets/images/avatar/${user.avatar}.png'),
                                backgroundColor: Colors.white.withOpacity(0.3),
                                onBackgroundImageError: (exception,
                                    stackTrace) {
                                  print(
                                      'Error cargando imagen de avatar: $exception');
                                },
                                child: user.avatar.isEmpty
                                    ? Text(
                                  user.username[0],
                                  style: TextStyle(color: Colors.white),
                                )
                                    : null,
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
                                  backgroundColor: Colors.white.withOpacity(
                                      0.2),
                                ),
                                onPressed: () =>
                                    sendFriendRequest(user.username),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
  final UserInfo userInfo = UserInfo();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await userInfo.initialize();
    // Load users automatically when screen opens
    fetchRequests();
  }

  // Método para abrir el drawer de perfil
  void _openProfileDrawer() {
    UserInfo.openProfileDrawer(context);
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

  Future<void> fetchRequests() async {
    setState(() {
      isLoading = true;
    });

    try {
      final String? token = await SessionManager.getSessionData();
      final response = await http.get(Uri.parse('$baseUrl/friends/request'),
          headers: {
            'Cookie': 'access_token=$token',
          }
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          print(data);
          requestUsers = (data['users'] as List)
          //.where((user) => user['status'] == 'pending')
              .map((user) =>
              Friend(
                username: user['username'],
                avatar: user['avatar'],
                status: user['status'],
              ))
              .toList();
          isLoading = false;
        });
      } else {
        print(response.statusCode);
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
      final String? token = await SessionManager.getSessionData();
      final response = await http.post(
        Uri.parse('$baseUrl/friends/request'),
        headers: {'Content-Type': 'application/json',
          'Cookie': 'access_token=$token',},
        body: jsonEncode(
            {
              'resp': {
                'username': username,
                'accept': accept}
            }
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          requestUsers.removeWhere((user) => user.username == username);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                accept ? 'Friend request accepted' : 'Friend request rejected'),
          ),
        );
        fetchRequests();
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
            // Elementos decorativos de fondo
            ...List.generate(
              15,
                  (index) =>
                  Positioned(
                    left: (index * 67) % MediaQuery
                        .of(context)
                        .size
                        .width,
                    top: (index * 83) % MediaQuery
                        .of(context)
                        .size
                        .height,
                    child: Opacity(
                      opacity: 0.3,
                      child: index % 3 == 0
                          ? Icon(
                          Icons.circle, size: 20, color: Colors.purple[200])
                          : index % 3 == 1
                          ? Icon(
                          Icons.album, size: 25, color: Colors.purple[300])
                          : Icon(
                          Icons.pets, size: 20, color: Colors.purple[100]),
                    ),
                  ),
            ),

            // Contenido principal
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 0.0),
                    child: userInfo.buildProfileBar(
                        context, _openProfileDrawer),
                  ),

                  // Header con título
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

                  // Lista de solicitudes
                  Expanded(
                    child: isLoading
                        ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : requestUsers.isEmpty
                        ? Center(
                      child: Text(
                        'No pending friend requests',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                        : ListView.builder(
                      itemCount: requestUsers.length,
                      itemBuilder: (context, index) {
                        final user = requestUsers[index];
                        return Container(
                          margin: EdgeInsets.symmetric(
                              vertical: 2, horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: AssetImage(
                                  'assets/images/avatar/${user.avatar}.png'),
                              backgroundColor: Colors.white.withOpacity(0.3),
                              onBackgroundImageError: (exception, stackTrace) {
                                print(
                                    'Error cargando imagen de avatar: $exception');
                              },
                              child: user.avatar.isEmpty
                                  ? Text(
                                user.username[0],
                                style: TextStyle(color: Colors.white),
                              )
                                  : null,
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
                                  onPressed: () =>
                                      respondToRequest(user.username, true),
                                ),
                                SizedBox(width: 8),
                                TextButton(
                                  child: Text('Reject',
                                      style: TextStyle(color: Colors.white70)),
                                  onPressed: () =>
                                      respondToRequest(user.username, false),
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
          ],
        ),
      ),
    );
  }
}

class Friend {
  final String username;
  final String avatar;

  Friend({required this.username, required this.avatar, required status});
}