import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionManager {
  // Instancia de FlutterSecureStorage
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  // Guardar token en almacenamiento seguro
  static Future<void> saveSessionData(String token) async {
    await _storage.write(key: 'authToken', value: token);
    print("Token guardado de forma segura");
  }

  static Future<void> saveUsername(String username) async {
    await _storage.write(key: 'username', value: username);
    print("Username guardado de forma segura");
  }

  static Future<String?> getUsername() async {
    return await _storage.read(key: 'username');
  }

  // Obtener token desde almacenamiento seguro
  static Future<String?> getSessionData() async {
    return await _storage.read(key: 'authToken');
  }

  // Eliminar token del almacenamiento seguro
  static Future<void> removeSessionData() async {
    await _storage.delete(key: 'authToken');
    print("Token eliminado de forma segura");
  }
}
