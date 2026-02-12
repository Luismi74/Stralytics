import 'package:json_annotation/json_annotation.dart';

part 'app_config.g.dart';

/// Configuration model for the application
/// Loads settings from config.json
@JsonSerializable()
class AppConfig {
  /// Strava OAuth Client ID
  @JsonKey(name: 'strava_client_id')
  final String stravaClientId;

  /// Strava OAuth Client Secret
  @JsonKey(name: 'strava_client_secret')
  final String stravaClientSecret;

  /// OAuth Redirect URL scheme
  @JsonKey(name: 'redirect_url', defaultValue: 'stralytics://callback')
  final String redirectUrl;

  /// OAuth Callback URL scheme
  @JsonKey(name: 'callback_scheme', defaultValue: 'stralytics')
  final String callbackScheme;

  /// Supabase URL
  @JsonKey(name: 'supabase_url')
  final String supabaseUrl;

  /// Supabase Anon Key
  @JsonKey(name: 'supabase_anon_key')
  final String supabaseAnonKey;

  /// Supabase Service Role Key
  /// ⚠️ WARNING: This key has full admin access to your database.
  /// It should NEVER be used in the Flutter app client code.
  /// Only use this for server-side scripts or deployment tools.
  @JsonKey(name: 'supabase_service_role_key')
  final String? supabaseServiceRoleKey;

  AppConfig({
    required this.stravaClientId,
    required this.stravaClientSecret,
    required this.redirectUrl,
    required this.callbackScheme,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    this.supabaseServiceRoleKey,
  });

  /// Creates an AppConfig from JSON
  factory AppConfig.fromJson(Map<String, dynamic> json) =>
      _$AppConfigFromJson(json);

  /// Converts AppConfig to JSON
  Map<String, dynamic> toJson() => _$AppConfigToJson(this);
}
