import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strava_client/strava_client.dart';
import 'package:stralytics/core/constants/app_config.dart';
import 'package:stralytics/features/strava_auth/data/repositories/i_strava_auth_repository.dart';

class StravaAuthRepository implements IStravaAuthRepository {
  StravaAuthRepository(this.ref);

  final Ref ref;
  final String clientId = AppCustomization.appConfig.stravaClientId;
  final String clientSecret = AppCustomization.appConfig.stravaClientSecret;

  late final StravaClient stravaClient = StravaClient(
    secret: clientSecret,
    clientId: clientId,
  );

  @override
  Future<void> authenticate() async {
    // Scopes required for the app
    final scopes = [
      AuthenticationScope.activity_read_all,
      AuthenticationScope.read_all,
      AuthenticationScope.profile_read_all,
    ];

    try {
      final token = await stravaClient.authentication.authenticate(
        scopes: scopes,
        redirectUrl: 'stralytics://callback',
        callbackUrlScheme: 'stralytics',
      );

      // TODO: Securely store the token (e.g., using flutter_secure_storage)
      print('Authentication Successful. Access Token: ${token.accessToken}');
    } catch (e) {
      print('Authentication Failed: $e');
      rethrow;
    }
  }
}
