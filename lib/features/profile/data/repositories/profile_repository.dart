import '../../../../core/storage/user_storage.dart';
import '../datasources/profile_api_service.dart';
import '../models/update_password_request.dart';
import '../models/update_password_response.dart';
import '../models/update_profile_request.dart';
import '../../../auth/data/models/login_response.dart';

class ProfileRepository {
  ProfileRepository({ProfileApiService? apiService})
      : _apiService = apiService ?? ProfileApiService();

  final ProfileApiService _apiService;

  Future<UserModel> getProfile() async {
    try {
      final user = await _apiService.getProfile();
      await UserStorage.saveUser(user);
      return user;
    } catch (e) {
      // If API fails, try to get from local storage
      final localUser = await UserStorage.getUser();
      if (localUser != null) {
        return localUser;
      }
      rethrow;
    }
  }

  Future<UserModel> updateProfile({
    required String name,
    required String phone,
  }) async {
    final request = UpdateProfileRequest(name: name, phone: phone);
    final user = await _apiService.updateProfile(request);
    await UserStorage.saveUser(user);
    return user;
  }

  Future<UpdatePasswordResponse> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    final request = UpdatePasswordRequest(
      currentPassword: currentPassword,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
    return await _apiService.updatePassword(request);
  }
}

