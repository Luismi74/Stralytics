// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppConfig _$AppConfigFromJson(Map<String, dynamic> json) => AppConfig(
      stravaClientId: json['strava_client_id'] as String,
      stravaClientSecret: json['strava_client_secret'] as String,
      redirectUrl: json['redirect_url'] as String? ?? 'stralytics://callback',
      callbackScheme: json['callback_scheme'] as String? ?? 'stralytics',
    );

Map<String, dynamic> _$AppConfigToJson(AppConfig instance) => <String, dynamic>{
      'strava_client_id': instance.stravaClientId,
      'strava_client_secret': instance.stravaClientSecret,
      'redirect_url': instance.redirectUrl,
      'callback_scheme': instance.callbackScheme,
    };
