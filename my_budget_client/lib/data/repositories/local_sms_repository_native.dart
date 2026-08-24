import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:my_budget_client/core/utils/platform/platform_utils.dart';

import 'package:flutter/services.dart';
import 'package:flutter_sms_reader/flutter_sms_reader.dart' as sms_reader;
import 'package:my_budget_client/data/seed_data/sms_preset_defaults.dart';
import 'package:my_budget_client/domain/entities/sms_preset.dart';
import 'package:my_budget_client/domain/repositories/sms_repository.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local SMS repository implementation using flutter_sms_reader.
class LocalSmsRepository implements SmsRepository {
  static const _smsChannel = EventChannel('com.mybudget.app/sms_events');
  final StreamController<SmsMessage> _smsController =
      StreamController<SmsMessage>.broadcast();

  static const String _presetsKey = 'sms_presets';
  static const String _lastSyncKey = 'sms_last_sync';
  static const String _deletedBuiltInsKey = 'sms_deleted_presets';

  LocalSmsRepository() {
    print('SMS_DEBUG: LocalSmsRepository initialized');
    _initSmsListener();
  }

  void _initSmsListener() {
    if (!AppPlatform.isAndroid) return;
    print('SMS_DEBUG: Wrapper listening to native stream');
    _smsChannel.receiveBroadcastStream().listen((dynamic event) {
      print('SMS_DEBUG: Wrapper received event: $event');
      if (event is Map) {
        final sender = event['sender'] as String? ?? 'Unknown';
        final body = event['body'] as String? ?? '';
        final dateInt =
            event['date'] as int? ?? DateTime.now().millisecondsSinceEpoch;
        final date = DateTime.fromMillisecondsSinceEpoch(dateInt);

        _smsController.add(SmsMessage(sender: sender, body: body, date: date));
      }
    });
  }

  List<SmsPreset>? _cachedPresets;

  @override
  Future<List<SmsPreset>> getAllPresets() async {
    if (_cachedPresets != null) return _cachedPresets!;

    final prefs = await SharedPreferences.getInstance();
    final storedJson = prefs.getString(_presetsKey);

    final builtInPresets = SmsPresetDefaults.getBuiltInPresets();
    // Built-ins live in code, so a deletion only sticks if the id is
    // remembered - otherwise the next load recreates what the user removed.
    final deletedBuiltInIds =
        prefs.getStringList(_deletedBuiltInsKey) ?? const <String>[];
    final liveBuiltIns = builtInPresets
        .where((p) => !deletedBuiltInIds.contains(p.id))
        .toList();

    if (storedJson == null) {
      _cachedPresets = liveBuiltIns;
      return _cachedPresets!;
    }

    try {
      final List<dynamic> decoded = jsonDecode(storedJson);
      final customPresets = decoded
          .map((e) => _presetFromJson(e as Map<String, dynamic>))
          .toList();

      final result = <SmsPreset>[];

      // A template newer than the stored copy rewrites that copy's rules, and
      // the result has to be written back: otherwise the upgrade is redone on
      // every launch, and the moment the user edits the preset the old version
      // number is saved along with the new rules.
      var templateUpgraded = false;
      for (final builtIn in liveBuiltIns) {
        final storedIndex = customPresets.indexWhere((p) => p.id == builtIn.id);
        // A built-in with no stored row has never reached this install - a
        // fresh profile, or one shipped by an app version newer than the
        // stored data - so it comes straight from the template.
        if (storedIndex < 0) {
          result.add(builtIn);
          continue;
        }
        final stored = customPresets[storedIndex];
        final merged = _mergeBuiltIn(stored, builtIn);
        if (merged.templateVersion != stored.templateVersion) {
          templateUpgraded = true;
          debugPrint(
            '[SmsRepository] Upgraded built-in preset "${builtIn.name}" from '
            'template v${stored.templateVersion} to '
            'v${builtIn.templateVersion}',
          );
        }
        result.add(merged);
      }

      for (final custom in customPresets) {
        if (!custom.isBuiltIn && !result.any((p) => p.id == custom.id)) {
          result.add(custom);
        }
      }

      // Migrate: copy default categoryKeywords to presets that have none.
      // Matches by senderFilter (case-insensitive). Skips presets that already
      // have user-configured keywords (non-empty list).
      bool needsPersist = templateUpgraded;
      for (int i = 0; i < result.length; i++) {
        final preset = result[i];
        if (preset.categoryKeywords.isEmpty) {
          final matches = builtInPresets.where(
            (b) =>
                b.senderFilter.toLowerCase() ==
                    preset.senderFilter.toLowerCase() &&
                b.categoryKeywords.isNotEmpty,
          );
          if (matches.isNotEmpty) {
            result[i] = preset.copyWith(
              categoryKeywords: matches.first.categoryKeywords,
            );
            needsPersist = true;
            debugPrint(
              '[SmsRepository] Migrated categoryKeywords for preset '
              '"${preset.name}" from built-in defaults '
              '(senderFilter="${preset.senderFilter}")',
            );
          }
        }
      }
      if (needsPersist) {
        await _persistPresets(result);
      }

      _cachedPresets = result;
      return _cachedPresets!;
    } catch (e) {
      _cachedPresets = liveBuiltIns;
      return _cachedPresets!;
    }
  }

  /// The stored copy is what the user has edited and wins field by field; the
  /// template only supplies what that copy cannot carry - fields introduced by
  /// an app version newer than the row on disk, and the rules themselves once
  /// the app ships a template newer than the one the row was written from.
  SmsPreset _mergeBuiltIn(SmsPreset stored, SmsPreset builtIn) {
    // A newer template means a pattern was fixed or a merchant was added, and
    // those belong to the app: the first time the user touched this preset a
    // copy of that day's rules was frozen onto the device, and nothing shipped
    // since has ever reached them. What the user owns - the account, the
    // category, the on/off switch, the name - is left untouched below.
    final upgrade = builtIn.templateVersion > stored.templateVersion;

    return stored.copyWith(
      // The id is what makes a preset built-in; rows written before the flag
      // existed decode as custom and would become editable and deletable.
      isBuiltIn: true,
      rules: upgrade || stored.rules.isEmpty ? builtIn.rules : null,
      categoryKeywords: upgrade || stored.categoryKeywords.isEmpty
          ? builtIn.categoryKeywords
          : null,
      templateVersion: upgrade ? builtIn.templateVersion : null,
    );
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
    final index = presets.indexWhere((p) => p.id == presetId);
    if (index < 0) return;

    final removed = presets.removeAt(index);
    if (removed.isBuiltIn) {
      await _rememberDeletedBuiltIn(presetId);
    }
    _cachedPresets = presets;
    await _persistPresets(presets);
  }

  Future<void> _rememberDeletedBuiltIn(String presetId) async {
    final prefs = await SharedPreferences.getInstance();
    final deleted =
        prefs.getStringList(_deletedBuiltInsKey) ?? const <String>[];
    if (deleted.contains(presetId)) return;
    await prefs.setStringList(_deletedBuiltInsKey, [...deleted, presetId]);
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
    if (!AppPlatform.isAndroid) return [];

    try {
      final messages = await sms_reader.FlutterSmsReader.getAllSms();

      var filtered = messages.map(
        (m) =>
            SmsMessage(sender: m.address, body: m.body, date: m.date, id: m.id),
      );

      if (since != null) {
        filtered = filtered.where((m) => m.date.isAfter(since));
      }

      if (senderFilters != null && senderFilters.isNotEmpty) {
        filtered = filtered.where((m) {
          return senderFilters.any(
            (filter) => m.sender.toLowerCase().contains(filter.toLowerCase()),
          );
        });
      }

      return filtered.toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Stream<SmsMessage> listenForSms() {
    // flutter_sms_reader doesn't support real-time listening
    // Would need platform channel implementation for this
    return _smsController.stream;
  }

  @override
  Future<bool> hasSmsPermission() async {
    if (!AppPlatform.isAndroid) return false;
    return await Permission.sms.isGranted;
  }

  @override
  Future<bool> requestSmsPermission() async {
    if (!AppPlatform.isAndroid) return false;
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  @override
  Future<void> clearData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_presetsKey);
    await prefs.remove(_lastSyncKey);
    await prefs.remove(_deletedBuiltInsKey);
    _cachedPresets = null;
    print('SMS_DEBUG: LocalSmsRepository data cleared');
  }

  // JSON serialization helpers
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
      'categoryKeywords': preset.categoryKeywords
          .map(
            (kw) => {
              'keyword': kw.keyword,
              'categoryId': kw.categoryId,
              'categoryNameHint': kw.categoryNameHint,
            },
          )
          .toList(),
      'templateVersion': preset.templateVersion,
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
      'categoryId': rule.categoryId,
      'descriptionPattern': rule.descriptionPattern,
      'forceReview': rule.forceReview,
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
      categoryKeywords:
          (json['categoryKeywords'] as List<dynamic>?)?.map((e) {
            final m = e as Map<String, dynamic>;
            return SmsCategoryKeyword(
              keyword: m['keyword'] as String,
              categoryId: m['categoryId'] as String,
              categoryNameHint: m['categoryNameHint'] as String?,
            );
          }).toList() ??
          [],
      // Absent on every preset stored before templates were versioned, and
      // zero is the right reading of those: whatever the app ships now is
      // newer than what they hold.
      templateVersion: json['templateVersion'] as int? ?? 0,
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
      categoryId: json['categoryId'] as String?,
      descriptionPattern: json['descriptionPattern'] as String?,
      forceReview: json['forceReview'] as bool? ?? false,
    );
  }
}
