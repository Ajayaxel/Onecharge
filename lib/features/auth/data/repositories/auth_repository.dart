import '../../../../core/storage/token_storage.dart';
import '../../../../core/storage/user_progress_storage.dart';
import '../../../../core/storage/user_storage.dart';
import '../datasources/auth_api_service.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/register_request.dart';
import '../models/register_response.dart';
import '../models/verify_otp_request.dart';
import '../models/verify_otp_response.dart';
import '../models/resend_otp_request.dart';
import '../models/resend_otp_response.dart';
import '../models/forgot_password_request.dart';
import '../models/forgot_password_response.dart';

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
    print('🔐 [AuthRepository] Login started for email: $email');
    try {
      print('📤 [AuthRepository] Sending login request...');
      final response = await _apiService.login(
        LoginRequest(email: email, password: password),
      );
      
      print('✅ [AuthRepository] Login successful!');
      print('📦 [AuthRepository] Response received: ${response.toString()}');
      
      // Save token first and verify it was saved
      print('💾 [AuthRepository] Saving token...');
      await TokenStorage.saveToken(response.token);
      
      // Verify token was saved correctly
      final savedToken = await TokenStorage.readToken();
      if (savedToken != response.token) {
        print('❌ [AuthRepository] Token verification failed after save');
        throw Exception('Failed to persist authentication token');
      }
      print('✅ [AuthRepository] Token saved and verified successfully');
      
      // Save user data
      print('💾 [AuthRepository] Saving user data...');
      await UserStorage.saveUser(response.user);
      print('✅ [AuthRepository] User data saved successfully');
      
      print('🎉 [AuthRepository] Login completed successfully');
      return response;
    } catch (e) {
      print('❌ [AuthRepository] Login failed with error: $e');
      rethrow;
    }
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

  /// Verify OTP function
  Future<VerifyOtpResponse> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _apiService.verifyOtp(
      VerifyOtpRequest(email: email, otp: otp),
    );
    return response;
  }

  /// Resend OTP function
  Future<ResendOtpResponse> resendOtp({
    required String email,
  }) async {
    final response = await _apiService.resendOtp(
      ResendOtpRequest(email: email),
    );
    return response;
  }

  /// Forgot Password function
  Future<ForgotPasswordResponse> forgotPassword({
    required String email,
  }) async {
    final response = await _apiService.forgotPassword(
      ForgotPasswordRequest(email: email),
    );
    return response;
  }
}
