import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'adzuna_service.dart';

const String fetchJobsTaskName = 'fetchJobsTask';

/// Initialize background job scheduling
/// Call this once when the app starts
void initializeBackgroundTasks() {
  if (!(Platform.isAndroid || Platform.isIOS)) {
    debugPrint('Background tasks are not supported on this platform. Skipping.');
    return;
  }

  Workmanager().initialize(
    callbackDispatcher,
  );

  // Schedule daily job fetch at 9:00 AM
  Workmanager().registerPeriodicTask(
    fetchJobsTaskName,
    fetchJobsTaskName,
    frequency: Duration(hours: 24),
    initialDelay: Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: false,
      requiresCharging: false,
      requiresDeviceIdle: false,
      requiresStorageNotLow: false,
    ),
    backoffPolicy: BackoffPolicy.exponential,
    backoffPolicyDelay: Duration(minutes: 15),
  );

  debugPrint('Background job scheduling initialized');
}

/// Callback dispatcher for background tasks
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      debugPrint('Background task running: $taskName');

      if (taskName == fetchJobsTaskName) {
        // Check if API is configured
        if (!await AdzunaService.isConfigured()) {
          debugPrint('Adzuna API not configured. Skipping job fetch.');
          return true;
        }

        // Fetch fresh jobs from Adzuna
        debugPrint('Fetching fresh jobs from Adzuna API...');
        final jobs = await AdzunaService.fetchJobsFromAdzuna(
          location: 'Australia',
          maxResults: 30,
        );

        debugPrint('Successfully fetched ${jobs.length} jobs from Adzuna');
        return true;
      }
      return true;
    } catch (e) {
      debugPrint('Error in background task: $e');
      // Return false to retry with backoff
      return false;
    }
  });
}

/// Cancel background job scheduling
void cancelBackgroundTasks() {
  if (!(Platform.isAndroid || Platform.isIOS)) {
    return;
  }
  Workmanager().cancelByUniqueName(fetchJobsTaskName);
  debugPrint('Background job scheduling cancelled');
}

/// Cancel all background tasks
void cancelAllBackgroundTasks() {
  if (!(Platform.isAndroid || Platform.isIOS)) {
    return;
  }
  Workmanager().cancelAll();
  debugPrint('All background tasks cancelled');
}
