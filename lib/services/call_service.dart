import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for managing phone calls with direct calling capability.
/// Supports permission handling and provides foundation for future recording integration.
class CallService {
  /// Initiates a direct phone call to the specified phone number.
  ///
  /// Handles permission requests and error management.
  /// Returns true if call was successfully initiated, false otherwise.
  static Future<bool> makeDirectCall(String phoneNumber) async {
    try {
      // Request CALL_PHONE permission
      final status = await Permission.phone.request();

      if (status.isDenied) {
        return false;
      }

      if (status.isPermanentlyDenied) {
        // Permission is permanently denied, direct user to settings
        openAppSettings();
        return false;
      }

      // Permission granted, make the call
      await FlutterPhoneDirectCaller.callNumber(phoneNumber);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Checks if the app has permission to make calls.
  /// Useful for pre-checking before showing call UI.
  static Future<bool> hasCallPermission() async {
    final status = await Permission.phone.status;
    return status.isGranted;
  }

  /// Requests call permission from the user.
  /// Returns the permission status.
  static Future<PermissionStatus> requestCallPermission() async {
    return await Permission.phone.request();
  }

  // ============================================================================
  // FUTURE RECORDING INTEGRATION (Phase 2)
  // The following methods are prepared for call recording feature implementation
  // ============================================================================

  /// Checks if the app has permission to record audio.
  /// Used for future call recording feature (Phase 2).
  static Future<bool> hasRecordingPermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Requests microphone permission for future recording feature.
  /// Currently not requested during Phase 1.
  static Future<PermissionStatus> requestRecordingPermission() async {
    return await Permission.microphone.request();
  }

  /// Placeholder for call state tracking.
  /// Will be used in Phase 2 to detect call start/end and auto-logging.
  ///
  /// Returns a stream of call events.
  /// Currently returns empty stream - to be implemented in Phase 2.
  static Stream<CallStateEvent> trackCallState() {
    // TODO: Implement call state tracking using platform channels
    // This will detect when device starts/ends a call and provide:
    // - Call start time
    // - Call end time
    // - Call duration
    // - Automatic call logging trigger
    return const Stream.empty();
  }

  /// Placeholder for recording initialization.
  /// Will start recording when call is active (Phase 2).
  ///
  /// Returns true if recording started successfully.
  static Future<bool> startRecording(String callSessionId) async {
    // TODO: Implement in Phase 2
    // - Initialize audio recorder
    // - Set output path (local cache initially)
    // - Start recording
    // - Log recording metadata
    return false;
  }

  /// Placeholder for stopping recording.
  /// Stops recording and prepares file for upload (Phase 2).
  ///
  /// Returns the local file path of the recording.
  static Future<String?> stopRecording() async {
    // TODO: Implement in Phase 2
    // - Stop audio recorder
    // - Get file path
    // - Return for upload processing
    return null;
  }

  /// Placeholder for uploading recording to cloud storage (Phase 2).
  ///
  /// Parameters:
  ///   - filePath: Local path to the recording file
  ///   - callLogId: Associated call log ID
  ///   - userId: User who made the call
  ///
  /// Returns the cloud storage URL of the recording.
  static Future<String?> uploadRecordingToCloud({
    required String filePath,
    required String callLogId,
    required String userId,
  }) async {
    // TODO: Implement in Phase 2
    // - Upload to Firebase Storage or AWS S3
    // - Generate signed URL
    // - Delete local file after successful upload
    // - Return cloud URL
    return null;
  }
}

/// Model for call state events (for Phase 2 implementation).
class CallStateEvent {
  final CallState state;
  final DateTime timestamp;
  final int? durationSeconds;

  CallStateEvent({
    required this.state,
    required this.timestamp,
    this.durationSeconds,
  });
}

/// Enum for call states.
enum CallState {
  started,
  connected,
  ended,
  failed,
}
