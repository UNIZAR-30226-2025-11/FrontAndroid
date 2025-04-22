import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'SessionManager.dart';
import 'models/models.dart';



class UserInfo {
  String _username = '';
  int _coins = 0;
  bool _isLoading = false;
  UserPersonalizeData _personalizeData = UserPersonalizeData();
  BuildContext? _context;

  // Constructor
  UserInfo({BuildContext? context}) {
    _context = context;
  }

  // Getters
  String getUsername() => _username;
  int getCoins() => _coins;
  bool getIsLoading() => _isLoading;
  UserPersonalizeData getPersonalizeData() => _personalizeData;
  String getAvatar() => _personalizeData.avatar;
  String getBackground() => _personalizeData.background;

  // Setters
  void setUsername(String value) {
    _username = value;
  }

  void setCoins(int value) {
    _coins = value;
  }

  void setIsLoading(bool value) {
    _isLoading = value;
  }

  void setPersonalizeData(UserPersonalizeData value) {
    _personalizeData = value;
  }

  void setAvatar(String value) {
    _personalizeData.avatar = value;
  }

  void setBackground(String value) {
    _personalizeData.background = value;
  }

  void setContext(BuildContext context) {
    _context = context;
  }

  Future<void> fetchUserData() async {
    setIsLoading(true);

    try {
      // First ensure we have the username
      if (_username.isEmpty) {
        final String? user = await SessionManager.getUsername();
        if (user != null && user.isNotEmpty) {
          _username = user;
        } else {
          throw Exception("Username not available");
        }
      }

      // Then fetch the user data
      final String? token = await SessionManager.getSessionData();
      if (token == null || token.isEmpty) {
        throw Exception("Authentication token not available");
      }

      final res = await http.get(
          Uri.parse('http://10.0.2.2:8000/user'),
          headers: {
            'Cookie': 'access_token=$token',
          }
      );

      final data = jsonDecode(res.body);

      if (res.statusCode != 200) {
        var errorMessage = data.containsKey('message')
            ? data['message']
            : "Server error: ${res.statusCode}";
        throw Exception(errorMessage);
      }

      // Actualizar valores
      setCoins(int.parse(data['coins'].toString()));

      // Actualizar datos de personalización si están disponibles
      if (data.containsKey('personalizeData')) {
        setPersonalizeData(UserPersonalizeData.fromJson(data['personalizeData']));
      }

      setIsLoading(false);
    } catch (e) {
      setIsLoading(false);
      if (_context != null) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          SnackBar(content: Text('Error fetching user data: ${e.toString()}')),
        );
      }
    }
  }

  // TODO: revisar cuando exista API
  Future<bool> updatePersonalizeData() async {
    setIsLoading(true);

    try {
      final String? token = await SessionManager.getSessionData();
      if (token == null || token.isEmpty) {
        throw Exception("Authentication token not available");
      }

      final res = await http.post(
        Uri.parse('http://10.0.2.2:8000/user/personalize'),
        headers: {
          'Cookie': 'access_token=$token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(_personalizeData.toJson()),
      );

      if (res.statusCode != 200) {
        final data = jsonDecode(res.body);
        var errorMessage = data.containsKey('message')
            ? data['message']
            : "Server error: ${res.statusCode}";
        throw Exception(errorMessage);
      }

      setIsLoading(false);
      return true;
    } catch (e) {
      setIsLoading(false);
      if (_context != null) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          SnackBar(content: Text('Error updating personalize data: ${e.toString()}')),
        );
      }
      return false;
    }
  }
}
