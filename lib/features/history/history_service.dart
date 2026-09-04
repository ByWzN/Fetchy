import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'history_entry.dart';

/// Simple local persistence for download history: a JSON-encoded list in
/// [SharedPreferences]. No database — the whole list is small and read
/// once per app session, then kept in memory and republished through
/// [entries] whenever it changes.
class HistoryService {
  HistoryService._();

  static final HistoryService instance = HistoryService._();

  static const String _storageKey = 'fetchy.history.entries.v1';

  /// Keeps the store from growing without bound on a long-lived install.
  static const int _maxEntries = 200;

  final ValueNotifier<List<HistoryEntry>> entries =
      ValueNotifier<List<HistoryEntry>>(const <HistoryEntry>[]);

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return;

      final List<HistoryEntry> loaded = decoded
          .whereType<Map<String, Object?>>()
          .map(HistoryEntry.tryFromJson)
          .whereType<HistoryEntry>()
          .toList(growable: false);

      entries.value = loaded;
    } catch (_) {
      // Corrupt or foreign data under this key — treat as empty rather
      // than crashing history for the whole app.
    }
  }

  Future<void> add(HistoryEntry entry) async {
    await load();

    final List<HistoryEntry> updated = <HistoryEntry>[
      entry,
      ...entries.value,
    ];
    if (updated.length > _maxEntries) {
      updated.removeRange(_maxEntries, updated.length);
    }

    entries.value = updated;
    await _persist(updated);
  }

  Future<void> clear() async {
    entries.value = const <HistoryEntry>[];
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _persist(List<HistoryEntry> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      value.map((HistoryEntry e) => e.toJson()).toList(growable: false),
    );
    await prefs.setString(_storageKey, encoded);
  }
}
