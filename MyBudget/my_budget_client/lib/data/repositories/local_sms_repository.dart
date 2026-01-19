import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:my_budget_client/data/seed_data/sms_preset_defaults.dart';
import 'package:my_budget_client/domain/entities/sms_preset.dart';
import 'package:my_budget_client/domain/repositories/sms_repository.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local SMS repository implementation.
/// Note: Actual SMS reading requires native implementation or a compatible package.
/// This implementation provides preset management and stub SMS methods.
class LocalSmsRepository implements SmsRepository {
  final StreamController<SmsMessage> _smsController =
      StreamController<SmsMessage>.broadcast();

  static const String _presetsKey = 'sms_presets';
  static const String _lastSyncKey = 'sms_last_sync';

  List<SmsPreset>? _cachedPresets;

  @override
  Future<List<SmsPreset>> getAllPresets() async {
    if (_cachedPresets != null) return _cachedPresets!;

    final prefs = await SharedPreferences.getInstance();
    final storedJson = prefs.getString(_presetsKey);

    final builtInPresets = SmsPresetDefaults.getBuiltInPresets();

    if (storedJson == null) {
      _cachedPresets = builtInPresets;
      return _cachedPresets!;
    }

    try {
      final List<dynamic> decoded = jsonDecode(storedJson);
      final customPresets = decoded
          .map((e) => _presetFromJson(e as Map<String, dynamic>))
          .toList();

      final result = <SmsPreset>[];

      for (final builtIn in builtInPresets) {
        final stored = customPresets.firstWhere(
          (p) => p.id == builtIn.id,
          orElse: () => builtIn,
        );
        result.add(
          builtIn.copyWith(
            isEnabled: stored.isEnabled,
            defaultAccountId: stored.defaultAccountId,
            defaultCategoryId: stored.defaultCategoryId,
          ),
        );
      }

      for (final custom in customPresets) {
        if (!custom.isBuiltIn && !result.any((p) => p.id == custom.id)) {
          result.add(custom);
        }
      }

      _cachedPresets = result;
      return _cachedPresets!;
    } catch (e) {
      _cachedPresets = builtInPresets;
      return _cachedPresets!;
    }
  }

  @override
  Future<List<SmsPreset>> getEnabledPresets() async {
    final all = await getAllPresets();
    return all.where((p) => p.isEnabled).toList();
  }

  @override
  Future<void> savePreset(SmsPreset preset) async {
    final presets = await getAllPresets();
    final index = presets.indexWhere((p) => p.id == preset.id);

    if (index >= 0) {
      presets[index] = preset;
    } else {
      presets.add(preset);
    }

    _cachedPresets = presets;
    await _persistPresets(presets);
  }

  @override
  Future<void> deletePreset(String presetId) async {
    final presets = await getAllPresets();
    presets.removeWhere((p) => p.id == presetId && !p.isBuiltIn);
    _cachedPresets = presets;
    await _persistPresets(presets);
  }

  @override
  Future<void> togglePreset(String presetId, bool isEnabled) async {
    final presets = await getAllPresets();
    final index = presets.indexWhere((p) => p.id == presetId);
    if (index >= 0) {
      presets[index] = presets[index].copyWith(isEnabled: isEnabled);
      _cachedPresets = presets;
      await _persistPresets(presets);
    }
  }

  Future<void> _persistPresets(List<SmsPreset> presets) async {
    final prefs = await SharedPreferences.getInstance();
    final json = presets.map(_presetToJson).toList();
    await prefs.setString(_presetsKey, jsonEncode(json));
  }

  @override
  Future<DateTime?> getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_lastSyncKey);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  @override
  Future<void> setLastSyncTimestamp(DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, timestamp.millisecondsSinceEpoch);
  }

  @override
  Future<List<SmsMessage>> getSmsMessages({
    DateTime? since,
    List<String>? senderFilters,
  }) async {
    // Stub: Returns empty list on non-Android or when SMS package not available
    // Real implementation requires native platform code or compatible SMS package
    if (!Platform.isAndroid) return [];

    // TODO: Implement native SMS reading when compatible package is available
    // For now, return empty list - users should update Dart SDK to 3.9.2+
    // and use flutter_sms_reader package
    return [];
  }

  @override
  Stream<SmsMessage> listenForSms() {
    // Stub: Real-time SMS listening requires platform-specific implementation
    return _smsController.stream;
  }

  @override
  Future<bool> hasSmsPermission() async {
    if (!Platform.isAndroid) return false;
    return await Permission.sms.isGranted;
  }

  @override
  Future<bool> requestSmsPermission() async {
    if (!Platform.isAndroid) return false;
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  // JSON serialization helpers
  Map<String, dynamic> _presetToJson(SmsPreset preset) {
    return {
      'id': preset.id,
      'name': preset.name,
      'senderFilter': preset.senderFilter,
      'isBuiltIn': preset.isBuiltIn,
      'isEnabled': preset.isEnabled,
      'defaultAccountId': preset.defaultAccountId,
      'defaultCategoryId': preset.defaultCategoryId,
      'rules': preset.rules.map(_ruleToJson).toList(),
    };
  }

  Map<String, dynamic> _ruleToJson(SmsParsingRule rule) {
    return {
      'id': rule.id,
      'type': rule.type.name,
      'matchPattern': rule.matchPattern,
      'amountPattern': rule.amountPattern,
      'currencyPattern': rule.currencyPattern,
      'datePattern': rule.datePattern,
    };
  }

  SmsPreset _presetFromJson(Map<String, dynamic> json) {
    return SmsPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      senderFilter: json['senderFilter'] as String,
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      isEnabled: json['isEnabled'] as bool? ?? true,
      defaultAccountId: json['defaultAccountId'] as String?,
      defaultCategoryId: json['defaultCategoryId'] as String?,
      rules:
          (json['rules'] as List<dynamic>?)
              ?.map((e) => _ruleFromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  SmsParsingRule _ruleFromJson(Map<String, dynamic> json) {
    return SmsParsingRule(
      id: json['id'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      matchPattern: json['matchPattern'] as String,
      amountPattern: json['amountPattern'] as String,
      currencyPattern: json['currencyPattern'] as String?,
      datePattern: json['datePattern'] as String?,
    );
  }
}
