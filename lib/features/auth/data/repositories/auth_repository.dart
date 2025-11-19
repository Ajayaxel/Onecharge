import '../../../../core/storage/token_storage.dart';
import '../../../../core/storage/user_progress_storage.dart';
import '../../../../core/storage/user_storage.dart';
import '../datasources/auth_api_service.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/register_request.dart';
import '../models/register_response.dart';

// Export UserModel for convenience
export '../models/login_response.dart' show UserModel;

class AuthRepository {
  AuthRepository({AuthApiService? apiService})
    : _apiService = apiService ?? AuthApiService();

  final AuthApiService _apiService;

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.login(
      LoginRequest(email: email, password: password),
    );
    await TokenStorage.saveToken(response.token);
    await UserStorage.saveUser(response.user);
    return response;
  }

  /// Register function

  Future<RegisterResponse> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    String? profileImage,
  }) async {
    final response = await _apiService.register(
      RegisterRequest(
        name: name,
        email: email,
        phone: phone,
        password: password,
        passwordConfirmation: passwordConfirmation,
        profileImage: profileImage,
      ),
    );
    return response;
  }

  Future<UserModel> getCurrentUser() async {
    // First try to get from API
    try {
      final user = await _apiService.getCurrentUser();
      await UserStorage.saveUser(user);
      return user;
    } catch (_) {
      // If API fails, try to get from local storage
      final localUser = await UserStorage.getUser();
      if (localUser != null) {
        return localUser;
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (_) {
      // Continue with local logout even if API call fails
      // This ensures user can logout even when offline
    }
    await TokenStorage.clearToken();
    await UserStorage.clearUser();
    await UserProgressStorage.clearVehicleSetup();
  }
}
