import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageToken {
  static final StorageToken instance = StorageToken._internal();
  StorageToken._internal();

  final _storage = const FlutterSecureStorage();

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  Future<void> saveUserInfo(int userId, String role) async {
    await _storage.write(key: 'user_id', value: userId.toString());
    await _storage.write(key: 'role', value: role);
  }

  Future<int?> getUserId() async {
    final value = await _storage.read(key: 'user_id');
    return value != null ? int.tryParse(value) : null;
  }

  Future<String?> getRole() async {
    return await _storage.read(key: 'role');
  }
}
