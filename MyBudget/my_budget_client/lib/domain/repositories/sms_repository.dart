import 'package:my_budget_client/domain/entities/sms_preset.dart';

/// Repository for SMS presets and SMS reading
abstract class SmsRepository {
  /// Get all presets (built-in + custom)
  Future<List<SmsPreset>> getAllPresets();

  /// Get enabled presets only
  Future<List<SmsPreset>> getEnabledPresets();

  /// Save a preset (create or update)
  Future<void> savePreset(SmsPreset preset);

  /// Delete a preset (only custom presets)
  Future<void> deletePreset(String presetId);

  /// Toggle preset enabled state
  Future<void> togglePreset(String presetId, bool isEnabled);

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTimestamp();

  /// Set last sync timestamp
  Future<void> setLastSyncTimestamp(DateTime timestamp);

  /// Get SMS messages from device (Android only)
  /// Returns list of (sender, body, date) tuples
  Future<List<SmsMessage>> getSmsMessages({
    DateTime? since,
    List<String>? senderFilters,
  });

  /// Listen for incoming SMS (Android only)
  Stream<SmsMessage> listenForSms();

  /// Check if SMS permission is granted
  Future<bool> hasSmsPermission();

  /// Request SMS permission
  Future<bool> requestSmsPermission();
}

/// Represents an SMS message
class SmsMessage {
  final String sender;
  final String body;
  final DateTime date;
  final int? id;

  const SmsMessage({
    required this.sender,
    required this.body,
    required this.date,
    this.id,
  });
}
