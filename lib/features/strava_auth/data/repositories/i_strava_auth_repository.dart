abstract class IStravaAuthRepository {
  Future<void> authenticate();
  Future<String?> getAccessToken();
  Future<bool> isAuthenticated();
  Future<void> logout();
}
