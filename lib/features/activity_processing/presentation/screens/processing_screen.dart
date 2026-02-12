import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/processing_viewmodel.dart';
import '../../domain/models/processing_job.dart';

/// Screen for monitoring Strava activity processing progress.
///
/// Shows real-time updates of processing status, progress, and current activity.
/// Allows users to start processing or cancel an in-progress job.
class ProcessingScreen extends ConsumerWidget {
  final String accessToken;

  const ProcessingScreen({
    required this.accessToken,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(processingViewModelProvider);
    final job = viewModel.currentJob;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing Activities'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: job == null
              ? _buildInitialState(context, viewModel)
              : _buildProcessingState(context, viewModel, job),
        ),
      ),
    );
  }

  /// Initial state - ready to start processing
  Widget _buildInitialState(
      BuildContext context, ProcessingViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_upload,
            size: 80,
            color: Colors.blue,
          ),
          const SizedBox(height: 24),
          const Text(
            'Ready to Process Your Activities',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'This will download all your Strava activities, streams, and images to the cloud. You can close the app and check back later.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 48),
          if (viewModel.error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      viewModel.error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          ElevatedButton.icon(
            onPressed: viewModel.isSubmitting
                ? null
                : () => viewModel.startProcessing(accessToken),
            icon: viewModel.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(
              viewModel.isSubmitting ? 'Starting...' : 'Start Processing',
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  /// Processing state - showing progress
  Widget _buildProcessingState(
    BuildContext context,
    ProcessingViewModel viewModel,
    ProcessingJob job,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStatusChip(job.status),
        const SizedBox(height: 32),
        _buildProgressIndicator(job),
        const SizedBox(height: 24),
        _buildProgressText(job),
        if (job.currentActivityName != null) ...[
          const SizedBox(height: 16),
          _buildCurrentActivity(job.currentActivityName!),
        ],
        const SizedBox(height: 48),
        if (job.status == JobStatus.processing) ...[
          _buildCancelButton(viewModel),
        ],
        if (job.status == JobStatus.completed) ...[
          _buildCompletedState(context),
        ],
        if (job.status == JobStatus.failed) ...[
          _buildFailedState(job.errorMessage),
        ],
        if (job.status == JobStatus.cancelled) ...[
          _buildCancelledState(),
        ],
      ],
    );
  }

  Widget _buildStatusChip(JobStatus status) {
    String statusText;
    Color statusColor;
    IconData icon;

    switch (status) {
      case JobStatus.pending:
        statusText = 'Starting...';
        statusColor = Colors.orange;
        icon = Icons.pending;
        break;
      case JobStatus.processing:
        statusText = 'Processing';
        statusColor = Colors.blue;
        icon = Icons.sync;
        break;
      case JobStatus.completed:
        statusText = 'Completed';
        statusColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case JobStatus.failed:
        statusText = 'Failed';
        statusColor = Colors.red;
        icon = Icons.error;
        break;
      case JobStatus.cancelled:
        statusText = 'Cancelled';
        statusColor = Colors.grey;
        icon = Icons.cancel;
        break;
    }

    return Center(
      child: Chip(
        avatar: Icon(icon, color: statusColor, size: 20),
        label: Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: statusColor.withOpacity(0.1),
        side: BorderSide(color: statusColor),
      ),
    );
  }

  Widget _buildProgressIndicator(ProcessingJob job) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: job.progress,
          minHeight: 12,
          backgroundColor: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
        ),
        const SizedBox(height: 8),
        Text(
          job.progressPercentage,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressText(ProcessingJob job) {
    return Center(
      child: Text(
        '${job.processedActivities} / ${job.totalActivities ?? '?'} activities processed',
        style: const TextStyle(
          fontSize: 16,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildCurrentActivity(String activityName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Text(
            'Currently Processing',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            activityName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton(ProcessingViewModel viewModel) {
    return TextButton.icon(
      onPressed: () => _showCancelDialog(viewModel),
      icon: const Icon(Icons.cancel),
      label: const Text('Cancel Processing'),
      style: TextButton.styleFrom(
        foregroundColor: Colors.red,
      ),
    );
  }

  void _showCancelDialog(ProcessingViewModel viewModel) {
    // Show confirmation dialog
    // Implementation depends on context availability
    viewModel.cancelProcessing();
  }

  Widget _buildCompletedState(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 80,
        ),
        const SizedBox(height: 16),
        const Text(
          'Processing Complete!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'All your activities are now available.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.list),
          label: const Text('View Activities'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildFailedState(String? errorMessage) {
    return Column(
      children: [
        const Icon(
          Icons.error,
          color: Colors.red,
          size: 80,
        ),
        const SizedBox(height: 16),
        const Text(
          'Processing Failed',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildCancelledState() {
    return const Column(
      children: [
        Icon(
          Icons.cancel,
          color: Colors.grey,
          size: 80,
        ),
        SizedBox(height: 16),
        Text(
          'Processing Cancelled',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
