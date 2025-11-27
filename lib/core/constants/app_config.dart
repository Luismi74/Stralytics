class AppConfig {
  final String stravaClientId;
  final String stravaClientSecret;

  AppConfig({
    required this.stravaClientId,
    required this.stravaClientSecret,
  });
}

class AppCustomization {
  static final AppConfig appConfig = AppConfig(
    stravaClientId: 'YOUR_CLIENT_ID',
    stravaClientSecret: 'YOUR_CLIENT_SECRET',
  );
}
