import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class SessionManager {
  // Instance of FlutterSecureStorage
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  // Save token in secure storage with expiration timestamp
  static Future<void> saveSessionData(String token) async {
    // Create session data with expiration time (current time + 1 hour)
    final expirationTime = DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch;
    final sessionData = {
      'token': token,
      'expiresAt': expirationTime,
    };

    // Convert to JSON string
    final sessionDataString = jsonEncode(sessionData);

    // Save to secure storage
    await _storage.write(key: 'authToken', value: sessionDataString);
    print("Token guardado de forma segura (expira en 1 hora)");
  }

  static Future<void> saveUsername(String username) async {
    await _storage.write(key: 'username', value: username);
    print("Username guardado de forma segura");
  }

  static Future<String?> getUsername() async {
    return await _storage.read(key: 'username');
  }

  // Get token from secure storage, checking if it's expired
  static Future<String?> getSessionData() async {
    final sessionDataString = await _storage.read(key: 'authToken');

    if (sessionDataString == null) {
      return null;
    }

    try {
      // Parse the session data
      final sessionData = jsonDecode(sessionDataString);
      final expiresAt = sessionData['expiresAt'] as int;
      final token = sessionData['token'] as String;

      // Check if the token has expired
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now > expiresAt) {
        // Token has expired, remove it
        await removeSessionData();
        print("Token expirado, sesión finalizada");
        return null;
      }

      // Token is still valid
      return token;
    } catch (e) {
      print("Error al recuperar datos de sesión: $e");
      await removeSessionData();
      return null;
    }
  }

  // Check if session is valid without returning the token
  static Future<bool> isSessionValid() async {
    return await getSessionData() != null;
  }

  // Remove token from secure storage
  static Future<void> removeSessionData() async {
    await _storage.delete(key: 'authToken');
    print("Token eliminado de forma segura");
  }
}