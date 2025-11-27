import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stralytics/features/strava_auth/data/repositories/i_strava_auth_repository.dart';

class StravaAuthViewModel extends StateNotifier {
  final IStravaAuthRepository _repository;

  StravaAuthViewModel(this._repository) : super(const AsyncValue.data(null));

  Future<void> login() async {
    state = const AsyncValue.loading();
    try {
      await _repository.authenticate();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
