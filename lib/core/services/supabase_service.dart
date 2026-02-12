import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton service for Supabase client initialization and access.
/// Must be initialized before app startup with [initialize].
class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance {
    if (_instance == null) {
      throw Exception(
        'SupabaseService not initialized. Call SupabaseService.initialize() first.',
      );
    }
    return _instance!;
  }

  late final SupabaseClient client;

  SupabaseService._();

  /// Initializes Supabase with project credentials.
  /// Call this in main() before runApp().
  ///
  /// ```dart
  /// await SupabaseService.initialize(
  ///   url: 'https://your-project.supabase.co',
  ///   anonKey: 'your-anon-key',
  /// );
  /// ```
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    _instance = SupabaseService._();

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );

    _instance!.client = Supabase.instance.client;

    // Sign in anonymously to create a unique user ID for this device
    // This enables multi-user data isolation via Row Level Security
    final currentUser = _instance!.client.auth.currentUser;
    if (currentUser == null) {
      try {
        print('Attempting anonymous sign-in...');
        final response = await _instance!.client.auth.signInAnonymously();
        final userId = response.user?.id;

        if (userId != null) {
          print('Anonymous sign-in successful! User ID: $userId');
          // Ensure user profile exists
          await _instance!._ensureProfileExists(userId);
        } else {
          throw Exception('Anonymous sign-in returned null user');
        }
      } catch (e, stackTrace) {
        print('ERROR during anonymous sign-in: $e');
        print('Stack trace: $stackTrace');
        rethrow;
      }
    } else {
      print('User already signed in: ${currentUser.id}');
    }
  }

  /// Creates a profile entry for the user if it doesn't exist.
  /// Required for foreign key constraints in processing_jobs and activities tables.
  Future<void> _ensureProfileExists(String userId) async {
    try {
      await client.from('profiles').upsert({
        'id': userId,
      });
    } catch (e) {
      // Profile might already exist, this is fine
      print('Profile upsert info: $e');
    }
  }

  /// Returns the current authenticated user ID, or null if not authenticated.
  String? get currentUserId => client.auth.currentUser?.id;

  /// Returns true if a user is currently authenticated.
  bool get isAuthenticated => client.auth.currentUser != null;
}
