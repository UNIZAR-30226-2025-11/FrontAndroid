import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'SessionManager.dart';
import 'models/models.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class UserInfo {
  // Singleton instance
  static final UserInfo _instance = UserInfo._internal();

  // Factory constructor returns the singleton instance
  factory UserInfo() => _instance;

  // Private constructor for singleton pattern
  UserInfo._internal();

  // User data
  String _username = "";
  int _coins = 0;
  String _avatar = "";
  String _background = "";
  String _avatarUrl = "";
  String _backgroundUrl = "";
  Map<String, dynamic> _statistics = {};
  List<dynamic> _ownedProducts = [];

  // Getters
  String get username => _username;
  int get coins => _coins;
  String get avatar => _avatar;
  String get background => _background;
  String get avatarUrl => _avatarUrl;
  String get backgroundUrl => _backgroundUrl;
  Map<String, dynamic> get statistics => _statistics;
  List<dynamic> get ownedProducts => _ownedProducts;

  // Initialize user data
  Future<void> initialize() async {
    await _fetchUsername();
    await _fetchUserData();
    await _fetchOwnedProducts();
  }

  // Fetch username from session
  Future<void> _fetchUsername() async {
    try {
      final String? user = await SessionManager.getUsername();
      if (user != null && user.isNotEmpty) {
        _username = user;
      }
    } catch (e) {
      print("Error fetching username: $e");
    }
  }

  // Fetch user data including coins, avatar, background
  Future<void> _fetchUserData() async {
    try {
      final String? token = await SessionManager.getSessionData();
      if (token == null || token.isEmpty) {
        print("Error: Invalid session token");
        return;
      }

      final res = await http.get(
          Uri.parse('http://10.0.2.2:8000/user'),
          headers: {
            'Cookie': 'access_token=$token',
          }
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        _coins = data['coins'] is int ? data['coins'] : int.parse(data['coins'].toString());
        if (data.containsKey('userPersonalizeData')) {
          final personalizeData = data['userPersonalizeData'];
          _avatarUrl = personalizeData['avatar'] ?? "";
          _backgroundUrl = personalizeData['background'] ?? "";
        }

        print("User data loaded: coins=$_coins, avatar=$_avatar, background=$_background");
      } else {
        print("Error fetching user data: ${res.statusCode}");
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  // Fetch owned products including avatar and background URLs
  Future<void> _fetchOwnedProducts() async {
    try {
      final String? token = await SessionManager.getSessionData();
      if (token == null || token.isEmpty) {
        print("Error: Invalid session token");
        return;
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/shop/owned'),
        headers: {
          'Cookie': 'access_token=$token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _ownedProducts = data['products'] ?? [];

        // Find URLs for current avatar and background
        _updateCustomizationUrls();
      } else {
        print("Error fetching owned products: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching owned products: $e");
    }
  }

  // Update avatar and background URLs based on their names
  void _updateCustomizationUrls() {
    // Find avatar URL
    if (_avatar.isNotEmpty) {
      final avatarProduct = _ownedProducts.firstWhere(
            (product) =>
        product['categoryName'].toString().toLowerCase() == 'avatar' &&
            product['productName'] == _avatar,
        orElse: () => null,
      );

      if (avatarProduct != null && avatarProduct.containsKey('productUrl')) {
        _avatarUrl = avatarProduct['productUrl'] ?? "";
      }
    }

    // Find background URL
    if (_background.isNotEmpty) {
      final backgroundProduct = _ownedProducts.firstWhere(
            (product) =>
        product['categoryName'].toString().toLowerCase() == 'background' &&
            product['productName'] == _background,
        orElse: () => null,
      );

      if (backgroundProduct != null && backgroundProduct.containsKey('productUrl')) {
        _backgroundUrl = backgroundProduct['productUrl'] ?? "";
      }
    }

    print("Updated URLs: avatarUrl=$_avatarUrl, backgroundUrl=$_backgroundUrl");
  }

  // Update customization (avatar or background)
  Future<bool> updateCustomization(String categoryName, String productName) async {
    try {
      final String? token = await SessionManager.getSessionData();
      if (token == null || token.isEmpty) {
        print("Error: Invalid session token");
        return false;
      }

      final response = await http.put(
        Uri.parse('http://10.0.2.2:8000/shop/owned'),
        headers: {
          'Cookie': 'access_token=$token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'resp': {
            'categoryName': categoryName,
            'productName': productName,
          }
        }),
      );

      if (response.statusCode == 200) {
        // Update local data
        if (categoryName.toLowerCase() == 'avatar') {
          _avatar = productName;
        } else if (categoryName.toLowerCase() == 'background') {
          _background = productName;
        }

        // Update URLs
        _updateCustomizationUrls();
        return true;
      } else {
        print("Error updating customization: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Error updating customization: $e");
      return false;
    }
  }

  // Update coins (after purchase or earning)
  void updateCoins(int newCoins) {
    _coins = newCoins;
  }

  // Refresh all user data
  Future<void> refreshData() async {
    await _fetchUserData();
    await _fetchOwnedProducts();
  }
}

void setupFriendJoinLobbyRequestListener({
  required IO.Socket socket,
  required BuildContext context,
  required String username,
  required Function(String lobbyId) onAccept,
}) {
  socket.on('send-friend-join-lobby-request', (data) {
    final BackendSendFriendRequestEnterLobbyJSON request =
    BackendSendFriendRequestEnterLobbyJSON.fromJson(data);

    if (!request.error) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Friend Invitation'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage('assets/images/avatar/${request.friendSendingRequestAvatar}'),
                  radius: 30,
                ),
                const SizedBox(height: 10),
                Text('${request.friendSendingRequest} has invited you to join their lobby.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  final FrontendResponseFriendRequestEnterLobbyJSON response = FrontendResponseFriendRequestEnterLobbyJSON(
                    error: false,
                    errorMsg: '',
                    lobbyId: request.lobbyId,
                    accept: false,
                    friendSendingRequest: request.friendSendingRequest,
                  );

                  socket.emit('send-friend-join-lobby-request', response.toJson());
                  Navigator.of(context).pop();
                },
                child: const Text('Decline'),
              ),
              ElevatedButton(
                onPressed: () {

                  final FrontendResponseFriendRequestEnterLobbyJSON response = FrontendResponseFriendRequestEnterLobbyJSON(
                    error: false,
                    errorMsg: '',
                    lobbyId: request.lobbyId,
                    accept: true,
                    friendSendingRequest: request.friendSendingRequest,
                  );
                  
                  socket.emit('send-friend-join-lobby-request', response.toJson());
                  Navigator.of(context).pop();

                  // Call the onAccept callback to navigate to the game screen
                  onAccept(request.lobbyId);
                },
                child: const Text('Accept'),
              ),
            ],
          );
        },
      );
    }
  });
}