class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = 'https://onecharge.io';
  static const String login = '/api/customer/login';
  static const String logout = '/api/customer/logout';
  static const String register = '/api/customer/register';
  static const String user = '/api/user';
  static const String vehicleCategories = '/api/customer/vehicle-types';
  static const String brands = '/api/customer/brands';
  static const String models = '/api/customer/models';
  static const String tickets = '/api/customer/tickets';
  static const String uploadFiles = '/api/upload'; // File upload endpoint (adjust if different)
  static const String uploadSimple = '/api/customer/upload-simple'; // Simple file upload for tickets
  static const String numberPlate = '/api/number-plate';
  static const String location = '/api/customer/location';
  static const String verifyOtp = '/api/customer/verify-otp';
  static const String resendOtp = '/api/customer/resend-otp';
  static const String forgotPassword = '/api/customer/forgot-password';
  static const String issueCategories = '/api/customer/tickets/issue-categories';
  static const String profile = '/api/customer/profile';
  static const String updatePassword = '/api/customer/profile/password';
}
