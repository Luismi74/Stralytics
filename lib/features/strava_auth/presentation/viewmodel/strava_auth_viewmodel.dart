import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stralytics/features/strava_auth/data/repositories/i_strava_auth_repository.dart';

class StravaAuthViewModel extends StateNotifier<AsyncValue<String?>> {
  final IStravaAuthRepository _repository;

  StravaAuthViewModel(this._repository) : super(const AsyncValue.loading()) {
    checkAuthStatus();
  }

  Future<void> login() async {
    state = const AsyncValue.loading();
    try {
      await _repository.authenticate();
      await checkAuthStatus();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      await _repository.logout();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> checkAuthStatus() async {
    try {
      final token = await _repository.getAccessToken();
      state = AsyncValue.data(token);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
