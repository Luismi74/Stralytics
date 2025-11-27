import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stralytics/features/strava_auth/data/repositories/i_strava_auth_repository.dart';
import 'package:stralytics/features/strava_auth/data/repositories/strava_auth_repository.dart';
import 'package:stralytics/features/strava_auth/presentation/viewmodel/strava_auth_viewmodel.dart';

final stravaAuthRepositoryProvider = Provider<IStravaAuthRepository>((ref) {
  return StravaAuthRepository(ref);
});

final stravaAuthViewModelProvider =
    StateNotifierProvider<StravaAuthViewModel>((ref) {
  final repository = ref.read(stravaAuthRepositoryProvider);
  return StravaAuthViewModel(repository);
});
