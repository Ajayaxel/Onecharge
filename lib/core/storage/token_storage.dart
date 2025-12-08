import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  TokenStorage._();

  static const String _tokenKey = 'auth_token';

  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(_tokenKey, token);
      if (!success) {
        print('❌ [TokenStorage] Failed to save token to SharedPreferences');
        throw Exception('Failed to save token');
      }
      print('✅ [TokenStorage] Token saved successfully');
      // Verify the token was saved
      final savedToken = prefs.getString(_tokenKey);
      if (savedToken != token) {
        print('❌ [TokenStorage] Token verification failed - saved token does not match');
        throw Exception('Token verification failed');
      }
      print('✅ [TokenStorage] Token verified successfully');
    } catch (e) {
      print('❌ [TokenStorage] Error saving token: $e');
      rethrow;
    }
  }

  static Future<String?> readToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      if (token != null && token.isNotEmpty) {
        print('✅ [TokenStorage] Token retrieved successfully (length: ${token.length})');
      } else {
        print('⚠️ [TokenStorage] No token found in storage');
      }
      return token;
    } catch (e) {
      print('❌ [TokenStorage] Error reading token: $e');
      return null;
    }
  }

  static Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      print('✅ [TokenStorage] Token cleared successfully');
    } catch (e) {
      print('❌ [TokenStorage] Error clearing token: $e');
      rethrow;
    }
  }
}


