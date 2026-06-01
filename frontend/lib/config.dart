class AppConfig {
  // Use http://10.0.2.2:5000/api for Android Emulator loopback,
  // or http://localhost:5000/api for Web/Desktop/iOS emulator.
  static const String apiBaseUrl = 'https://humorous-moonbeam-footboard.ngrok-free.dev/api';
  
  // Storage keys
  static const String tokenKey = 'jwt_auth_token';
  static const String roleKey = 'user_role';
  static const String userIdKey = 'user_id';
  static const String userNameKey = 'user_name';
}
