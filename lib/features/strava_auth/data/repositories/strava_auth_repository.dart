import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:strava_client/strava_client.dart';
import 'package:stralytics/core/constants/app_config.dart';
import 'package:stralytics/features/strava_auth/data/repositories/i_strava_auth_repository.dart';

class StravaAuthRepository implements IStravaAuthRepository {
  StravaAuthRepository(this.ref);

  final Ref ref;

  // Config and client will be loaded async
  AppConfig? _appConfig;
  StravaClient? _stravaClient;

  Future<AppConfig> _getConfig() async {
    _appConfig ??= await ConfigService.loadConfig();
    return _appConfig!;
  }

  Future<StravaClient> _getClient() async {
    if (_stravaClient != null) return _stravaClient!;

    final config = await _getConfig();
    _stravaClient = StravaClient(
      secret: config.stravaClientSecret,
      clientId: config.stravaClientId,
    );
    return _stravaClient!;
  }

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Storage keys
  static const String _accessTokenKey = 'strava_access_token';
  static const String _refreshTokenKey = 'strava_refresh_token';
  static const String _expiresAtKey = 'strava_expires_at';

  // Strava token endpoint
  static const String _tokenEndpoint = 'https://www.strava.com/oauth/token';

  @override
  Future<void> authenticate() async {
    final config = await _getConfig();
    final client = await _getClient();

    // Scopes required for the app
    final scopes = [
      AuthenticationScope.activity_read_all,
      AuthenticationScope.read_all,
      AuthenticationScope.profile_read_all,
    ];

    try {
      final token = await client.authentication.authenticate(
        scopes: scopes,
        redirectUrl: config.redirectUrl,
        callbackUrlScheme: config.callbackScheme,
      );

      // Store tokens securely
      await _saveTokens(token);
      print('Authentication Successful. Token stored securely.');
    } catch (e) {
      print('Authentication Failed: $e');
      rethrow;
    }
  }

  @override
  Future<String?> getAccessToken() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final expiresAtStr = await _storage.read(key: _expiresAtKey);

    if (accessToken == null || expiresAtStr == null) {
      return null; // User needs to authenticate
    }

    final expiresAt = int.tryParse(expiresAtStr);
    if (expiresAt == null) {
      return null;
    }

    final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);

    // Check if token is expired or expiring soon (within 1 minute)
    if (DateTime.now()
        .isAfter(expiryDate.subtract(const Duration(minutes: 1)))) {
      return await _refreshAccessToken();
    }

    return accessToken;
  }

  @override
  Future<bool> isAuthenticated() async {
    final accessToken = await getAccessToken();
    return accessToken != null;
  }

  @override
  Future<void> logout() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _expiresAtKey);
    print('User logged out. Tokens cleared.');
  }

  /// Refreshes the access token using the stored refresh token
  /// Makes a direct HTTP POST request to Strava's token endpoint
  Future<String?> _refreshAccessToken() async {
    final config = await _getConfig();
    final refreshToken = await _storage.read(key: _refreshTokenKey);

    if (refreshToken == null) {
      print('No refresh token available. Please authenticate again.');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': config.stravaClientId,
          'client_secret': config.stravaClientSecret,
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        // Save new tokens
        await _storage.write(
            key: _accessTokenKey, value: data['access_token'] as String);
        await _storage.write(
            key: _refreshTokenKey, value: data['refresh_token'] as String);
        await _storage.write(
            key: _expiresAtKey, value: data['expires_at'].toString());

        print('Access token refreshed successfully.');
        return data['access_token'] as String;
      } else {
        print('Failed to refresh token. Status: ${response.statusCode}');
        // Clear invalid tokens
        await logout();
        return null;
      }
    } catch (e) {
      print('Failed to refresh token: $e');
      // Clear invalid tokens
      await logout();
      return null;
    }
  }

  /// Saves authentication tokens to secure storage
  Future<void> _saveTokens(TokenResponse token) async {
    await _storage.write(key: _accessTokenKey, value: token.accessToken);
    await _storage.write(key: _refreshTokenKey, value: token.refreshToken);
    await _storage.write(key: _expiresAtKey, value: token.expiresAt.toString());
  }
}
