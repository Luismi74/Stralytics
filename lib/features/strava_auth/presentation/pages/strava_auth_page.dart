import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stralytics/features/activity_processing/presentation/screens/processing_screen.dart';
import 'package:stralytics/features/strava_auth/presentation/providers/strava_auth_provider.dart';

class StravaAuthPage extends ConsumerWidget {
  const StravaAuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(stravaAuthViewModelProvider);

    return authState.when(
      data: (token) {
        if (token != null) {
          return ProcessingScreen(accessToken: token);
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Stralytics Login'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Welcome to Stralytics!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(stravaAuthViewModelProvider.notifier).login();
                  },
                  icon: const Icon(Icons.directions_run),
                  label: const Text('Connect with Strava'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: $error',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  ref.read(stravaAuthViewModelProvider.notifier).login();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
