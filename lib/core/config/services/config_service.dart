import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:stralytics/core/config/models/app_config.dart';

/// Service for loading application configuration from JSON file
class ConfigService {
  static AppConfig? _config;

  /// Loads the configuration from assets/config.json
  static Future<AppConfig> loadConfig() async {
    if (_config != null) {
      return _config!;
    }

    try {
      // Load the JSON file from assets
      final jsonString = await rootBundle.loadString('assets/config.json');
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;

      _config = AppConfig.fromJson(jsonMap);
      return _config!;
    } catch (e) {
      throw Exception('Failed to load config.json: $e');
    }
  }

  /// Gets the cached configuration
  /// Throws if config hasn't been loaded yet
  static AppConfig getConfig() {
    if (_config == null) {
      throw Exception(
        'Config not loaded. Call ConfigService.loadConfig() first.',
      );
    }
    return _config!;
  }

  /// Clears the cached configuration (useful for testing)
  static void clearConfig() {
    _config = null;
  }
}
